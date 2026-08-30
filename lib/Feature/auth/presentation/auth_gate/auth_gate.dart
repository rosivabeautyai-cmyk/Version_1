import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:rosivia/Feature/admin/presentation/screens/admin_shell.dart';
import 'package:rosivia/Feature/home/presentation/screens/main_screen.dart';
import 'package:rosivia/Feature/settings/provider/regional_prefs_provider.dart';

import '../../provider/auth_provider.dart';
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
///   Logged in + Verified + Normal User
///       ↓
///   MainScreen
///
///   Logged in + Verified + Admin
///       ↓
///   AdminShell
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return StreamBuilder<User?>(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        // Firebase is still checking the current authentication state.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AuthGateLoading();
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

      // Refresh Firebase user information.
      final verified = await auth.reloadUser();

      bool isAdmin = false;

      if (verified) {
        // Make sure the user's Firestore document exists.
        await auth.ensureUserDoc();

        // Now that Firestore reads are authorized, refresh the
        // Firestore-backed country/currency config (its first attempt
        // at app start ran before sign-in and fell back to defaults).
        if (mounted) {
          // fire-and-forget — best-effort, never blocks routing
          context.read<RegionalPrefsProvider>().load();
        }

        // Get the user's latest data from Firestore.
        final userData = await auth.fetchUserData(widget.user.uid);

        isAdmin = userData?.isAdmin ?? false;
      }

      if (!mounted) return;

      setState(() {
        _isVerified = verified;
        _isAdmin = isAdmin;
        _checking = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isVerified = false;
        _isAdmin = false;
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

    // Verified Admin.
    if (_isAdmin) {
      return const AdminShell();
    }

    // Verified normal user.
    return const MainScreen();
  }
}

/// Loading screen shown while Firebase authentication
/// and user information are being checked.
class _AuthGateLoading extends StatelessWidget {
  const _AuthGateLoading();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      ),
    );
  }
}
