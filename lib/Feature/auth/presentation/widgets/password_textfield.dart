import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rosivia/core/styles/colors.dart';

/// A themed password field with a visibility toggle icon.
class PasswordTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final AutovalidateMode autovalidateMode;
  final void Function(String)? onFieldSubmitted;
  final void Function(String)? onChanged;

  const PasswordTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.obscureText,
    required this.onToggleVisibility,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.onFieldSubmitted,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          textInputAction: textInputAction,
          validator: validator,
          autovalidateMode: autovalidateMode,
          onFieldSubmitted: onFieldSubmitted,
          onChanged: onChanged,
          style: TextStyle(
            fontSize: 15.sp,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              size: 22,
              color: AppColors.primary,
            ),
            suffixIcon: IconButton(
              onPressed: onToggleVisibility,
              icon: Icon(
                obscureText
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 22,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
