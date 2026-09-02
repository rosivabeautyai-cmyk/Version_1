import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:rosivia/core/styles/app_dimens.dart';
import 'package:rosivia/core/styles/colors.dart';
import 'package:rosivia/core/widgets/motion/pressable_scale.dart';
import 'package:rosivia/l10n/app_localizations.dart';

/// ROSIVA's floating glass bottom navigation.
///
/// A detached, fully-rounded bar that hovers above the content with a
/// soft ambient shadow and a frosted-glass fill (BackdropFilter blur
/// tinted with the brand colour). The host [Scaffold] uses
/// `extendBody: true` so the catalog scrolls behind the glass; every
/// scroll view then reserves [bottomInset] of trailing space so no
/// content is ever hidden underneath.
///
/// RTL-safe: the item row flips automatically, margins are symmetric,
/// and there is no directional iconography.
class HomeBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  const HomeBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  /// Logical-pixel height of the floating pill + its top/bottom margin.
  /// Scroll views add [bottomInset] (this, scaled, plus the OS inset).
  static const double reservedSpace = 84;

  /// Trailing space a scroll view should reserve so its last item
  /// clears the floating bar on this device.
  static double bottomInset(BuildContext context) =>
      reservedSpace.h + MediaQuery.viewPaddingOf(context).bottom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    final items = <_NavSpec>[
      _NavSpec(Icons.home_outlined, Icons.home_rounded, lang.home),
      _NavSpec(Icons.explore_outlined, Icons.explore_rounded, lang.explore),
      _NavSpec(Icons.category_outlined, Icons.category_rounded, lang.categories),
      _NavSpec(
        Icons.favorite_border_rounded,
        Icons.favorite_rounded,
        lang.favorites,
      ),
      _NavSpec(
        Icons.person_outline_rounded,
        Icons.person_rounded,
        lang.profile,
      ),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl.r + 4),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: isDark ? 0.28 : 0.16),
                blurRadius: 28,
                spreadRadius: -6,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl.r + 4),
            child: BackdropFilter(
              // A stronger blur lets the fill stay thinner, so the brand
              // colour of the content behind the glass keeps reading.
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Container(
                decoration: BoxDecoration(
                  // Thin translucent surface — just enough to keep the
                  // nav icons/labels legible over scrolling content,
                  // without desaturating the page.
                  color: (isDark ? AppColors.cardDark : Colors.white)
                      .withValues(alpha: isDark ? 0.52 : 0.58),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xl.r + 4),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    // A touch more brand tint so the glass itself carries
                    // the rose, rather than reading as flat white.
                    color: AppColors.primary
                        .withValues(alpha: isDark ? 0.12 : 0.09),
                    borderRadius: BorderRadius.circular(AppRadius.xl.r + 4),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 8.h,
                    ),
                    child: Row(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          Expanded(
                            child: _NavItem(
                              spec: items[i],
                              selected: i == currentIndex,
                              onTap: () => onItemSelected(i),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavSpec {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavSpec(this.icon, this.activeIcon, this.label);
}

class _NavItem extends StatelessWidget {
  final _NavSpec spec;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = AppColors.primary;
    final muted = theme.colorScheme.onSurfaceVariant;
    final color = selected ? active : muted;

    return PressableScale(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: AppDuration.short,
              curve: AppCurve.standard,
              padding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 5.h,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? active.withValues(alpha: 0.14)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Icon(
                selected ? spec.activeIcon : spec.icon,
                size: 22.sp,
                color: color,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              spec.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10.5.sp,
                height: 1,
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
