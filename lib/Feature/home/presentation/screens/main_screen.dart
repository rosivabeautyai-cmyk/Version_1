import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:rosivia/Feature/products/presentation/screens/categories_screen.dart';
import 'package:rosivia/core/responsive/responsive.dart';
import 'package:rosivia/core/services/notification_service.dart';

import '../widgets/home_bottom_nav_bar.dart';
import '../widgets/home_side_nav.dart';
import 'explore_screen.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // If push was enabled before, make sure this account has an
    // up-to-date token for this device. Never prompts; never blocks.
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      NotificationService.instance.syncOnLogin(uid);
    }
  }

  late final List<Widget> _screens = [
    const HomeScreen(),
    const ExploreScreen(),
    const CategoriesScreen(),
    const FavoritesScreen(),
    ProfileScreen(onShowFavorites: () => _onItemTapped(3)),
  ];

  void _onItemTapped(int index) {
    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final body = IndexedStack(index: _currentIndex, children: _screens);

    // Wide viewports (desktop web / large tablet) get a real side
    // navigation rail; phones and narrow tablets keep the bottom bar.
    if (context.useSideNav) {
      return Scaffold(
        body: Row(
          children: [
            HomeSideNav(
              currentIndex: _currentIndex,
              onItemSelected: _onItemTapped,
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: HomeBottomNavBar(
        currentIndex: _currentIndex,
        onItemSelected: _onItemTapped,
      ),
    );
  }
}
