import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
 import 'package:flutter/foundation.dart'; // for kIsWeb


class AppAuthProvider extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _google = GoogleSignIn();

  User? get user => _auth.currentUser;
  Stream<User?> get authState => _auth.authStateChanges();

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  Future<void> signInWithEmail(String email, String pass) async {
    _setLoading(true);
    _error = null;
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: pass);
    } on FirebaseAuthException catch (e) {
      _error = _friendlyError(e.code);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> registerWithEmail(String email, String pass, String name) async {
    _setLoading(true);
    _error = null;
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );
      await cred.user?.updateDisplayName(name);
    } on FirebaseAuthException catch (e) {
      _error = _friendlyError(e.code);
    } finally {
      _setLoading(false);
    }
  }


Future<void> signInWithGoogle() async {
  _setLoading(true);
  _error = null;

  try {
    if (kIsWeb) {
      // Web → use Firebase popup
      final provider = GoogleAuthProvider();
      await _auth.signInWithPopup(provider);
    } else {
      // Android/iOS → use google_sign_in
      final gUser = await _google.signIn();
      if (gUser == null) {
        _setLoading(false);
        return;
      }

      final gAuth = await gUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
    }
  } catch (e) {
    print("Google Sign-In Error: $e");
    _error = 'Google sign-in failed. Try again.';
  } finally {
    _setLoading(false);
  }
}

  Future<void> signOut() async {
    await _google.signOut();
    await _auth.signOut();
  }

  String _friendlyError(String code) => switch (code) {
    'user-not-found' => 'No account found with this email.',
    'wrong-password' => 'Incorrect password.',
    'email-already-in-use' => 'Email already registered.',
    'weak-password' => 'Password is too weak.',
    'invalid-email' => 'Invalid email address.',
    _ => 'Authentication failed. Try again.',
  };
}
