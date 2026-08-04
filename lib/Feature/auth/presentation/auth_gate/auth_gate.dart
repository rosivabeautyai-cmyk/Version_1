import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:rosivia/core/styles/colors.dart';

import '../../../admin/presentation/admin_home_screen.dart';
import '../../../home/presentation/home_screen.dart';
import '../../data/models/user_model.dart';
import '../../provider/auth_provider.dart';
import '../login/login_screen.dart';
import '../verify_email/verify_email_screen.dart';

/// AuthGate is the root routing widget for ROSIVA.
///
/// It listens to [FirebaseAuth.authStateChanges] and decides which
/// screen to show:
///
///   Not logged in            -> [LoginScreen]
///   Logged in, not verified  -> [VerifyEmailScreen]
///   Logged in, verified, user  -> [HomeScreen]
///   Logged in, verified, admin -> [AdminHomeScreen]
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return StreamBuilder<User?>(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AuthGateLoading();
        }

        final user = snapshot.data;

        if (user == null) {
          return const LoginScreen();
        }

        return _EmailVerificationCheck(user: user);
      },
    );
  }
}

/// Reloads the user once on entry to get a fresh `emailVerified`
/// value, then routes to Home or the verification screen.
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
    // IMPORTANT: this used to call _checkVerification() directly,
    // which calls AuthProvider.reloadUser() -> notifyListeners()
    // synchronously, before any `await`. Since initState() runs
    // *during* AuthGate's StreamBuilder build, that notifyListeners()
    // tried to rebuild the same provider scope mid-build and Flutter
    // threw "setState() or markNeedsBuild() called during build."
    // Scheduling it for the next frame (post-build) fixes that.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVerification());
  }

  Future<void> _checkVerification() async {
    final auth = context.read<AuthProvider>();
    final verified = await auth.reloadUser();

    // Only bother reading the Firestore role once the email is
    // actually verified — an unverified user will see the
    // VerifyEmailScreen regardless of their role.
    bool isAdmin = false;
    if (verified) {
      await auth.ensureUserDoc();
      final userData = await auth.fetchUserData(widget.user.uid);
      isAdmin = userData?.isAdmin ?? false;
    }

    if (!mounted) return;
    setState(() {
      _isVerified = verified;
      _isAdmin = isAdmin;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const _AuthGateLoading();
    }

    if (!_isVerified) {
      return const VerifyEmailScreen();
    }

    return _isAdmin ? const AdminHomeScreen() : const HomeScreen();
  }
}

class _AuthGateLoading extends StatelessWidget {
  const _AuthGateLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }
}
