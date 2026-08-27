import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:rosivia/l10n/app_localizations.dart';

import '../../../auth/data/models/user_model.dart';

/// A single row for a real Firestore `UserModel` — avatar/initial,
/// name, email, verification status, and join date (only fields that
/// actually exist on the model; nothing invented).
class AdminUserListItem extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;

  const AdminUserListItem({super.key, required this.user, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lang = AppLocalizations.of(context)!;

    final hasPhoto = user.photoUrl != null && user.photoUrl!.isNotEmpty;
    final initial = user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?';

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                backgroundImage: hasPhoto ? NetworkImage(user.photoUrl!) : null,
                child: hasPhoto
                    ? null
                    : Text(
                        initial,
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName.isNotEmpty ? user.fullName : lang.adminFallbackName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (_countryAndLanguage(user).isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        _countryAndLanguage(user),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _VerificationBadge(isVerified: user.isEmailVerified, lang: lang),
                  if (user.createdAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      DateFormat.yMMMd(lang.localeName).format(user.createdAt!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Only real, present fields — never invents a country/language for
  /// accounts that never set one.
  String _countryAndLanguage(UserModel user) {
    return [
      if (user.country != null && user.country!.isNotEmpty) user.country,
      if (user.language != null && user.language!.isNotEmpty) user.language!.toUpperCase(),
    ].whereType<String>().join(' • ');
  }
}

class _VerificationBadge extends StatelessWidget {
  final bool isVerified;
  final AppLocalizations lang;

  const _VerificationBadge({required this.isVerified, required this.lang});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = isVerified ? colorScheme.tertiary : colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isVerified ? lang.adminStatusVerified : lang.adminStatusUnverified,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
