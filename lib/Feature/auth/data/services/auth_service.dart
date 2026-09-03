import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/services.dart' show PlatformException;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// A thin wrapper around a [FirebaseAuthException] that carries a
/// human-readable message already mapped from the Firebase error code.
class AuthFailure implements Exception {
  final String code;
  final String message;

  const AuthFailure(this.code, this.message);

  @override
  String toString() => message;
}

/// AuthService is the ONLY class allowed to talk directly to
/// Firebase Authentication, Google Sign-In, and Apple Sign-In.
///
/// It contains no business logic — that lives in [AuthRepository].
class AuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: ['email']);

  /// Stream of auth state changes (null when signed out).
  ///
  /// Deliberately NOT memoised: `firebase_auth_web`'s implementation is
  /// an `async*` generator that yields `currentUser` first on each new
  /// subscription. A fresh call therefore primes a late subscriber
  /// (e.g. the new `AuthGate` created by `pushNamedAndRemoveUntil`
  /// right after a Google popup) with the already-signed-in user —
  /// which is exactly how the user reaches Home. Re-subscription churn
  /// on rebuilds is handled by `AuthGate` caching this once per
  /// instance, not here.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Currently signed-in Firebase user, if any.
  User? get currentUser => _firebaseAuth.currentUser;

  /// Signs in an existing user with email and password.
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapException(e);
    } catch (_) {
      throw const AuthFailure(
        'unknown',
        'Something went wrong. Please try again.',
      );
    }
  }

  /// Creates a new user with email and password.
  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapException(e);
    } catch (_) {
      throw const AuthFailure(
        'unknown',
        'Something went wrong. Please try again.',
      );
    }
  }

  /// Signs out of Firebase Auth, Google, and any active Apple session.
  Future<void> logout() async {
    try {
      final signedInWithGoogle = await _googleSignIn.isSignedIn();
      if (signedInWithGoogle) {
        await _googleSignIn.signOut();
      }
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _mapException(e);
    } catch (_) {
      throw const AuthFailure(
        'unknown',
        'Failed to sign out. Please try again.',
      );
    }
  }

  /// Sends a password reset email.
  Future<void> forgotPassword({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapException(e);
    } catch (_) {
      throw const AuthFailure(
        'unknown',
        'Failed to send reset email. Please try again.',
      );
    }
  }

  /// Sends a Firebase email verification link to the current user.
  Future<void> verifyEmail() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthFailure('no-user', 'No signed-in user found.');
      }
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _mapException(e);
    }
  }

  /// Reloads the current user from Firebase to refresh their
  /// `emailVerified` status. Returns the refreshed [User], or null
  /// if no user is signed in.
  Future<User?> reloadUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;
      await user.reload();
      return _firebaseAuth.currentUser;
    } on FirebaseAuthException catch (e) {
      throw _mapException(e);
    }
  }

  /// Signs in with Google and returns the resulting [UserCredential].
  ///
  /// Web and mobile use different, platform-correct flows:
  ///  * **Web** — Firebase's own popup flow
  ///    (`signInWithPopup(GoogleAuthProvider())`). The `google_sign_in`
  ///    package's `signIn()` is not supported on Flutter Web in the 6.x
  ///    line (it requires the rendered button / One Tap), which is why
  ///    the pink "continue with Google" button was failing. This path
  ///    needs the Google provider enabled in the Firebase console and
  ///    the web domain in Authentication → Settings → Authorized
  ///    domains (see WEB_DEPLOYMENT.md) — no OAuth client id in code.
  ///  * **Mobile (Android/iOS)** — the existing `google_sign_in` flow,
  ///    unchanged.
  Future<UserCredential> googleSignIn() async {
    if (kIsWeb) {
      try {
        final provider = GoogleAuthProvider()..addScope('email');
        return await _firebaseAuth.signInWithPopup(provider);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'popup-closed-by-user' ||
            e.code == 'cancelled-popup-request' ||
            e.code == 'user-cancelled') {
          throw const AuthFailure(
            'sign-in-cancelled',
            'Google sign-in was cancelled.',
          );
        }
        if (e.code == 'popup-blocked') {
          throw const AuthFailure(
            'popup-blocked',
            'Your browser blocked the Google sign-in popup. Allow popups for this site and try again.',
          );
        }
        throw _mapException(e);
      } on AuthFailure {
        rethrow;
      } catch (_) {
        throw const AuthFailure(
          'google-sign-in-failed',
          'Google sign-in failed. Please try again.',
        );
      }
    }

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw const AuthFailure(
          'sign-in-cancelled',
          'Google sign-in was cancelled.',
        );
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // TEMP diagnostic: a missing ID token is the usual symptom of a
      // build without `default_web_client_id` (google-services resource
      // not applied). Surface it instead of failing opaquely later.
      if (googleAuth.idToken == null) {
        throw AuthFailure(
          'google-no-id-token',
          'Google sign-in returned no ID token '
              '(accessToken=${googleAuth.accessToken == null ? "null" : "present"}). '
              'Check default_web_client_id / SHA-1 registration.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _mapException(e);
    } on AuthFailure {
      rethrow;
    } on PlatformException catch (e) {
      // Native Google Sign-In failure. `sign_in_canceled` = user backed
      // out. Everything else: surface the REAL code + message TEMPORARILY
      // (e.g. "ApiException: 10" == DEVELOPER_ERROR == SHA-1 / OAuth
      // client / package-name mismatch for this signed build). Revert to
      // a friendly string once sign-in is verified on a Play build.
      if (e.code == 'sign_in_canceled' || e.code == 'canceled') {
        throw const AuthFailure(
          'sign-in-cancelled',
          'Google sign-in was cancelled.',
        );
      }
      throw AuthFailure(
        'gsi:${e.code}',
        'Google sign-in failed — code=${e.code} · '
            'message=${e.message ?? "(none)"} · '
            'details=${e.details ?? "(none)"}',
      );
    } catch (e) {
      // TEMP diagnostic: include the raw error instead of swallowing it.
      throw AuthFailure('google-sign-in-failed', 'Google sign-in failed: $e');
    }
  }

  /// Signs in with Apple using the sign_in_with_apple package.
  /// Should only be invoked on iOS/macOS platforms.
  Future<UserCredential> appleSignIn() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(
        oauthCredential,
      );

      // Apple only returns the user's name on the very first sign-in.
      final fullName = <String>[
        if (appleCredential.givenName != null &&
            appleCredential.givenName!.isNotEmpty)
          appleCredential.givenName!,
        if (appleCredential.familyName != null &&
            appleCredential.familyName!.isNotEmpty)
          appleCredential.familyName!,
      ].join(' ');

      if (fullName.isNotEmpty &&
          (userCredential.user?.displayName == null ||
              userCredential.user!.displayName!.isEmpty)) {
        await userCredential.user?.updateDisplayName(fullName);
      }

      return userCredential;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AuthFailure(
          'sign-in-cancelled',
          'Apple sign-in was cancelled.',
        );
      }
      throw AuthFailure('apple-sign-in-failed', e.message);
    } on FirebaseAuthException catch (e) {
      throw _mapException(e);
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure(
        'apple-sign-in-failed',
        'Apple sign-in failed. Please try again.',
      );
    }
  }

  /// Whether Apple Sign-In should be offered on this platform.
  static bool get isAppleSignInAvailable {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Maps a raw [FirebaseAuthException] into a friendly [AuthFailure].
  AuthFailure _mapException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return const AuthFailure(
          'invalid-email',
          'The email address is not valid.',
        );
      case 'user-disabled':
        return const AuthFailure(
          'user-disabled',
          'This account has been disabled. Contact support.',
        );
      case 'user-not-found':
        return const AuthFailure(
          'user-not-found',
          'No account found with this email.',
        );
      case 'wrong-password':
        return const AuthFailure(
          'wrong-password',
          'Incorrect password. Please try again.',
        );
      case 'email-already-in-use':
        return const AuthFailure(
          'email-already-in-use',
          'An account already exists with this email.',
        );
      case 'operation-not-allowed':
        return const AuthFailure(
          'operation-not-allowed',
          'This sign-in method is currently disabled.',
        );
      case 'weak-password':
        return const AuthFailure(
          'weak-password',
          'Please choose a stronger password.',
        );
      case 'network-request-failed':
        return const AuthFailure(
          'network-request-failed',
          'Network error. Please check your connection.',
        );
      case 'too-many-requests':
        return const AuthFailure(
          'too-many-requests',
          'Too many attempts. Please try again later.',
        );
      case 'invalid-credential':
        return const AuthFailure(
          'invalid-credential',
          'Invalid credentials. Please try again.',
        );
      case 'account-exists-with-different-credential':
        return const AuthFailure(
          'account-exists-with-different-credential',
          'An account already exists with a different sign-in method.',
        );
      case 'requires-recent-login':
        return const AuthFailure(
          'requires-recent-login',
          'Please sign in again to continue.',
        );
      default:
        return AuthFailure(
          e.code,
          e.message ?? 'Authentication failed. Please try again.',
        );
    }
  }
}
