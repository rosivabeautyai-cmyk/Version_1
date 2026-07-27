import 'package:flutter/material.dart';
import 'package:rosivia/core/styles/text_style.dart';

class SecondButton extends StatelessWidget {
  const SecondButton({
    super.key,
    required this.text,
    required this.onpress,
    this.color,
    this.backgroundColor,
    this.icon,
  });

  final String text;
  final Function() onpress;
  final Color? color;
  final Color? backgroundColor;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        minimumSize: const Size(double.infinity, 70),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: onpress,
      child: icon == null
          ? Text(
              text,
              style: TextStyles.body.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon!,
                const SizedBox(width: 10),
                Text(
                  text,
                  style: TextStyles.body.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
    );
  }
}
