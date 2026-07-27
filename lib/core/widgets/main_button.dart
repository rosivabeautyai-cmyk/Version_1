import 'package:flutter/material.dart';
import 'package:rosivia/core/styles/colors.dart';
import 'package:rosivia/core/styles/text_style.dart';

class MainButton extends StatelessWidget {
  const MainButton({
    super.key,
    required this.text,
    required this.onpress,
    this.color,
    this.backgroundColor,
  });

  final String text;
  final Function() onpress;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            backgroundColor ?? AppColors.primary, // 👈 default color
        minimumSize: const Size(double.infinity, 70),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: onpress,
      child: Text(
        text,
        style: TextStyles.body.copyWith(
          color: color ?? Colors.white, // 👈 default text color
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
