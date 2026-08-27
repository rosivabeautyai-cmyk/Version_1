import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:rosivia/core/functions/navigations.dart';
import 'package:rosivia/core/services/snackbar_service.dart';
import 'package:rosivia/core/widgets/main_button.dart';
import 'package:rosivia/core/widgets/state_views.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import '../../../auth/provider/auth_provider.dart';

/// Lets the user pick their skin type, stored on their Firestore
/// profile so ROSIVA can tailor product recommendations.
class MyBeautyProfileScreen extends StatefulWidget {
  const MyBeautyProfileScreen({super.key});

  @override
  State<MyBeautyProfileScreen> createState() => _MyBeautyProfileScreenState();
}

class _MyBeautyProfileScreenState extends State<MyBeautyProfileScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _selectedSkinType;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUser();
    });
  }

  Future<void> _loadUser() async {
    final auth = context.read<AuthProvider>();

    final data = await auth.fetchUserData();

    if (!mounted) return;

    setState(() {
      _selectedSkinType = data?.skinType;
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final lang = AppLocalizations.of(context)!;

    await context.read<AuthProvider>().updateProfile(
          skinType: _selectedSkinType,
        );

    if (!mounted) return;

    setState(() => _saving = false);

    SnackbarService.success(context, lang.profileUpdated);
    pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;

    final options = <(String, String)>[
      ('normal', lang.skinTypeNormal),
      ('dry', lang.skinTypeDry),
      ('oily', lang.skinTypeOily),
      ('combination', lang.skinTypeCombination),
      ('sensitive', lang.skinTypeSensitive),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(lang.myBeautyProfile, style: theme.textTheme.titleMedium)),
      body: SafeArea(
        child: _loading
            ? const AppLoadingView()
            : ListView(
                padding: EdgeInsets.all(20.w),
                children: [
                  Text(
                    lang.myBeautyProfileScreenSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    lang.skinType,
                    style: theme.textTheme.titleSmall,
                  ),
                  SizedBox(height: 12.h),
                  Wrap(
                    spacing: 10.w,
                    runSpacing: 10.h,
                    children: [
                      for (final option in options)
                        ChoiceChip(
                          label: Text(option.$2),
                          selected: _selectedSkinType == option.$1,
                          onSelected: (selected) {
                            setState(() {
                              _selectedSkinType = selected ? option.$1 : null;
                            });
                          },
                        ),
                    ],
                  ),
                  SizedBox(height: 32.h),
                  MainButton(text: lang.save, onpress: _save),
                ],
              ),
      ),
    );
  }
}
