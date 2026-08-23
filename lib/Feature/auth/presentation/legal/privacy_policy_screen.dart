import 'package:flutter/material.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import 'legal_document_screen.dart';

/// ROSIVA Privacy Policy.
///
/// ============================================================
/// EDIT ME: everything below is placeholder text so the screen
/// works out of the box. Replace the strings in each
/// [LegalSection] with your real privacy policy whenever you're
/// ready — nothing else in the app needs to change.
/// ============================================================
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;

    return LegalDocumentScreen(
      title: lang.privacyPolicy,
      lastUpdated: lang.legalLastUpdatedPlaceholder,
      sections: [
        LegalSection(
          title: lang.privacySection1Title,
          body: lang.privacySection1Body,
        ),
        LegalSection(
          title: lang.privacySection2Title,
          body: lang.privacySection2Body,
        ),
        LegalSection(
          title: lang.privacySection3Title,
          body: lang.privacySection3Body,
        ),
        LegalSection(
          title: lang.privacySection4Title,
          body: lang.privacySection4Body,
        ),
        LegalSection(
          title: lang.privacySection5Title,
          body: lang.privacySection5Body,
        ),
        LegalSection(
          title: lang.privacySection6Title,
          body: lang.privacySection6Body,
        ),
      ],
    );
  }
}
