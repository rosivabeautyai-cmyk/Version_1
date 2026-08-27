import 'package:flutter/material.dart';
import 'package:rosivia/core/styles/colors.dart';
import 'package:rosivia/core/styles/text_style.dart';

class CustomTextFormField extends StatelessWidget {
  const CustomTextFormField({
    super.key,
    this.hintText,
    this.keyboardType,
    this.validator,
    this.prefixIcon,
    this.readOnly = false,
    this.onTap,
    this.focusNode,
    this.onChange,
    this.textInputAction = TextInputAction.next,
    this.controller,
  });

  final String? hintText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final bool readOnly;
  final Function()? onTap;
  final Function(String)? onChange;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      keyboardType: keyboardType,
      readOnly: readOnly,
      focusNode: focusNode,
      textInputAction: textInputAction,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      controller: controller,

      onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),

      onChanged: onChange,
      onTap: onTap,
      validator: validator,

      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon,

        hintStyle: TextStyles.caption1.copyWith(color: theme.colorScheme.onSurfaceVariant),

        fillColor: theme.cardColor,
        filled: true,

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.errorcolor),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.errorcolor),
        ),
      ),
    );
  }
}
