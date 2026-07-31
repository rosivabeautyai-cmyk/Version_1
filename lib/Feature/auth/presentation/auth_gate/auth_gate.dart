import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:rosivia/core/styles/colors.dart';
import 'package:rosivia/l10n/app_localizations.dart';

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
///   Logged in, verified      -> the app's Home screen
///
/// Replace [HomeScreenPlaceholder] with your actual home screen
/// widget once it exists in your app.
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

  @override
  void initState() {
    super.initState();
    _checkVerification();
  }

  Future<void> _checkVerification() async {
    final auth = context.read<AuthProvider>();
    final verified = await auth.reloadUser();
    if (!mounted) return;
    setState(() {
      _isVerified = verified;
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

    return const HomeScreenPlaceholder();
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

/// Temporary placeholder shown once a user is signed in and verified.
///
/// Replace this widget with your app's real Home screen — it exists
/// here only so the auth module compiles and runs standalone.
class HomeScreenPlaceholder extends StatelessWidget {
  const HomeScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final lang = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(lang.appName)),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 56.sp,
              ),
              SizedBox(height: 16.h),
              Text(
                lang.signedInAndVerified,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 24.h),
              OutlinedButton(
                onPressed: () => auth.logout(),
                child: Text(lang.logOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
