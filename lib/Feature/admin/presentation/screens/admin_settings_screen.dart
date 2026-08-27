import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import 'package:rosivia/Feature/home/presentation/screens/edit_profile_screen.dart';
import 'package:rosivia/Feature/home/presentation/screens/security_screen.dart';
import 'package:rosivia/Feature/intro/language/language_provider.dart';
import 'package:rosivia/Feature/intro/language/language_tile.dart';
import 'package:rosivia/Feature/settings/presentation/widgets/settings_widgets.dart';
import 'package:rosivia/core/functions/navigations.dart';
import 'package:rosivia/core/providers/theme_provider.dart';

import '../../../auth/provider/auth_provider.dart';

/// Admin Settings — every row here connects to functionality that
/// already exists elsewhere in the app (reused, not duplicated):
/// Account/Security reuse the same screens the user-facing Profile
/// uses, Appearance reuses [ThemeProvider], Language reuses
/// [LanguageProvider]. Notifications has no admin-specific system
/// (the existing notification prefs are shopper-facing — reusing
/// them here would be misleading), so it's shown honestly as
/// "coming soon" instead.
class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;
    final languageProvider = context.watch<LanguageProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isArabic = languageProvider.locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(title: Text(lang.navSettings)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(lang.navSettings, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(lang.adminSettingsScreenSubtitle, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),
            SettingsSectionLabel(lang.adminSectionAccount),
            SettingsCard(
              children: [
                SettingsTile(
                  icon: Icons.person_outline_rounded,
                  title: lang.editProfile,
                  onTap: () => pushTo(context, const EditProfileScreen()),
                ),
              ],
            ),
            SettingsSectionLabel(lang.adminSectionAppearance),
            SettingsCard(
              children: [
                SettingsTile(
                  icon: Icons.dark_mode_outlined,
                  title: lang.darkMode,
                  trailing: Text(
                    themeModeLabel(lang, themeProvider.themeMode),
                    style: theme.textTheme.bodySmall,
                  ),
                  onTap: () => showThemeModePicker(context, themeProvider),
                ),
                SettingsTile(
                  icon: Icons.translate_rounded,
                  title: lang.language,
                  trailing: Text(
                    isArabic ? 'العربية' : 'English',
                    style: theme.textTheme.bodySmall,
                  ),
                  onTap: () => _showLanguagePicker(context),
                ),
              ],
            ),
            SettingsSectionLabel(lang.notifications),
            SettingsCard(
              children: [
                SettingsTile(
                  icon: Icons.notifications_outlined,
                  title: lang.notifications,
                  subtitle: lang.adminNotificationsComingSoonDesc,
                  iconColor: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            SettingsSectionLabel(lang.security),
            SettingsCard(
              children: [
                SettingsTile(
                  icon: Icons.lock_outline_rounded,
                  title: lang.security,
                  onTap: () => pushTo(context, const SecurityScreen()),
                ),
                SettingsTile(
                  icon: Icons.logout_rounded,
                  title: lang.logOut,
                  iconColor: theme.colorScheme.error,
                  onTap: () => _confirmLogout(context, lang),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final languageProvider = context.read<LanguageProvider>();
    final lang = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(lang.language, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 18),
              LanguageTile(
                title: 'العربية',
                subtitle: 'Arabic',
                flag: '🇪🇬',
                isSelected: languageProvider.locale.languageCode == 'ar',
                onTap: () {
                  languageProvider.changeLanguage('ar');
                  Navigator.pop(sheetContext);
                },
              ),
              const SizedBox(height: 14),
              LanguageTile(
                title: 'English',
                subtitle: 'English',
                flag: '🇺🇸',
                isSelected: languageProvider.locale.languageCode == 'en',
                onTap: () {
                  languageProvider.changeLanguage('en');
                  Navigator.pop(sheetContext);
                },
              ),
            ],
          ),
        );
      },
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
