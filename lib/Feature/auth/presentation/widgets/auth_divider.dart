import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rosivia/l10n/app_localizations.dart';

/// A labeled divider used to separate email auth from social auth,
/// e.g. "or continue with".
class AuthDivider extends StatelessWidget {
  final String? label;

  const AuthDivider({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    final lineColor = Theme.of(context).colorScheme.outlineVariant;
    final lang = AppLocalizations.of(context)!;
    final resolvedLabel = label ?? lang.orContinueWith;

    return Row(
      children: [
        Expanded(child: Divider(color: lineColor, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text(
            resolvedLabel,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Expanded(child: Divider(color: lineColor, thickness: 1)),
      ],
    );
  }
}
