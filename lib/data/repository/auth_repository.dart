import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class AuthRepository {
  FirebaseAuth? get _auth {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseAuth.instance;
      }
    } catch (e) {
      debugPrint("Auth access error: $e");
    }
    return null;
  }

  User? get currentUser => _auth?.currentUser;

  Stream<User?> get authStateChanges => _auth?.authStateChanges() ?? const Stream.empty();

  Future<UserCredential?> signInAnonymously() async {
    try {
      final auth = _auth;
      if (auth == null) throw Exception("Firebase Auth not initialized");
      return await auth.signInAnonymously();
    } catch (e) {
      debugPrint("Auth Error: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth?.signOut();
  }
}
