import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shared responsive frame for every auth screen (login, register,
/// forgot-password, verify-email, complete-registration).
///
/// Behaviour:
///  * phone  — a full-width column, exactly like before;
///  * tablet / desktop — the form is capped at [maxWidth] and centred
///    both horizontally and vertically, so it reads as a normal web
///    sign-in card instead of a stretched mobile screen. It still
///    scrolls when the viewport is too short (small laptops, keyboard
///    open) because the whole thing lives in a [SingleChildScrollView]
///    with a `minHeight` equal to the viewport.
///
/// No timers, no `kIsWeb` branching — it's driven purely by the
/// available width via [ConstrainedBox].
class AuthShell extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final double maxWidth;

  const AuthShell({
    super.key,
    required this.child,
    this.appBar,
    this.maxWidth = 420,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 28.h),
                      child: child,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
