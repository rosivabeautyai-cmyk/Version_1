// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:rosivia/core/styles/colors.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

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

  final List<Widget> screens = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],

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
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: (index) {
            setState(() {
              currentIndex = index;
            });
          },
          items: [
            // BottomNavigationBarItem(
            //   icon: SvgPicture.asset(
            //     AppImages.home1,
            //     colorFilter: ColorFilter.mode(
            //       currentIndex == 0 ? AppColors.primary : AppColors.background,
            //       BlendMode.srcIn,
            //     ),
            //   ),
            //   label: "استكشف",
            // ),

            // BottomNavigationBarItem(
            //   icon: SvgPicture.asset(
            //     AppImages.categarios,
            //     colorFilter: ColorFilter.mode(
            //       currentIndex == 1 ? AppColors.primary : AppColors.background,
            //       BlendMode.srcIn,
            //     ),
            //   ),
            //   label: "الأقسام",
            // ),

            // BottomNavigationBarItem(
            //   icon: SvgPicture.asset(
            //     AppImages.fevourite,
            //     colorFilter: ColorFilter.mode(
            //       currentIndex == 2 ? AppColors.primary : AppColors.background,
            //       BlendMode.srcIn,
            //     ),
            //   ),
            //   label: "المفضلة",
            // ),

            // BottomNavigationBarItem(
            //   icon: SvgPicture.asset(
            //     AppImages.profile,
            //     colorFilter: ColorFilter.mode(
            //       currentIndex == 3 ? AppColors.primary : AppColors.background,
            //       BlendMode.srcIn,
            //     ),
            //   ),
            //   label: "حسابي",
            // ),
          ],
        ),
      ),
    );
  }
}
