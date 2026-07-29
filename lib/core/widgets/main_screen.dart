import 'package:flutter/material.dart';
import 'package:rosivia/core/styles/colors.dart';

/// A reusable bottom-navigation shell.
///
/// Pass the screens and the matching [BottomNavigationBarItem]s you
/// want to display; [MainScreen] takes care of the tab switching and
/// consistent styling. This keeps the shell fully generic so any
/// feature can plug its own tabs in once those screens exist.
class MainScreen extends StatefulWidget {
  final List<Widget> screens;
  final List<BottomNavigationBarItem> items;
  final int initialIndex;

  const MainScreen({
    super.key,
    required this.screens,
    required this.items,
    this.initialIndex = 0,
  }) : assert(screens.length == items.length,
            'screens and items must have the same length');

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: widget.screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 15,
              spreadRadius: 2,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          currentIndex: currentIndex,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.graycolor,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: (index) => setState(() => currentIndex = index),
          items: widget.items,
        ),
      ),
    );
  }
}
