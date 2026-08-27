import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rosivia/l10n/app_localizations.dart';

import '../widgets/admin_platform_card.dart';
import '../widgets/admin_time_format.dart';

/// The "Affiliate Platforms" tab. Awin is the only real, implemented
/// integration — its card is built entirely from real Firestore data
/// (`admin/awinSyncStatus` + a real `products` count). Other
/// platforms are shown only as an honest "coming soon" placeholder,
/// never as a fabricated Amazon/Sephora/Dior-style integration.
class AdminPlatformsScreen extends StatelessWidget {
  const AdminPlatformsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.adminPlatformsScreenTitle,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              lang.adminPlatformsScreenSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.doc('admin/awinSyncStatus').snapshots(),
              builder: (context, statusSnapshot) {
                return FutureBuilder<AggregateQuerySnapshot>(
                  future: FirebaseFirestore.instance.collection('products').count().get(),
                  builder: (context, countSnapshot) {
                    final statusData = statusSnapshot.data?.data();
                    final status = statusData?['status'] as String?;
                    final finishedAt = parseIsoTimestamp(statusData?['finishedAt']);
                    final productsCount = countSnapshot.data?.count ?? 0;

                    return AdminAwinPlatformCard(
                      isConnected: status != null,
                      isCatalogActive: productsCount > 0,
                      lastSyncText: finishedAt != null
                          ? formatRelativeTime(lang, finishedAt)
                          : lang.adminSyncNever,
                      productsCount: productsCount,
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            const AdminComingSoonPlatformCard(),
            const SizedBox(height: 8),
            const AdminComingSoonPlatformCard(),
          ],
        ),
      ),
    );
  }
}
