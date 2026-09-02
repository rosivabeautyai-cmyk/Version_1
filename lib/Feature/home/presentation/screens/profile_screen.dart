import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:rosivia/core/constants/app_images.dart';
import 'package:rosivia/core/functions/navigations.dart';
import 'package:rosivia/core/responsive/responsive.dart';
import 'package:rosivia/core/services/snackbar_service.dart';
import 'package:rosivia/core/widgets/motion/app_fade_in.dart';
import 'package:rosivia/core/widgets/motion/pressable_scale.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import '../../../auth/data/models/user_model.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../settings/presentation/screens/contact_us_screen.dart';
import '../../../settings/presentation/screens/help_center_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../widgets/home_bottom_nav_bar.dart';
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

  void _editAvatar() {
    // The pick → compress → upload-to-Storage flow needs the
    // image_picker + firebase_storage packages and Storage rules, which
    // aren't set up yet. Wired to a real handler once those land.
    SnackbarService.info(context, AppLocalizations.of(context)!.avatarUploadSoon);
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
              padding: EdgeInsets.fromLTRB(
                20.w,
                20.w,
                20.w,
                HomeBottomNavBar.bottomInset(context),
              ),
              children: [
                AppFadeIn(
                  child: _ProfileHeader(
                    userData: _userData,
                    loading: _loading,
                    onEditAvatar: _editAvatar,
                  ),
                ),
                SizedBox(height: 24.h),

                AppFadeIn(
                  delay: const Duration(milliseconds: 60),
                  child: Row(
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
                ),
                SizedBox(height: 24.h),

                AppFadeIn(
                  delay: const Duration(milliseconds: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProfileSectionLabel(lang.accountSettings),
                      _ProfileCard(
                        children: [
                          _ProfileTile(
                            icon: Icons.person_outline_rounded,
                            title: lang.editProfile,
                            onTap: () =>
                                pushTo(context, const EditProfileScreen()),
                          ),
                          _ProfileTile(
                            icon: Icons.lock_outline_rounded,
                            title: lang.security,
                            onTap: () =>
                                pushTo(context, const SecurityScreen()),
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
                            onTap: () =>
                                pushTo(context, const SettingsScreen()),
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
                            onTap: () =>
                                pushTo(context, const HelpCenterScreen()),
                          ),
                          _ProfileTile(
                            icon: Icons.mail_outline_rounded,
                            title: lang.contactUs,
                            onTap: () =>
                                pushTo(context, const ContactUsScreen()),
                          ),
                        ],
                      ),
                    ],
                  ),
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
  final VoidCallback onEditAvatar;

  const _ProfileHeader({
    required this.userData,
    required this.loading,
    required this.onEditAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lang = AppLocalizations.of(context)!;

    final name = userData?.fullName.isNotEmpty == true
        ? userData!.fullName
        : lang.rosivaUserFallback;
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
          ProfileAvatar(
            avatarUrl: userData?.avatarUrl,
            radius: 40.r,
            onEdit: onEditAvatar,
          ),
          SizedBox(height: 16.h),
          Text(
            loading ? lang.yourProfile : name,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
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

/// Circular avatar with a soft brand ring and a tap-to-change edit
/// badge. Shows the user's own uploaded photo when present, otherwise
/// the bundled model portrait — never a provider (Google/Apple) photo.
class ProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double radius;
  final VoidCallback? onEdit;
  final bool busy;

  const ProfileAvatar({
    super.key,
    required this.avatarUrl,
    required this.radius,
    this.onEdit,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final uploaded = avatarUrl != null && avatarUrl!.trim().isNotEmpty;

    final inner = ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: busy
            ? ColoredBox(
                color: colorScheme.primary.withValues(alpha: 0.08),
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : uploaded
                ? Image.network(
                    avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stack) => const _AssetAvatar(),
                    loadingBuilder: (context, child, progress) =>
                        progress == null ? child : const _AssetAvatar(),
                  )
                : const _AssetAvatar(),
      ),
    );

    return GestureDetector(
      onTap: busy ? null : onEdit,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.35),
                width: 2,
              ),
            ),
            child: inner,
          ),
          if (onEdit != null)
            PositionedDirectional(
              end: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).cardColor, width: 2),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    size: 14, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class _AssetAvatar extends StatelessWidget {
  const _AssetAvatar();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Image.asset(
      AppImages.profileAvatar,
      fit: BoxFit.cover,
      errorBuilder: (_, error, stack) => ColoredBox(
        color: primary.withValues(alpha: 0.10),
        child: Icon(Icons.person_rounded, color: primary, size: 34.sp),
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

    return PressableScale(
      child: Material(
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
