import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rosivia/l10n/app_localizations.dart';

/// Standalone FAQ page listing common questions about the account,
/// products, orders, favorites, the AI assistant, language, and
/// privacy — each answer expands in place.
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;

    final faqs = <(String, String)>[
      (lang.helpCenterAccountQuestion, lang.helpCenterAccountAnswer),
      (lang.helpCenterProductsQuestion, lang.helpCenterProductsAnswer),
      (lang.helpCenterOrdersQuestion, lang.helpCenterOrdersAnswer),
      (lang.helpCenterFavoritesQuestion, lang.helpCenterFavoritesAnswer),
      (lang.helpCenterAiQuestion, lang.helpCenterAiAnswer),
      (lang.helpCenterLanguageQuestion, lang.helpCenterLanguageAnswer),
      (lang.helpCenterPrivacyQuestion, lang.helpCenterPrivacyAnswer),
      (lang.helpCenterContactQuestion, lang.helpCenterContactAnswer),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(lang.helpCenter, style: theme.textTheme.titleMedium)),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(20.w),
          children: [
            Text(
              lang.helpCenterSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
            SizedBox(height: 20.h),
            Container(
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
                  for (int i = 0; i < faqs.length; i++) ...[
                    Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.symmetric(horizontal: 16.w),
                        childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                        expandedAlignment: AlignmentDirectional.centerStart,
                        title: Text(
                          faqs[i].$1,
                          style: theme.textTheme.titleSmall,
                        ),
                        children: [
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              faqs[i].$2,
                              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i != faqs.length - 1)
                      Divider(
                        height: 1,
                        indent: 16.w,
                        endIndent: 16.w,
                        color: theme.colorScheme.outline.withValues(alpha: 0.1),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
