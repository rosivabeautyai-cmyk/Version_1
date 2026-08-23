import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

/// AuthRepository contains the business logic for authentication.
///
/// It calls into [AuthService] for raw Firebase operations and into
/// Cloud Firestore for user document persistence. Presentation code
/// (the provider) should only ever talk to this repository — never
/// directly to Firebase.
class AuthRepository {
  final AuthService _authService;
  final FirebaseFirestore _firestore;

  static const String _usersCollection = 'users';

  AuthRepository({
    AuthService? authService,
    FirebaseFirestore? firestore,
  })  : _authService = authService ?? AuthService(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _authService.authStateChanges;

  User? get currentUser => _authService.currentUser;

  bool get isAppleSignInAvailable => AuthService.isAppleSignInAvailable;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(_usersCollection);

  /// Logs in a user and updates their `lastLogin` timestamp.
  ///
  /// Also self-heals accounts whose Firestore document never got
  /// created (e.g. if Firestore was disabled/misconfigured at the
  /// time they first signed up) by creating it here if missing.
  Future<User> login({
    required String email,
    required String password,
  }) async {
    final credential = await _authService.login(email: email, password: password);
    final user = credential.user;
    if (user == null) {
      throw const AuthFailure('unknown', 'Login failed. Please try again.');
    }
    await _createUserDocIfMissing(user: user, isFirstLogin: false);
    await _touchLastLogin(user.uid);
    return user;
  }

  /// Registers a new user, creates their Firestore document, and
  /// sends the email verification link.
  Future<User> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final credential = await _authService.register(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw const AuthFailure(
        'unknown',
        'Registration failed. Please try again.',
      );
    }

    await user.updateDisplayName(fullName);

    final newUser = UserModel.newUser(
      uid: user.uid,
      fullName: fullName,
      email: email.trim(),
      photoUrl: user.photoURL,
      isEmailVerified: user.emailVerified,
    );

    await _usersRef.doc(user.uid).set(newUser.toCreateMap());
    await _authService.verifyEmail();

    return user;
  }

  /// Signs out the current user from Firebase, Google, and Apple.
  Future<void> logout() => _authService.logout();

  /// Sends a password reset email.
  Future<void> forgotPassword({required String email}) =>
      _authService.forgotPassword(email: email);

  /// Resends the email verification link to the current user.
  Future<void> sendVerificationEmail() => _authService.verifyEmail();

  /// Reloads the current user and returns whether their email is
  /// now verified. Also syncs the flag to Firestore when it flips.
  Future<bool> reloadAndCheckVerification() async {
    final user = await _authService.reloadUser();
    if (user == null) return false;

    if (user.emailVerified) {
      await _usersRef
          .doc(user.uid)
          .set({'isEmailVerified': true}, SetOptions(merge: true));
    }

    return user.emailVerified;
  }

  /// Signs in with Google, creating a Firestore document on first login.
  Future<User> googleSignIn() async {
    final credential = await _authService.googleSignIn();
    final user = credential.user;
    if (user == null) {
      throw const AuthFailure(
        'unknown',
        'Google sign-in failed. Please try again.',
      );
    }
    await _createUserDocIfMissing(
      user: user,
      isFirstLogin: credential.additionalUserInfo?.isNewUser ?? false,
    );
    await _touchLastLogin(user.uid);
    return user;
  }

  /// Signs in with Apple, creating a Firestore document on first login.
  Future<User> appleSignIn() async {
    final credential = await _authService.appleSignIn();
    final user = credential.user;
    if (user == null) {
      throw const AuthFailure(
        'unknown',
        'Apple sign-in failed. Please try again.',
      );
    }
    await _createUserDocIfMissing(
      user: user,
      isFirstLogin: credential.additionalUserInfo?.isNewUser ?? false,
    );
    await _touchLastLogin(user.uid);
    return user;
  }

  /// Fetches the Firestore user document for the given uid.
  Future<UserModel?> getUserData(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromSnapshot(doc);
  }

  /// Streams the Firestore user document for the given uid, used by
  /// [FavoritesProvider] to react instantly to favorite changes.
  Stream<UserModel?> watchUserData(String uid) {
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromSnapshot(doc);
    });
  }

  /// Adds [productId] to the current user's `favorites` array.
  Future<void> addFavorite({required String uid, required String productId}) {
    return _usersRef.doc(uid).set(
      {
        'favorites': FieldValue.arrayUnion([productId]),
      },
      SetOptions(merge: true),
    );
  }

  /// Removes [productId] from the current user's `favorites` array.
  Future<void> removeFavorite({
    required String uid,
    required String productId,
  }) {
    return _usersRef.doc(uid).set(
      {
        'favorites': FieldValue.arrayRemove([productId]),
      },
      SetOptions(merge: true),
    );
  }

  /// Public entry point so callers like [AuthGate] can repair an
  /// incomplete Firestore doc for the currently signed-in user even
  /// on a resumed session — not just right after a fresh sign-in
  /// call (login/googleSignIn/appleSignIn already do this on their
  /// own).
  Future<void> ensureUserDoc(User user) =>
      _createUserDocIfMissing(user: user, isFirstLogin: false);

  /// Creates (or repairs) the Firestore user document.
  ///
  /// This used to only check `doc.exists`, which meant a doc that
  /// already existed but was missing its core fields — e.g. one
  /// created by a partial write like `_touchLastLogin` merging in
  /// just `lastLogin` before the full document ever got created —
  /// would silently stay incomplete forever. Now it checks for the
  /// `role` field specifically (the one every account must have) and
  /// backfills the full profile with `merge: true` whenever it's
  /// missing, without clobbering fields that are already correct
  /// (like an existing `lastLogin` or `isEmailVerified`).
  Future<void> _createUserDocIfMissing({
    required User user,
    required bool isFirstLogin,
  }) async {
    final docRef = _usersRef.doc(user.uid);
    final doc = await docRef.get();
    final data = doc.data();
    final isIncomplete = !doc.exists || data == null || !data.containsKey('role');

    if (isIncomplete) {
      final newUser = UserModel.newUser(
        uid: user.uid,
        fullName: user.displayName ?? 'ROSIVA User',
        email: user.email ?? '',
        photoUrl: user.photoURL,
        isEmailVerified: user.emailVerified,
      );
      await docRef.set(newUser.toCreateMap(), SetOptions(merge: true));
    }
  }

  Future<void> _touchLastLogin(String uid) async {
    // `set` + merge instead of `update`: `update` throws NOT_FOUND if
    // the document doesn't exist yet (e.g. a race with doc creation,
    // or a legacy account from before Firestore was enabled). `set`
    // with merge creates it if missing and just updates the field
    // otherwise — either way this never throws NOT_FOUND.
    await _usersRef.doc(uid).set(
      {'lastLogin': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }
}
