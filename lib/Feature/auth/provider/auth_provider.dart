import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/remember_me_service.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/auth_service.dart';

/// Central ChangeNotifier that drives every screen in the auth module.
///
/// Holds text controllers, UI flags, and orchestrates calls into
/// [AuthRepository]. Screens should only ever read from / call into
/// this provider — never touch Firebase or the repository directly.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  AuthProvider({AuthRepository? repository})
      : _repository = repository ?? AuthRepository() {
    _restoreRememberedEmail();
  }

  // ---------------------------------------------------------------------
  // Controllers
  // ---------------------------------------------------------------------
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController forgotEmailController = TextEditingController();

  // ---------------------------------------------------------------------
  // UI State
  // ---------------------------------------------------------------------
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _obscurePassword = true;
  bool get obscurePassword => _obscurePassword;

  bool _obscureConfirmPassword = true;
  bool get obscureConfirmPassword => _obscureConfirmPassword;

  bool _rememberMe = false;
  bool get rememberMe => _rememberMe;

  bool _agreedToTerms = false;
  bool get agreedToTerms => _agreedToTerms;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isResendingEmail = false;
  bool get isResendingEmail => _isResendingEmail;

  bool _isCheckingVerification = false;
  bool get isCheckingVerification => _isCheckingVerification;

  bool get isAppleSignInAvailable => _repository.isAppleSignInAvailable;

  User? get currentUser => _repository.currentUser;

  Stream<User?> get authStateChanges => _repository.authStateChanges;

  // ---------------------------------------------------------------------
  // UI togglers
  // ---------------------------------------------------------------------
  void togglePassword() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleConfirmPassword() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }

  void toggleRememberMe() {
    _rememberMe = !_rememberMe;
    notifyListeners();
  }

  void toggleAgreedToTerms() {
    _agreedToTerms = !_agreedToTerms;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> _restoreRememberedEmail() async {
    final remembered = await RememberMeService.getRememberMe();
    if (remembered) {
      final savedEmail = await RememberMeService.getSavedEmail();
      _rememberMe = true;
      if (savedEmail != null) {
        emailController.text = savedEmail;
      }
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------

  /// Logs in with email + password. Returns true on success.
  Future<bool> login() async {
    _errorMessage = null;
    _setLoading(true);
    try {
      await _repository.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      await RememberMeService.setRememberMe(
        _rememberMe,
        email: emailController.text.trim(),
      );
      return true;
    } on AuthFailure catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Registers a new account, creates the Firestore doc, and sends
  /// the verification email. Returns true on success.
  Future<bool> register() async {
    _errorMessage = null;
    _setLoading(true);
    try {
      await _repository.register(
        fullName: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      return true;
    } on AuthFailure catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Signs in with Google. Returns true on success.
  Future<bool> googleSignIn() async {
    _errorMessage = null;
    _setLoading(true);
    try {
      await _repository.googleSignIn();
      return true;
    } on AuthFailure catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Google sign-in failed. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Signs in with Apple. Returns true on success.
  Future<bool> appleSignIn() async {
    _errorMessage = null;
    _setLoading(true);
    try {
      await _repository.appleSignIn();
      return true;
    } on AuthFailure catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Apple sign-in failed. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Signs the current user out and clears all controllers.
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _repository.logout();
      _clearControllers();
    } on AuthFailure catch (e) {
      _errorMessage = e.message;
    } finally {
      _setLoading(false);
    }
  }

  /// Sends a password reset email. Returns true on success.
  Future<bool> forgotPassword() async {
    _errorMessage = null;
    _setLoading(true);
    try {
      await _repository.forgotPassword(
        email: forgotEmailController.text.trim(),
      );
      return true;
    } on AuthFailure catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Resends the verification email to the current user.
  Future<bool> sendVerificationEmail() async {
    _errorMessage = null;
    _isResendingEmail = true;
    notifyListeners();
    try {
      await _repository.sendVerificationEmail();
      return true;
    } on AuthFailure catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Failed to resend email. Please try again.';
      return false;
    } finally {
      _isResendingEmail = false;
      notifyListeners();
    }
  }

  /// Fetches the Firestore document (including `role`) for the given
  /// uid, or for the current user if no uid is passed. Used by
  /// [AuthGate] to decide between the admin and user home screens.
  Future<UserModel?> fetchUserData([String? uid]) {
    final targetUid = uid ?? currentUser?.uid;
    if (targetUid == null) return Future.value(null);
    return _repository.getUserData(targetUid);
  }

  /// Live stream of the current user's Firestore document, used to
  /// keep the Favorites screen and product hearts in sync in
  /// real time.
  Stream<UserModel?> watchCurrentUser() {
    final uid = currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _repository.watchUserData(uid);
  }

  Future<void> addFavorite(String productId) {
    final uid = currentUser?.uid;
    if (uid == null) return Future.value();
    return _repository.addFavorite(uid: uid, productId: productId);
  }

  Future<void> removeFavorite(String productId) {
    final uid = currentUser?.uid;
    if (uid == null) return Future.value();
    return _repository.removeFavorite(uid: uid, productId: productId);
  }

  /// Updates a subset of profile fields on the current user's
  /// Firestore document. Never touches Firebase Auth itself.
  Future<void> updateProfile({
    String? fullName,
    String? skinType,
    String? country,
  }) {
    final uid = currentUser?.uid;
    if (uid == null) return Future.value();
    return _repository.updateProfile(
      uid: uid,
      fullName: fullName,
      skinType: skinType,
      country: country,
    );
  }

  /// Sends a password reset email to the current user's own address,
  /// reusing the same repository call as the "forgot password" flow.
  Future<bool> sendPasswordResetToCurrentUser() async {
    final email = currentUser?.email;
    if (email == null) return false;
    _errorMessage = null;
    _setLoading(true);
    try {
      await _repository.forgotPassword(email: email);
      return true;
    } on AuthFailure catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Repairs the current user's Firestore doc if it's missing or
  /// incomplete (e.g. missing the `role` field). Safe to call every
  /// time the app resumes an existing session, not just right after
  /// a fresh sign-in.
  Future<void> ensureUserDoc() async {
    final user = currentUser;
    if (user == null) return;
    await _repository.ensureUserDoc(user);
  }

  /// Reloads the current user and returns whether the email is verified.
  Future<bool> reloadUser() async {
    _isCheckingVerification = true;
    notifyListeners();
    try {
      return await _repository.reloadAndCheckVerification();
    } on AuthFailure catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      return false;
    } finally {
      _isCheckingVerification = false;
      notifyListeners();
    }
  }

  void _clearControllers() {
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    nameController.clear();
    forgotEmailController.clear();
    _agreedToTerms = false;
    _obscurePassword = true;
    _obscureConfirmPassword = true;
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    forgotEmailController.dispose();
    super.dispose();
  }
}
