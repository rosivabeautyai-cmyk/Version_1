import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:rosivia/core/providers/theme_provider.dart';
import 'package:rosivia/l10n/app_localizations.dart';

/// Section label used above a group of settings rows (e.g.
/// "Localization", "Notifications", "Transparency & Legal").
class SettingsSectionLabel extends StatelessWidget {
  final String text;

  const SettingsSectionLabel(this.text, {super.key});

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

/// A card that groups a set of [SettingsTile]s together with
/// dividers, matching the reference design's rounded settings
/// groups.
class SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const SettingsCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
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

/// A single settings row: icon, title, optional subtitle, and a
/// trailing widget (chevron / switch / value text).
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
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
                  color: (iconColor ?? colorScheme.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  icon,
                  size: 18.sp,
                  color: iconColor ?? colorScheme.primary,
                ),
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
              trailing ??
                  (onTap != null
                      ? Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14.sp,
                          color: theme.colorScheme.onSurfaceVariant,
                        )
                      : const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Localized label for a [ThemeMode] — shared so the trailing value
/// text on the "Dark Mode" settings row (both user-facing and admin)
/// always agrees with the picker sheet below.
String themeModeLabel(AppLocalizations lang, ThemeMode mode) {
  return switch (mode) {
    ThemeMode.light => lang.themeLight,
    ThemeMode.dark => lang.themeDark,
    ThemeMode.system => lang.themeSystem,
  };
}

/// Bottom-sheet picker for Light/Dark/System, shared between the
/// user-facing and admin Settings screens so appearance selection
/// stays in exactly one place.
void showThemeModePicker(BuildContext context, ThemeProvider themeProvider) {
  final lang = AppLocalizations.of(context)!;

  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(lang.darkMode, style: theme.textTheme.titleMedium),
              ),
              const SizedBox(height: 8),
              for (final mode in ThemeMode.values)
                ListTile(
                  leading: Icon(
                    switch (mode) {
                      ThemeMode.light => Icons.light_mode_outlined,
                      ThemeMode.dark => Icons.dark_mode_outlined,
                      ThemeMode.system => Icons.brightness_auto_outlined,
                    },
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(themeModeLabel(lang, mode)),
                  trailing: themeProvider.themeMode == mode
                      ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
                      : null,
                  onTap: () {
                    themeProvider.setThemeMode(mode);
                    Navigator.pop(sheetContext);
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}
