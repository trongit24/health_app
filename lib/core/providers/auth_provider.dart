import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '711053109880-8q4tb8fd47rfqot8lija2tlh3lnkp14b.apps.googleusercontent.com',
  );
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isAnonymous => _user?.isAnonymous ?? false;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _user = _auth.currentUser;
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  /// Sign in with Email and Password
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      final creds = await _auth.signInWithEmailAndPassword(email: email, password: password);
      _setLoading(false);
      return creds;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  /// Register with Email and Password and update Display Name
  Future<UserCredential?> registerWithEmail(String email, String password, String name) async {
    _setLoading(true);
    try {
      final creds = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (creds.user != null) {
        await creds.user!.updateDisplayName(name);
        await creds.user!.reload();
        _user = _auth.currentUser;
      }
      _setLoading(false);
      return creds;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    _setLoading(true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _setLoading(false);
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final creds = await _auth.signInWithCredential(credential);
      _setLoading(false);
      return creds;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  /// Enable Anonymous Cloud Sync
  Future<UserCredential?> signInAnonymously() async {
    _setLoading(true);
    try {
      final creds = await _auth.signInAnonymously();
      _setLoading(false);
      return creds;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _auth.signOut();
      try {
        if (await _googleSignIn.isSignedIn()) {
          await _googleSignIn.signOut();
        }
      } catch (e) {
        // Safe check for non-google login environments
      }
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }
}
