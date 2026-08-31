import 'package:flutter/material.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import 'legal_document_screen.dart';

/// ROSIVA Terms of Service.
///
/// ============================================================
/// EDIT ME: everything below is placeholder text so the screen
/// works out of the box. Replace the strings in each
/// [LegalSection] with your real terms of service whenever you're
/// ready — nothing else in the app needs to change.
/// ============================================================
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;

    return LegalDocumentScreen(
      title: lang.termsOfService,
      lastUpdated: lang.legalLastUpdatedPlaceholder,
      sections: [
        LegalSection(title: lang.tosSection1Title, body: lang.tosSection1Body),
        LegalSection(title: lang.tosSection2Title, body: lang.tosSection2Body),
        LegalSection(title: lang.tosSection3Title, body: lang.tosSection3Body),
        LegalSection(title: lang.tosSection4Title, body: lang.tosSection4Body),
        LegalSection(title: lang.tosSection5Title, body: lang.tosSection5Body),
        LegalSection(title: lang.tosSection6Title, body: lang.tosSection6Body),
      ],
    );
  }
}
