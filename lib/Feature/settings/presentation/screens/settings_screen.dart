import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:rosivia/Feature/auth/presentation/legal/privacy_policy_screen.dart';
import 'package:rosivia/Feature/auth/presentation/legal/terms_of_service_screen.dart';
import 'package:rosivia/Feature/intro/language/language_provider.dart';
import 'package:rosivia/Feature/intro/language/language_tile.dart';
import 'package:rosivia/core/functions/navigations.dart';
import 'package:rosivia/core/providers/theme_provider.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import '../../provider/notification_prefs_provider.dart';
import '../widgets/settings_widgets.dart';
import 'legal_info_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotificationPrefsProvider()..load(),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;
    final languageProvider = context.watch<LanguageProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final notifPrefs = context.watch<NotificationPrefsProvider>();

    final isArabic = languageProvider.locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.settings, style: theme.textTheme.titleMedium),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(20.w),
          children: [
            Text(lang.settings, style: theme.textTheme.headlineSmall),
            SizedBox(height: 4.h),
            Text(lang.settingsSubtitle, style: theme.textTheme.bodyMedium),
            SizedBox(height: 20.h),

            SettingsSectionLabel(lang.localization),
            SettingsCard(
              children: [
                SettingsTile(
                  icon: Icons.public_rounded,
                  title: lang.country,
                  trailing: Text(
                    lang.autoBasedOnLocation,
                    style: theme.textTheme.bodySmall,
                  ),
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
                SettingsTile(
                  icon: Icons.attach_money_rounded,
                  title: lang.currency,
                  trailing: Text(
                    lang.autoBasedOnLocation,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),

            SettingsSectionLabel(lang.notifications),
            SettingsCard(
              children: [
                SettingsTile(
                  icon: Icons.auto_awesome_rounded,
                  title: lang.aiRecommendations,
                  subtitle: lang.aiRecommendationsDesc,
                  trailing: Switch(
                    value: notifPrefs.aiRecommendations,
                    onChanged: notifPrefs.setAiRecommendations,
                  ),
                ),
                SettingsTile(
                  icon: Icons.sell_outlined,
                  title: lang.priceDrops,
                  subtitle: lang.priceDropsDesc,
                  trailing: Switch(
                    value: notifPrefs.priceDrops,
                    onChanged: notifPrefs.setPriceDrops,
                  ),
                ),
                SettingsTile(
                  icon: Icons.explore_outlined,
                  title: lang.newDiscoveries,
                  subtitle: lang.newDiscoveriesDesc,
                  trailing: Switch(
                    value: notifPrefs.newDiscoveries,
                    onChanged: notifPrefs.setNewDiscoveries,
                  ),
                ),
              ],
            ),

            SettingsSectionLabel(lang.transparencyAndLegal),
            SettingsCard(
              children: [
                SettingsTile(
                  icon: Icons.handshake_outlined,
                  title: lang.affiliateTransparency,
                  onTap: () => pushTo(
                    context,
                    LegalInfoScreen(
                      title: lang.affiliateTransparency,
                      body: lang.affiliateTransparencyDesc,
                      icon: Icons.handshake_outlined,
                    ),
                  ),
                ),
                SettingsTile(
                  icon: Icons.health_and_safety_outlined,
                  title: lang.medicalDisclaimer,
                  onTap: () => pushTo(
                    context,
                    LegalInfoScreen(
                      title: lang.medicalAdviceDisclaimerTitle,
                      body: lang.medicalAdviceDisclaimerDesc,
                      icon: Icons.health_and_safety_outlined,
                    ),
                  ),
                ),
                SettingsTile(
                  icon: Icons.description_outlined,
                  title: lang.termsOfServiceShort,
                  onTap: () => pushTo(context, const TermsOfServiceScreen()),
                ),
                SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: lang.privacyPolicy,
                  onTap: () => pushTo(context, const PrivacyPolicyScreen()),
                ),
              ],
            ),

            SettingsSectionLabel(lang.preferences),
            SettingsCard(
              children: [
                SettingsTile(
                  icon: Icons.dark_mode_outlined,
                  title: lang.darkMode,
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: themeProvider.toggleDarkMode,
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.h),
            Center(
              child: Text(
                lang.appVersion('2.4.0 (102)'),
                style: theme.textTheme.bodySmall,
              ),
            ),
            SizedBox(height: 24.h),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 30.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(lang.language, style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 18.h),
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
              SizedBox(height: 14.h),
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
}
