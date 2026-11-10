import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class DesktopAuthHandler {
  final String apiKey;
  final String? clientId;
  final String? clientSecret;
  HttpServer? _server;

  DesktopAuthHandler({
    required this.apiKey,
    this.clientId,
    this.clientSecret,
  });

  Future<UserCredential?> signInWithGoogleDesktop() async {
    final String activeClientId = clientId ?? "";
    final String activeClientSecret = clientSecret ?? "";

    if (activeClientId.isEmpty || activeClientSecret.isEmpty) {
      debugPrint("DesktopAuthHandler: GOOGLE_CLIENT_ID or GOOGLE_CLIENT_SECRET not configured.");
      return null;
    }
    
    // 2. Start local server on a FIXED port to ensure stable OAuth Redirect URIs
    const int fixedPort = 8080;
    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, fixedPort);
    } catch (e) {
      // Fallback if 8080 is taken, but warn the user
      debugPrint("Warning: Port 8080 taken, falling back to random port. OAuth might fail.");
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    }
    final int port = _server!.port;
    final String redirectUri = "http://localhost:$port";

    final String authUrl = "https://accounts.google.com/o/oauth2/v2/auth"
        "?client_id=$activeClientId"
        "&redirect_uri=$redirectUri"
        "&response_type=code"
        "&scope=email profile openid https://www.googleapis.com/auth/calendar https://www.googleapis.com/auth/tasks"
        "&access_type=offline";

    final completer = Completer<UserCredential?>();

    // 3. Open the browser
    if (!await launchUrl(Uri.parse(authUrl), mode: LaunchMode.externalApplication)) {
      await _server?.close(force: true);
      throw Exception("Could not launch browser");
    }

    // 4. Listen for the authorization code
    _server!.listen((HttpRequest request) async {
      final String? code = request.uri.queryParameters['code'];

      if (code != null) {
        // Success response to browser
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.html
          ..write('''
            <!DOCTYPE html>
            <html>
            <head><title>Authentication Successful</title></head>
            <body style="font-family: sans-serif; text-align: center; padding-top: 50px;">
              <h1>Success!</h1>
              <p>Authentication was successful. You can close this window and return to the app.</p>
            </body>
            </html>
          ''');
        await request.response.close();

        try {
          // 5. Exchange code for tokens
          final response = await http.post(
            Uri.parse("https://oauth2.googleapis.com/token"),
            body: {
              'client_id': activeClientId,
              'client_secret': activeClientSecret,
              'code': code,
              'grant_type': 'authorization_code',
              'redirect_uri': redirectUri,
            },
          );

          final data = jsonDecode(response.body);
          final String? idToken = data['id_token'];
          final String? accessToken = data['access_token'];

          if (idToken != null) {
            if (!kIsWeb && Platform.isLinux) {
              // Use Firebase REST API to sign in with Google ID Token on Linux
              final firebaseResponse = await http.post(
                Uri.parse("https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp?key=$apiKey"),
                body: jsonEncode({
                  'postBody': 'id_token=$idToken&providerId=google.com',
                  'requestUri': 'http://localhost',
                  'returnIdpCredential': true,
                  'returnSecureToken': true,
                }),
                headers: {'Content-Type': 'application/json'},
              );
              
              if (firebaseResponse.statusCode == 200) {
                final firebaseData = jsonDecode(firebaseResponse.body);
                firebaseData['google_access_token'] = accessToken;
                if (data.containsKey('refresh_token')) {
                  firebaseData['google_refresh_token'] = data['refresh_token'];
                }
                completer.complete(UserCredentialMock(firebaseData)); 
              } else {
                completer.completeError(Exception("Firebase REST Auth failed: ${firebaseResponse.body}"));
              }
            } else {
              final credential = GoogleAuthProvider.credential(
                idToken: idToken,
                accessToken: accessToken,
              );
              final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
              completer.complete(userCredential);
            }
          } else {
            completer.completeError(Exception("Failed to obtain ID token: ${response.body}"));
          }
        } catch (e) {
          completer.completeError(e);
        } finally {
          await _server?.close(force: true);
        }
      } else {
        request.response
          ..statusCode = 400
          ..write('Authorization code missing');
        await request.response.close();
      }
    });

    return completer.future;
  }

  void dispose() {
    _server?.close(force: true);
  }
}

// Simple mock to satisfy return type while providing data
class UserCredentialMock implements UserCredential {
  final Map<String, dynamic> data;
  UserCredentialMock(this.data);
  
  @override
  AdditionalUserInfo? get additionalUserInfo => null;

  @override
  AuthCredential? get credential => null;

  @override
  User? get user => null;
}
