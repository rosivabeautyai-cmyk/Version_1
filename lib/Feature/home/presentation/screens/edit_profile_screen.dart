import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:rosivia/core/functions/navigations.dart';
import 'package:rosivia/core/services/snackbar_service.dart';
import 'package:rosivia/core/widgets/state_views.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import '../../../auth/presentation/widgets/auth_textfield.dart';
import '../../../auth/presentation/widgets/loading_button.dart';
import '../../../auth/provider/auth_provider.dart';

/// Lets the user update their display name on the Firestore profile.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  bool _loading = true;
  bool _saving = false;

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
      _nameController.text = data?.fullName ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final lang = AppLocalizations.of(context)!;

    await context.read<AuthProvider>().updateProfile(
          fullName: _nameController.text.trim(),
        );

    if (!mounted) return;

    setState(() => _saving = false);

    SnackbarService.success(context, lang.profileUpdated);
    pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(lang.editProfile, style: theme.textTheme.titleMedium)),
      body: SafeArea(
        child: _loading
            ? const AppLoadingView()
            : ListView(
                padding: EdgeInsets.all(20.w),
                children: [
                  Text(
                    lang.editProfileScreenSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                  SizedBox(height: 24.h),
                  Form(
                    key: _formKey,
                    child: AuthTextField(
                      controller: _nameController,
                      label: lang.fullName,
                      hint: lang.fullNameHint,
                      prefixIcon: Icons.person_outline_rounded,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return lang.fullNameRequired;
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: 32.h),
                  LoadingButton(
                    label: lang.save,
                    isLoading: _saving,
                    onPressed: _save,
                  ),
                ],
              ),
      ),
    );
  }
}
