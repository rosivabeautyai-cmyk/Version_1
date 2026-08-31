import 'package:flutter/material.dart';

import 'package:rosivia/core/constants/app_fonts.dart';
import 'package:rosivia/core/responsive/responsive.dart';
import 'package:rosivia/l10n/app_localizations.dart';

/// Desktop / large-tablet primary navigation for the shopper shell.
///
/// Same five destinations as [HomeBottomNavBar] (Home, Explore,
/// Categories, Favorites, Profile) — this is a `NavigationRail` so the
/// web layout gets a real side navigation instead of a bottom bar
/// stretched across a 1400px window. It becomes an *extended* rail
/// (icon + label) on wide desktops and a compact icon rail between the
/// side-nav breakpoint and there.
class HomeSideNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  const HomeSideNav({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lang = AppLocalizations.of(context)!;
    final extended = context.screenWidth >= Breakpoints.largeDesktop;

    return SizedBox(
      width: extended ? 232 : 88,
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: BorderDirectional(
            end: BorderSide(color: colorScheme.outline.withValues(alpha: 0.12)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(extended ? 24 : 8, 28, 8, 20),
              child: Text(
                extended ? lang.appName : 'R',
                textAlign: extended ? TextAlign.start : TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.playfairDisplaySC,
                  fontSize: extended ? 24 : 20,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Expanded(
              child: NavigationRail(
                extended: extended,
                backgroundColor: theme.scaffoldBackgroundColor,
                selectedIndex: currentIndex,
                onDestinationSelected: onItemSelected,
                labelType: extended
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.all,
                indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
                minWidth: 72,
                minExtendedWidth: 232,
                groupAlignment: -0.9,
                destinations: [
                  NavigationRailDestination(
                    icon: const Icon(Icons.home_outlined),
                    selectedIcon: const Icon(Icons.home_rounded),
                    label: Text(lang.home),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.explore_outlined),
                    selectedIcon: const Icon(Icons.explore_rounded),
                    label: Text(lang.explore),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.category_outlined),
                    selectedIcon: const Icon(Icons.category_rounded),
                    label: Text(lang.categories),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.favorite_border_rounded),
                    selectedIcon: const Icon(Icons.favorite_rounded),
                    label: Text(lang.favorites),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.person_outline_rounded),
                    selectedIcon: const Icon(Icons.person_rounded),
                    label: Text(lang.profile),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
