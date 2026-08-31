import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:rosivia/Feature/admin/presentation/screens/admin_shell.dart';
import 'package:rosivia/Feature/home/presentation/screens/main_screen.dart';
import 'package:rosivia/Feature/settings/provider/regional_prefs_provider.dart';
import 'package:rosivia/core/constants/app_images.dart';
import 'package:rosivia/core/styles/colors.dart';

import '../../provider/auth_provider.dart';
import '../complete_registration/complete_registration_screen.dart';
import '../login/login_screen.dart';
import '../verify_email/verify_email_screen.dart';

/// AuthGate is the root routing widget for ROSIVA.
///
/// Routing logic:
///
///   Not logged in
///       ↓
///   LoginScreen
///
///   Logged in + Email not verified
///       ↓
///   VerifyEmailScreen
///
///   Logged in + Verified + Terms not yet accepted (fresh social sign-in)
///       ↓
///   CompleteRegistrationScreen
///
///   Logged in + Verified + Registration complete + Normal User
///       ↓
///   MainScreen
///
///   Logged in + Verified + Registration complete + Admin
///       ↓
///   AdminShell
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  /// Captured ONCE for this AuthGate instance (not memoised globally):
  /// route rebuilds reuse it so there's no re-subscription churn, while
  /// a brand-new AuthGate (e.g. from `pushNamedAndRemoveUntil` right
  /// after a Google popup) still gets a fresh stream that primes with
  /// the already-signed-in `currentUser`.
  late final Stream<User?> _authStream;

  bool _loadTimedOut = false;
  Timer? _timeout;

  @override
  void initState() {
    super.initState();
    _authStream = context.read<AuthProvider>().authStateChanges;
    // If Firebase Auth never reports a state at all — SDK wedged or
    // offline — don't spin on the loading screen forever. Fall through
    // to the login screen so the app stays usable.
    _timeout = Timer(const Duration(seconds: 8), () {
      if (mounted && !_loadTimedOut) setState(() => _loadTimedOut = true);
    });
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, snapshot) {
        // The auth state could not be determined (stream error). Show
        // the login screen rather than crashing or looping.
        if (snapshot.hasError) {
          return const LoginScreen();
        }

        // Firebase is still checking the current authentication state.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loadTimedOut ? const LoginScreen() : const _AuthGateLoading();
        }

        final user = snapshot.data;

        // No authenticated user.
        if (user == null) {
          return const LoginScreen();
        }

        // Authenticated user.
        return _EmailVerificationCheck(user: user);
      },
    );
  }
}

/// Checks the user's email verification status and admin status.
///
/// The Firebase user is reloaded once so that we get the latest
/// emailVerified value.
class _EmailVerificationCheck extends StatefulWidget {
  final User user;

  const _EmailVerificationCheck({required this.user});

  @override
  State<_EmailVerificationCheck> createState() =>
      _EmailVerificationCheckState();
}

class _EmailVerificationCheckState extends State<_EmailVerificationCheck> {
  bool _checking = true;
  bool _isVerified = false;
  bool _isAdmin = false;

  /// True only for a fresh social sign-in whose Firestore doc has
  /// `registrationCompleted == false` — i.e. still owes Terms consent.
  /// Legacy accounts (field absent) and completed accounts both leave
  /// this `false`, so no existing user is ever bounced to the gate.
  bool _needsRegistration = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUserStatus();
    });
  }

  Future<void> _checkUserStatus() async {
    try {
      final auth = context.read<AuthProvider>();

      // Verification decision: the already-authenticated user's own
      // flag is the source of truth (a Google account is verified
      // immediately). `reloadUser()` is only a best-effort refresh — a
      // transient network/SDK error on the web must NOT bounce a
      // verified user to the "verify your email" screen.
      var verified = widget.user.emailVerified;
      try {
        final refreshed = await auth.reloadUser();
        verified = verified || refreshed;
      } catch (_) {
        // keep widget.user.emailVerified
      }

      bool isAdmin = false;
      bool needsRegistration = false;

      if (verified) {
        // Ensure the Firestore user doc — best-effort. On failure it is
        // recreated by the next sign-in's `_touchLastLogin`; do not
        // block routing to Home over it. For a first-time Google/Apple
        // sign-in this is what creates the doc with
        // `registrationCompleted: false`.
        try {
          await auth.ensureUserDoc();
        } catch (_) {}

        if (mounted) {
          // fire-and-forget — best-effort, never blocks routing
          context.read<RegionalPrefsProvider>().load();
        }

        // One read covers both the admin decision and the
        // consent-gate decision. Best-effort: if it can't be read
        // right now the user still reaches Home (existing admins /
        // legacy accounts already have a doc, so this rarely matters,
        // and a missing/unreadable doc must not trap the user on the
        // consent gate).
        try {
          final userData = await auth.fetchUserData(widget.user.uid);
          isAdmin = userData?.isAdmin ?? false;
          needsRegistration =
              userData != null && !userData.isRegistrationComplete;
        } catch (_) {}
      }

      if (!mounted) return;

      setState(() {
        _isVerified = verified;
        _isAdmin = isAdmin;
        _needsRegistration = needsRegistration;
        _checking = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isVerified = false;
        _isAdmin = false;
        _needsRegistration = false;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Still checking Firebase / Firestore.
    if (_checking) {
      return const _AuthGateLoading();
    }

    // Email is not verified.
    if (!_isVerified) {
      return const VerifyEmailScreen();
    }

    // Verified, but a fresh social sign-in that still owes Terms
    // consent — must not reach Home yet.
    if (_needsRegistration) {
      return const CompleteRegistrationScreen();
    }

    // Verified Admin.
    if (_isAdmin) {
      return const AdminShell();
    }

    // Verified normal user.
    return const MainScreen();
  }
}

/// Loading screen shown while Firebase authentication and the Firestore
/// user document are being resolved.
///
/// It reuses the existing splash artwork (not modified — just displayed
/// here too) so the hand-off SplashScreen -> AuthGate is visually
/// seamless and there is never a bare-spinner flash.
class _AuthGateLoading extends StatelessWidget {
  const _AuthGateLoading();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.continerbg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(AppImages.splash, width: 200, height: 200),
            const SizedBox(height: 24),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
