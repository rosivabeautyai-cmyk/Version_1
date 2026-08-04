import 'package:flutter/material.dart';

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
    return const LegalDocumentScreen(
      title: 'شروط الاستخدام',
      lastUpdated: 'آخر تحديث: أضيفي التاريخ هنا',
      sections: [
        LegalSection(
          title: '١. الموافقة على الشروط',
          body:
              'باستخدامك لتطبيق ROSIVA فإنك توافقين على هذه الشروط. إذا كنتِ '
              'لا توافقين عليها، يرجى عدم استخدام التطبيق.',
        ),
        LegalSection(
          title: '٢. استخدام التطبيق',
          body:
              'يجب استخدام التطبيق للأغراض الشخصية المشروعة فقط، وعدم محاولة '
              'إساءة استخدامه أو الوصول غير المصرح به إلى حسابات أخرى.',
        ),
        LegalSection(
          title: '٣. الحساب والمسؤولية',
          body:
              'أنتِ مسؤولة عن الحفاظ على سرية بيانات حسابك، وعن أي نشاط يتم '
              'من خلاله.',
        ),
        LegalSection(
          title: '٤. التعديلات على الخدمة',
          body:
              'نحتفظ بحق تعديل أو إيقاف أي جزء من التطبيق في أي وقت دون '
              'إشعار مسبق.',
        ),
        LegalSection(
          title: '٥. إنهاء الحساب',
          body:
              'يحق لنا تعليق أو إنهاء أي حساب يخالف هذه الشروط أو يُستخدم '
              'بشكل غير قانوني.',
        ),
        LegalSection(
          title: '٦. التواصل معنا',
          body: 'لأي استفسار حول شروط الاستخدام، راسلينا على: أضيفي بريدك هنا.',
        ),
      ],
    );
  }
}
