import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:flutter_core_entities/app_user.dart';
import 'desktop_auth_handler.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firedart/firedart.dart' as fd;
import 'google_auth_client.dart';
import 'package:google_sign_in/google_sign_in.dart' show GoogleSignIn, GoogleSignInAccount, GoogleSignInAuthentication, GoogleSignInAuthenticationEventSignIn;

class AuthRepository with ChangeNotifier {
  late final DesktopAuthHandler _desktopAuthHandler;
  AppUser? _linuxUser;
  GoogleSignInAccount? _googleAccount;
  final _manualAuthStateController = StreamController<AppUser?>.broadcast();
  final _authStateChangesController = StreamController<AppUser?>.broadcast();
  bool _isGoogleSignInInitialized = false;
  StreamSubscription<User?>? _firebaseAuthSubscription;

  AuthRepository({required String apiKey, String? clientId, String? clientSecret}) {
    _desktopAuthHandler = DesktopAuthHandler(
      apiKey: apiKey,
      clientId: clientId,
      clientSecret: clientSecret,
    );
    
    // Defer initialization to avoid constructor-time crashes on Web
    Future.microtask(() => _initialize(clientId));
  }

  Future<void> _initialize(String? clientId) async {
    try {
      if (kIsWeb) {
        // Early initialization for Web to avoid "Getting ready" delay
        await GoogleSignIn.instance.initialize(clientId: clientId);
        _isGoogleSignInInitialized = true;
      } else if (!kIsWeb && Platform.isLinux) {
        await _loadLinuxSession();
      }

      // Listen to Google Sign-In events (crucial for Web's official button)
      GoogleSignIn.instance.authenticationEvents.listen((event) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          _googleAccount = event.user;
          _handleGoogleSignIn(event.user);
        }
      });

