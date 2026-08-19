import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../auth/data/models/user_model.dart';

class WelcomeCard extends StatelessWidget {
  final UserModel? userData;

  const WelcomeCard({
    super.key,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final name = userData?.fullName.isNotEmpty == true
        ? userData!.fullName
        : 'ROSIVA User';

    final email = userData?.email ?? '';

    final photoUrl = userData?.photoUrl;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Row(
        children: [
          _UserAvatar(
            photoUrl: photoUrl,
            primaryColor: colorScheme.primary,
          ),

          SizedBox(width: 14.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أهلًا، $name',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: 5.h),

                if (email.isNotEmpty)
                  Text(
                    email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final Color primaryColor;

  const _UserAvatar({
    required this.photoUrl,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    return CircleAvatar(
      radius: 28.r,
      backgroundColor: Colors.white,
      backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
      child: hasPhoto
          ? null
          : Icon(
              Icons.person_rounded,
              color: primaryColor,
              size: 28.sp,
            ),
    );
  }
}