import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import '../../../core/styles/colors.dart';
import '../../auth/provider/auth_provider.dart';

/// The admin dashboard, shown only to accounts whose Firestore
/// `users/{uid}.role` field is `"admin"`.
///
/// There is no in-app way to become an admin — that field must be
/// changed by hand in the Firebase console. See `firestore.rules`.
///
/// This pulls a couple of quick stats (total users, unverified
/// users) straight from Firestore so it's a real working screen, not
/// just a placeholder. Add your real admin tools (manage users,
/// review content, etc.) below the stats row.
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  bool _loading = true;
  int _totalUsers = 0;
  int _verifiedUsers = 0;

  @override
  void initState() {
    super.initState();
    // Deferred to after the first frame so this never fires a
    // notifyListeners()/setState() while AuthGate's StreamBuilder is
    // still mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStats());
  }

  Future<void> _loadStats() async {
    try {
      final usersRef = FirebaseFirestore.instance.collection('users');
      final totalSnapshot = await usersRef.count().get();
      final verifiedSnapshot =
          await usersRef.where('isEmailVerified', isEqualTo: true).count().get();
      if (!mounted) return;
      setState(() {
        _totalUsers = totalSnapshot.count ?? 0;
        _verifiedUsers = verifiedSnapshot.count ?? 0;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final lang = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(lang.adminDashboardTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.people_alt_rounded,
                          label: lang.totalUsers,
                          value: '$_totalUsers',
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.verified_rounded,
                          label: lang.verifiedEmails,
                          value: '$_verifiedUsers',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    lang.adminToolsTitle,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blackcolor,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // TODO: replace with real admin tools — manage
                  // users, review reported content, edit app
                  // content, etc.
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: AppColors.continerbg,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: AppColors.bordercolor),
                    ),
                    child: Text(
                      lang.adminToolsPlaceholder,
                      style: TextStyle(fontSize: 14.sp, color: AppColors.graycolor),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.continerbg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.bordercolor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 26.sp),
          SizedBox(height: 10.h),
          Text(
            value,
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w800, color: AppColors.blackcolor),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: AppColors.graycolor),
          ),
        ],
      ),
    );
  }
}