      // Pipe Firebase Auth changes into our unified stream
      final auth = _auth;
      if (auth != null) {
        _firebaseAuthSubscription = auth.authStateChanges().listen((user) {
          if (kIsWeb || !Platform.isLinux) {
            if (user == null) {
              _authStateChangesController.add(null);
            } else {
              _authStateChangesController.add(AppUser(
                id: user.uid,
                email: user.email,
                displayName: user.displayName,
                photoURL: user.photoURL,
                isAnonymous: user.isAnonymous,
              ));
            }
            notifyListeners();
          }
        }, onError: (e) {
          debugPrint("AuthRepository: Firebase Auth Stream Error: $e");
        });
      }
    } catch (e) {
      debugPrint("AuthRepository: Initialization Error: $e");
    }
  }

  @override
  void dispose() {
    _firebaseAuthSubscription?.cancel();
    _authStateChangesController.close();
    _manualAuthStateController.close();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn(GoogleSignInAccount user) async {
    try {
      final auth = user.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      print("AuthRepository: Successfully signed in via event stream.");
    } catch (e) {
      print("AuthRepository: Error handling Google Sign-In event: $e");
    }
  }

  Future<void> _loadLinuxSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('linux_user_session');
      if (userData != null) {
        print("AuthRepository: Loading Linux session from SharedPreferences...");
        final Map<String, dynamic> map = jsonDecode(userData);
        _linuxUser = AppUser(
          id: map['id'],
          displayName: map['displayName'],
          email: map['email'],
          photoURL: map['photoURL'],
          isAnonymous: map['isAnonymous'] ?? false,
        );

        if (map['fullResponse'] != null) {
          final fullResponse = map['fullResponse'] as Map<String, dynamic>;
          // Always refresh the idToken on startup — saved tokens expire after 1 hour
          final refreshToken = fullResponse['refreshToken'] ?? fullResponse['refresh_token'];
          if (refreshToken != null) {
            print("AuthRepository: Refreshing expired Linux token...");
            final refreshed = await _refreshIdToken(refreshToken);
            if (refreshed != null) {
              // Merge fresh tokens into fullResponse and re-save
              fullResponse['idToken'] = refreshed['id_token'];
              fullResponse['refreshToken'] = refreshed['refresh_token'] ?? refreshToken;
              map['fullResponse'] = fullResponse;
              await prefs.setString('linux_user_session', jsonEncode(map));
              print("AuthRepository: Token refreshed successfully.");
            } else {
              print("AuthRepository: Token refresh failed, using cached token (may fail).");
            }
          }
          _updateFiredartToken(fullResponse);
        }

        _authStateChangesController.add(_linuxUser);
        _manualAuthStateController.add(_linuxUser);
        notifyListeners();
      } else {
        _authStateChangesController.add(null);
        _manualAuthStateController.add(null);
        notifyListeners();
      }
    } catch (e) {
      print("Error loading Linux session: $e");
      _authStateChangesController.add(null);
    }
  }

  /// Exchanges a refreshToken for a fresh idToken via Google Identity Toolkit
  Future<Map<String, dynamic>?> _refreshIdToken(String refreshToken) async {
    try {
      // Import is already present via desktop_auth_handler — use http directly
      final uri = Uri.parse(
        'https://securetoken.googleapis.com/v1/token?key=${_desktopAuthHandler.apiKey}',
      );
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'grant_type=refresh_token&refresh_token=$refreshToken',
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      print("AuthRepository: Token refresh HTTP error ${response.statusCode}: ${response.body}");
    } catch (e) {
      print("AuthRepository: Token refresh exception: $e");
    }
    return null;
  }

  void _updateFiredartToken(Map<String, dynamic> response) {
    try {
      print("AuthRepository: Synchronizing credentials with Firedart engine...");
      
      final Map<String, dynamic> tokenMap = {
        'localId': response['localId'] ?? response['id'] ?? response['user_id'] ?? _linuxUser?.id,
        'idToken': response['idToken'] ?? response['id_token'],
        'refreshToken': response['refreshToken'] ?? response['refresh_token'],
        'expiresIn': (response['expiresIn'] ?? response['expires_in'] ?? "3600").toString(),
      };
      
      if (tokenMap['idToken'] != null && tokenMap['localId'] != null) {
        fd.FirebaseAuth.instance.tokenProvider.setToken(tokenMap);
        print("AuthRepository: Firedart engine synchronized. Status: SIGNED_IN (UID: ${tokenMap['localId']})");
      }
    } catch (e) {
      print("Firedart token update error: $e");
    }
  }

  Future<void> _saveLinuxSession([Map<String, dynamic>? fullResponse]) async {
    if (_linuxUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> sessionData = {
      'id': _linuxUser!.id,
      'displayName': _linuxUser!.displayName,
      'email': _linuxUser!.email,
      'photoURL': _linuxUser!.photoURL,
      'isAnonymous': _linuxUser!.isAnonymous,
    };
    if (fullResponse != null) {
      sessionData['fullResponse'] = fullResponse;
    }
    await prefs.setString('linux_user_session', jsonEncode(sessionData));
    
    if (sessionData['fullResponse'] != null) {
      _updateFiredartToken(sessionData['fullResponse']);
    }
  }

  Future<void> _clearLinuxSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('linux_user_session');
    try {
      fd.FirebaseAuth.instance.signOut();
    } catch (_) {}
  }

  FirebaseAuth? get _auth {
    if (!kIsWeb && Platform.isLinux) return null;
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseAuth.instance;
      }
    } catch (e) {
      debugPrint("Auth access error: $e");
    }
    return null;
  }

  AppUser? get currentUser {
    if (!kIsWeb && Platform.isLinux) {
      return _linuxUser;
    }
    final user = _auth?.currentUser;
    if (user == null) return null;
    return AppUser(
      id: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
      isAnonymous: user.isAnonymous,
    );
  }

  Stream<AppUser?>? _authStateChangesStream;

  Stream<AppUser?> get authStateChanges {
    _authStateChangesStream ??= Stream<AppUser?>.multi((controller) {
      try {
        controller.add(currentUser);
      } catch (e) {
        debugPrint("AuthRepository: Initial state error: $e");
        controller.add(null);
      }
      final subscription = _authStateChangesController.stream.listen(controller.add);
      controller.onCancel = () => subscription.cancel();
    }).asBroadcastStream();
    return _authStateChangesStream!;
  }

  Future<void> signInAnonymously() async {
    if (!kIsWeb && Platform.isLinux) {
      final fdUser = await fd.FirebaseAuth.instance.signInAnonymously();
      _linuxUser = AppUser(id: fdUser.id, isAnonymous: true);
      _authStateChangesController.add(_linuxUser);
      _manualAuthStateController.add(_linuxUser);
      notifyListeners();
      return;
    }
    final auth = _auth;
    if (auth == null) throw Exception("Firebase Auth not initialized");
    await auth.signInAnonymously();
  }

  Future<void> signInWithGoogle() async {
    if (!kIsWeb && Platform.isLinux) {
      final result = await _desktopAuthHandler.signInWithGoogleDesktop();
      if (result != null && result is UserCredentialMock) {
        final data = result.data;
        _linuxUser = AppUser(
          id: data['localId'] ?? "google_linux",
          displayName: data['displayName'],
          email: data['email'],
          photoURL: data['photoUrl'],
        );
        await _saveLinuxSession(data);
        _authStateChangesController.add(_linuxUser);
        _manualAuthStateController.add(_linuxUser);
        notifyListeners();
      }
      return;
    }
    
    try {
      if (!_isGoogleSignInInitialized) {
        await GoogleSignIn.instance.initialize();
        _isGoogleSignInInitialized = true;
      }
      final GoogleSignInAccount account = await GoogleSignIn.instance.authenticate(
        scopeHint: [
          'https://www.googleapis.com/auth/calendar',
          'https://www.googleapis.com/auth/tasks',
        ],
      );
      _googleAccount = account;
      
      final GoogleSignInAuthentication googleAuth = account.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      
      final auth = _auth;
      if (auth == null) throw Exception("Firebase Auth not initialized");
      await auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb && Platform.isLinux) {
      _linuxUser = null;
      await _clearLinuxSession();
      _authStateChangesController.add(null);
      _manualAuthStateController.add(null);
      notifyListeners();
      return;
    }
    try {
      _googleAccount = null;
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _auth?.signOut();
  }

  /// Returns an authenticated HTTP client for Google APIs
  Future<http.Client?> getGoogleAuthClient() async {
    if (!kIsWeb && Platform.isLinux) {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('linux_user_session');
      if (userData != null) {
        final map = jsonDecode(userData);
        if (map['fullResponse'] != null) {
          final token = map['fullResponse']['google_access_token'];
          if (token != null) {
            return GoogleAuthClient({
              'Authorization': 'Bearer $token',
              'X-Goog-AuthUser': '0',
            });
          }
        }
      }
      return null;
    } else {
      if (_googleAccount != null) {
        final authHeaders = await _googleAccount!.authorizationClient.authorizationHeaders(
          [
            'https://www.googleapis.com/auth/calendar',
            'https://www.googleapis.com/auth/tasks',
          ]
        );
        if (authHeaders != null) {
          return GoogleAuthClient(authHeaders);
        }
      }
      return null;
    }
  }
}
