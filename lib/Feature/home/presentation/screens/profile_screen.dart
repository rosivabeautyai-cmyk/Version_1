import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:rosivia/core/functions/navigations.dart';
import 'package:rosivia/core/responsive/responsive.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import '../../../auth/data/models/user_model.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../settings/presentation/screens/contact_us_screen.dart';
import '../../../settings/presentation/screens/help_center_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import 'edit_profile_screen.dart';
import 'my_beauty_profile_screen.dart';
import 'security_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onShowFavorites;

  const ProfileScreen({super.key, this.onShowFavorites});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _userData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUser());
  }

  Future<void> _loadUser() async {
    final data = await context.read<AuthProvider>().fetchUserData();
    if (!mounted) return;
    setState(() {
      _userData = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.profile, style: theme.textTheme.titleMedium),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadUser,
          child: PageContainer(
            maxWidth: 720,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(20.w),
              children: [
                _ProfileHeader(userData: _userData, loading: _loading),
                SizedBox(height: 24.h),

                Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.face_retouching_natural_rounded,
                        title: lang.myBeautyProfile,
                        subtitle: lang.myBeautyProfileDesc,
                        onTap: () =>
                            pushTo(context, const MyBeautyProfileScreen()),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.favorite_rounded,
                        title: lang.favoritesAndCollections,
                        subtitle: lang.favoritesSubtitle,
                        onTap: widget.onShowFavorites,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),

                _ProfileSectionLabel(lang.accountSettings),
                _ProfileCard(
                  children: [
                    _ProfileTile(
                      icon: Icons.person_outline_rounded,
                      title: lang.editProfile,
                      onTap: () => pushTo(context, const EditProfileScreen()),
                    ),
                    _ProfileTile(
                      icon: Icons.lock_outline_rounded,
                      title: lang.security,
                      onTap: () => pushTo(context, const SecurityScreen()),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),

                _ProfileSectionLabel(lang.preferences),
                _ProfileCard(
                  children: [
                    _ProfileTile(
                      icon: Icons.settings_outlined,
                      title: lang.settings,
                      subtitle: lang.settingsSubtitle,
                      onTap: () => pushTo(context, const SettingsScreen()),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),

                _ProfileSectionLabel(lang.support),
                _ProfileCard(
                  children: [
                    _ProfileTile(
                      icon: Icons.help_outline_rounded,
                      title: lang.helpCenter,
                      onTap: () => pushTo(context, const HelpCenterScreen()),
                    ),
                    _ProfileTile(
                      icon: Icons.mail_outline_rounded,
                      title: lang.contactUs,
                      onTap: () => pushTo(context, const ContactUsScreen()),
                    ),
                  ],
                ),
                SizedBox(height: 28.h),

                OutlinedButton.icon(
                  onPressed: () => _confirmLogout(context, lang),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, 52.h),
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(
                      color: theme.colorScheme.error.withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(lang.logOut),
                ),
                SizedBox(height: 12.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AppLocalizations lang) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(lang.logOut),
          content: Text(lang.confirmLogout),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(lang.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<AuthProvider>().logout();
              },
              child: Text(lang.logOut),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserModel? userData;
  final bool loading;

  const _ProfileHeader({required this.userData, required this.loading});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lang = AppLocalizations.of(context)!;

    final name = userData?.fullName.isNotEmpty == true
        ? userData!.fullName
        : lang.rosivaUserFallback;
    final email = userData?.email ?? '';
    final photoUrl = userData?.photoUrl;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    final createdAt = userData?.createdAt;

    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 38.r,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.10),
            backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
            child: hasPhoto
                ? null
                : Icon(
                    Icons.person_rounded,
                    size: 40.sp,
                    color: colorScheme.primary,
                  ),
          ),
          SizedBox(height: 16.h),
          Text(
            loading ? lang.yourProfile : name,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          if (email.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              email,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
          if (createdAt != null) ...[
            SizedBox(height: 6.h),
            Text(
              lang.memberSince(createdAt.year.toString()),
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colorScheme.primary, size: 24.sp),
              SizedBox(height: 10.h),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileSectionLabel extends StatelessWidget {
  final String text;

  const _ProfileSectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h, top: 4.h),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final List<Widget> children;

  const _ProfileCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(
                height: 1,
                indent: 16.w,
                endIndent: 16.w,
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
          ],
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Row(
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, size: 18.sp, color: colorScheme.primary),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    if (subtitle != null) ...[
                      SizedBox(height: 3.h),
                      Text(subtitle!, style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14.sp,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
