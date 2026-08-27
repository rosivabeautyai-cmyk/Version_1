import 'package:flutter/material.dart';
import 'package:rosivia/core/styles/colors.dart';
import 'package:rosivia/core/styles/text_style.dart';

class PasswordTextFormField extends StatefulWidget {
  const PasswordTextFormField({
    super.key,
    this.validator,
    required this.hint,
    this.passwordController,
    required this.keyboardType,
  });

  final String? Function(String?)? validator;
  final String hint;
  final TextEditingController? passwordController;
  final TextInputType keyboardType;

  @override
  State<PasswordTextFormField> createState() => _PasswordTextFormFieldState();
}

class _PasswordTextFormFieldState extends State<PasswordTextFormField> {
  bool isHide = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: widget.passwordController,
      obscureText: isHide,
      keyboardType: widget.keyboardType,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onTapOutside: (event) {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: TextStyles.caption1.copyWith(color: theme.colorScheme.onSurfaceVariant),
        fillColor: theme.cardColor,
        filled: true,

        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              isHide = !isHide;
            });
          },
          icon: Icon(isHide ? Icons.visibility_off : Icons.remove_red_eye),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
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

      validator: widget.validator,
    );
  }
}
