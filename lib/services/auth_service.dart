import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Wraps Firebase Auth + Google Sign-In for the optional "sign in to sync"
/// feature. Nothing else in the app depends on this — Prakriyā works fully
/// offline; signing in only adds a cloud copy of your data under your own
/// Google account.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // The Web (type 3) OAuth client from google-services.json — Android needs
  // this passed as the serverClientId to get a verifiable ID token back.
  static const _serverClientId =
      '191375066674-nfovb3noep8q4e0kqanill93emno1r8f.apps.googleusercontent.com';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _initialized = false;

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => currentUser != null;
  Stream<User?> get userChanges => _auth.authStateChanges();

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(serverClientId: _serverClientId);
    _initialized = true;
  }

  /// Returns the signed-in user, or null if the sheet was dismissed or
  /// something went wrong (no network, no Google account on the device).
  Future<User?> signInWithGoogle() async {
    await _ensureInitialized();
    try {
      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;
      final credential =
          GoogleAuthProvider.credential(idToken: googleAuth.idToken);
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (_) {
      return null;
    }
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Not signed in with Google this session — fine, still sign out of Firebase below.
    }
    await _auth.signOut();
  }
}
