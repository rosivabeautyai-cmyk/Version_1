import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:rosivia/Feature/auth/presentation/legal/privacy_policy_screen.dart';
import 'package:rosivia/Feature/auth/presentation/legal/terms_of_service_screen.dart';
import 'package:rosivia/Feature/auth/provider/auth_provider.dart';
import 'package:rosivia/Feature/home/presentation/screens/edit_profile_screen.dart';
import 'package:rosivia/Feature/home/presentation/screens/security_screen.dart';
import 'package:rosivia/Feature/intro/language/language_provider.dart';
import 'package:rosivia/Feature/intro/language/language_tile.dart';
import 'package:rosivia/core/functions/navigations.dart';
import 'package:rosivia/core/providers/theme_provider.dart';
import 'package:rosivia/core/responsive/responsive.dart';
import 'package:rosivia/core/services/notification_service.dart';
import 'package:rosivia/core/services/snackbar_service.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import '../../provider/notification_prefs_provider.dart';
import '../../provider/regional_prefs_provider.dart';
import '../widgets/settings_widgets.dart';
import 'contact_us_screen.dart';
import 'help_center_screen.dart';
import 'legal_info_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // RegionalPrefsProvider is now app-wide (see main.dart) so a
    // country change here immediately reflects on product screens.
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
    final regionalPrefs = context.watch<RegionalPrefsProvider>();

    final isArabic = languageProvider.locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.settings, style: theme.textTheme.titleMedium),
      ),
      body: SafeArea(
        child: PageContainer(
          maxWidth: 720,
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
                      regionalPrefs.countryCode != null
                          ? regionalPrefs.countryName(
                              lang,
                              regionalPrefs.countryCode!,
                            )
                          : regionalPrefs.countryIsInferred
                              ? '${lang.autoBasedOnLocation} · '
                                  '${regionalPrefs.countryName(lang, regionalPrefs.effectiveCountryCode!)}'
                              : lang.autoBasedOnLocation,
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.end,
                    ),
                    onTap: () =>
                        _showCountryPicker(context, regionalPrefs, lang),
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
                  // Not tappable — currency is derived from the
                  // selected country (see RegionalPrefsProvider), never
                  // picked independently, so there's nothing to open a
                  // picker for here.
                  SettingsTile(
                    icon: Icons.attach_money_rounded,
                    title: lang.currency,
                    trailing: Text(
                      regionalPrefs.currencyCode ?? lang.autoBasedOnLocation,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),

              SettingsSectionLabel(lang.notifications),
              SettingsCard(
                children: [
                  SettingsTile(
                    icon: Icons.notifications_active_outlined,
                    title: lang.pushNotifications,
                    subtitle: _pushSubtitle(lang, notifPrefs.pushStatus),
                    trailing: notifPrefs.pushBusy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Switch(
                            value: notifPrefs.pushOn,
                            onChanged: (v) =>
                                _togglePush(context, notifPrefs, lang, v),
                          ),
                  ),
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
                    icon: Icons.verified_user_outlined,
                    title: lang.aiAccuracyTitle,
                    onTap: () => pushTo(
                      context,
                      LegalInfoScreen(
                        title: lang.aiAccuracyTitle,
                        body: lang.aiAccuracyDesc,
                        icon: Icons.verified_user_outlined,
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

              SettingsSectionLabel(lang.accountSettings),
              SettingsCard(
                children: [
                  SettingsTile(
                    icon: Icons.person_outline_rounded,
                    title: lang.editProfile,
                    onTap: () => pushTo(context, const EditProfileScreen()),
                  ),
                  SettingsTile(
                    icon: Icons.lock_outline_rounded,
                    title: lang.security,
                    onTap: () => pushTo(context, const SecurityScreen()),
                  ),
                ],
              ),

              SettingsSectionLabel(lang.support),
              SettingsCard(
                children: [
                  SettingsTile(
                    icon: Icons.help_outline_rounded,
                    title: lang.helpCenter,
                    onTap: () => pushTo(context, const HelpCenterScreen()),
                  ),
                  SettingsTile(
                    icon: Icons.mail_outline_rounded,
                    title: lang.contactUs,
                    onTap: () => pushTo(context, const ContactUsScreen()),
                  ),
                ],
              ),

              SettingsSectionLabel(lang.preferences),
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
                    icon: Icons.logout_rounded,
                    title: lang.logOut,
                    iconColor: theme.colorScheme.error,
                    onTap: () => _confirmLogout(context, lang),
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
              Text(
                lang.language,
                style: Theme.of(context).textTheme.titleMedium,
              ),
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

  void _showCountryPicker(
    BuildContext context,
    RegionalPrefsProvider regionalPrefs,
    AppLocalizations lang,
  ) {
    _showOptionPicker(
      context: context,
      title: lang.country,
      options: [
        _PickerOption(
          label: lang.autoBasedOnLocation,
          selected: regionalPrefs.countryCode == null,
          onTap: () => regionalPrefs.setCountry(null),
        ),
        for (final code in regionalPrefs.resolvedCountryCodes)
          _PickerOption(
            label: regionalPrefs.countryName(lang, code),
            selected: regionalPrefs.countryCode == code,
            onTap: () => regionalPrefs.setCountry(code),
          ),
      ],
    );
  }

  void _showOptionPicker({
    required BuildContext context,
    required String title,
    required List<_PickerOption> options,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(8.w, 20.h, 8.w, 8.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
                SizedBox(height: 8.h),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final option in options)
                        ListTile(
                          title: Text(option.label),
                          trailing: option.selected
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: theme.colorScheme.primary,
                                )
                              : null,
                          onTap: () {
                            option.onTap();
                            Navigator.pop(sheetContext);
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _pushSubtitle(AppLocalizations lang, PushStatus status) {
    switch (status) {
      case PushStatus.enabled:
        return lang.pushStatusEnabled;
      case PushStatus.denied:
        return lang.pushBlockedTitle;
      case PushStatus.notConfigured:
        return lang.pushNotConfigured;
      case PushStatus.notEnabled:
      case PushStatus.unknown:
        return lang.pushNotificationsDesc;
    }
  }

  Future<void> _togglePush(
    BuildContext context,
    NotificationPrefsProvider prefs,
    AppLocalizations lang,
    bool value,
  ) async {
    final uid = context.read<AuthProvider>().currentUser?.uid;
    if (uid == null) return;

    if (!value) {
      await prefs.disablePush(uid);
      if (context.mounted) {
        SnackbarService.info(context, lang.pushDisabledToast);
      }
      return;
    }

    if (prefs.pushStatus == PushStatus.denied) {
      if (context.mounted) _showPushBlockedDialog(context, lang);
      return;
    }

    final res = await prefs.enablePush(uid);
    if (!context.mounted) return;
    switch (res) {
      case PushEnableResult.enabled:
        SnackbarService.success(context, lang.pushEnabledToast);
        break;
      case PushEnableResult.denied:
        _showPushBlockedDialog(context, lang);
        break;
      case PushEnableResult.notConfigured:
        SnackbarService.info(context, lang.pushNotConfigured);
        break;
      case PushEnableResult.error:
        SnackbarService.error(context, lang.pushEnableFailed);
        break;
    }
  }

  void _showPushBlockedDialog(BuildContext context, AppLocalizations lang) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(lang.pushBlockedTitle),
        content: Text(lang.pushBlockedBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(lang.done),
          ),
        ],
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

class _PickerOption {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PickerOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });
}
