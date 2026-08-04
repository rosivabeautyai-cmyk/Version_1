import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../core/styles/colors.dart';
import '../../../core/widgets/main_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/data/models/user_model.dart';
import '../../auth/provider/auth_provider.dart';

/// The regular user's home screen, shown once a user is signed in,
/// their email is verified, and their Firestore `role` is `"user"`.
///
/// This is a real (not placeholder) screen: it pulls the signed-in
/// user's data from Firestore via [AuthProvider.fetchUserData] and
/// displays it in a welcome card. Add your actual feature sections
/// (AI assistant, favorites, etc.) below the welcome card.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? _userData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Deferred to after the first frame so this never fires a
    // notifyListeners() while AuthGate's StreamBuilder is still
    // mid-build (that's what caused the earlier crash).
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUser());
  }

  Future<void> _loadUser() async {
    final auth = context.read<AuthProvider>();
    final data = await auth.fetchUserData();
    if (!mounted) return;
    setState(() {
      _userData = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final lang = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(lang.appName),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.blackcolor,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: lang.logOut,
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : ListView(
                padding: EdgeInsets.all(20.w),
                children: [
                  _WelcomeCard(userData: _userData),
                  SizedBox(height: 24.h),
                  Text(
                    'ابدأي من هنا',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blackcolor,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // TODO: replace this placeholder card with your
                  // real feature sections (AI assistant, favorites,
                  // affiliate offers, etc.)
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: AppColors.continerbg,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: AppColors.bordercolor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 32.sp),
                        SizedBox(height: 12.h),
                        Text(
                          'محتوى الصفحة الرئيسية لسه محتاج تتضاف هنا',
                          style: TextStyle(fontSize: 14.sp, color: AppColors.graycolor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final UserModel? userData;

  const _WelcomeCard({required this.userData});

  @override
  Widget build(BuildContext context) {
    final name = userData?.fullName.isNotEmpty == true ? userData!.fullName : 'ROSIVA User';
    final email = userData?.email ?? '';

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28.r,
            backgroundColor: Colors.white,
            backgroundImage: (userData?.photoUrl != null && userData!.photoUrl!.isNotEmpty)
                ? NetworkImage(userData!.photoUrl!)
                : null,
            child: (userData?.photoUrl == null || userData!.photoUrl!.isEmpty)
                ? Icon(Icons.person_rounded, color: AppColors.primary, size: 28.sp)
                : null,
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أهلًا، $name',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  email,
                  style: TextStyle(fontSize: 12.sp, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Standalone alternate entry point kept for convenience if you ever
/// want a "sign out" button styled with [MainButton] elsewhere.
class HomeSignOutButton extends StatelessWidget {
  const HomeSignOutButton({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final lang = AppLocalizations.of(context)!;
    return MainButton(text: lang.logOut, onpress: () => auth.logout());
  }
}
