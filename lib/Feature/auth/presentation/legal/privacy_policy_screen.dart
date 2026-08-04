import 'package:flutter/material.dart';

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
    return const LegalDocumentScreen(
      title: 'سياسة الخصوصية',
      lastUpdated: 'آخر تحديث: أضيفي التاريخ هنا',
      sections: [
        LegalSection(
          title: '١. البيانات التي نجمعها',
          body:
              'نجمع بيانات مثل الاسم، البريد الإلكتروني، وأي معلومات تقومين '
              'بإدخالها داخل التطبيق (مثل نوع البشرة أو المفضلة). عدّلي هذا '
              'النص ليعكس البيانات الفعلية التي يجمعها تطبيقك.',
        ),
        LegalSection(
          title: '٢. كيف نستخدم بياناتك',
          body:
              'نستخدم بياناتك لتقديم خدمات التطبيق، تحسين تجربة الاستخدام، '
              'والتواصل معك عند الحاجة. لا نبيع بياناتك لأي طرف ثالث.',
        ),
        LegalSection(
          title: '٣. مشاركة البيانات',
          body:
              'قد تتم مشاركة بعض البيانات مع مزودي خدمات موثوقين (مثل '
              'Firebase من جوجل) لتشغيل التطبيق فقط، وليس لأي غرض تسويقي.',
        ),
        LegalSection(
          title: '٤. أمان البيانات',
          body:
              'نتخذ إجراءات معقولة لحماية بياناتك، لكن لا يمكن ضمان الأمان '
              'الكامل لأي نظام إلكتروني بنسبة ١٠٠٪.',
        ),
        LegalSection(
          title: '٥. حقوقك',
          body:
              'يمكنك طلب تعديل أو حذف بياناتك في أي وقت عن طريق التواصل معنا '
              'من داخل التطبيق أو عبر البريد الإلكتروني.',
        ),
        LegalSection(
          title: '٦. التواصل معنا',
          body: 'لأي استفسار حول سياسة الخصوصية، راسلينا على: أضيفي بريدك هنا.',
        ),
      ],
    );
  }
}
