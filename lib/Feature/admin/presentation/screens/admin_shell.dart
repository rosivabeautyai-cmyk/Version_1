import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:rosivia/core/functions/navigations.dart';

import '../../../auth/data/models/user_model.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../provider/admin_config_provider.dart';
import '../widgets/admin_bottom_nav.dart';
import '../widgets/admin_header.dart';
import '../widgets/admin_sidebar.dart';
import 'admin_dashboard_screen.dart';
import 'admin_platforms_screen.dart';
import 'admin_products_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_users_screen.dart';

/// Breakpoint above which the sidebar is shown permanently instead of
/// as a drawer/bottom nav.
const _desktopBreakpoint = 900.0;

/// The admin experience's navigation shell: Dashboard/Users/Products/
/// Platforms as the 4 primary tabs (bottom nav on mobile, permanent
/// sidebar on desktop), Settings reached via the profile menu.
///
/// Shown only to accounts whose Firestore `users/{uid}.role` field is
/// `"admin"` — see `AuthGate`. There is no in-app way to become an
/// admin; that field must be changed by hand in the Firebase console.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;
  UserModel? _adminUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAdminUser());
  }

  Future<void> _loadAdminUser() async {
    final user = await context.read<AuthProvider>().fetchUserData();
    if (!mounted) return;
    setState(() => _adminUser = user);
  }

  void _selectTab(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  void _openSettings() => pushTo(context, const AdminSettingsScreen());

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width >= _desktopBreakpoint;

    final screens = [
      AdminDashboardScreen(
        onViewProductsTap: () => _selectTab(2),
        onViewUsersTap: () => _selectTab(1),
        onSettingsTap: _openSettings,
      ),
      const AdminUsersScreen(),
      const AdminProductsScreen(),
      const AdminPlatformsScreen(),
    ];

    final sidebar = AdminSidebar(
      adminUser: _adminUser,
      currentIndex: _currentIndex,
      onTabSelected: _selectTab,
      onSettingsTap: _openSettings,
      onLogout: auth.logout,
    );

    return ChangeNotifierProvider(
      create: (_) => AdminConfigProvider(),
      child: Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AdminHeader(
        adminUser: _adminUser,
        onMenuTap: isDesktop ? null : () => Scaffold.of(context).openDrawer(),
        onSettingsTap: _openSettings,
        onLogout: auth.logout,
      ),
      drawer: isDesktop ? null : Drawer(width: 280, child: sidebar),
      bottomNavigationBar: isDesktop
          ? null
          : AdminBottomNav(currentIndex: _currentIndex, onItemSelected: _selectTab),
      body: SafeArea(
        top: false,
        child: Row(
          children: [
            if (isDesktop)
              SizedBox(
                width: 260,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: BorderDirectional(
                      end: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  child: sidebar,
                ),
              ),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: screens,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
