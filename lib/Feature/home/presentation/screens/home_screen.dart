import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:rosivia/core/widgets/main_button.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import '../../../auth/data/models/user_model.dart';
import '../../../auth/provider/auth_provider.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_feature_card.dart';
import '../widgets/home_loading.dart';
import '../widgets/home_section_title.dart';
import '../widgets/welcome_card.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUser();
    });
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
    final lang = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: HomeAppBar(
        title: lang.appName,
        onLogout: () {
          context.read<AuthProvider>().logout();
        },
      ),
      body: SafeArea(
        child: _loading
            ? const HomeLoading()
            : RefreshIndicator(
                onRefresh: _loadUser,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(20.w),
                  children: [
                    WelcomeCard(userData: _userData),

                    SizedBox(height: 28.h),

                    HomeSectionTitle(title: lang.homeStartHere),

                    SizedBox(height: 14.h),

                    HomeFeatureCard(
                      icon: Icons.auto_awesome_rounded,
                      title: lang.homeDiscoverMoreTitle,
                      description: lang.homeDiscoverMoreDesc,
                      onTap: () {},
                    ),

                    SizedBox(height: 14.h),

                    HomeFeatureCard(
                      icon: Icons.favorite_rounded,
                      title: lang.favorites,
                      description: lang.homeFavoritesDesc,
                      onTap: () {},
                    ),

                    SizedBox(height: 14.h),

                    HomeFeatureCard(
                      icon: Icons.person_rounded,
                      title: lang.homeMyAccountTitle,
                      description: lang.homeMyAccountDesc,
                      onTap: () {},
                    ),

                    SizedBox(height: 24.h),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Optional standalone logout button.
///
/// يمكن استخدامه في أي مكان آخر داخل التطبيق إذا احتجنا
/// زر Logout بنفس Theme التطبيق.
class HomeSignOutButton extends StatelessWidget {
  const HomeSignOutButton({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final lang = AppLocalizations.of(context)!;

    return MainButton(text: lang.logOut, onpress: () => auth.logout());
  }
}
