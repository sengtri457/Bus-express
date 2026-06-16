import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class AvatarWidget extends StatelessWidget {
  final String initials;
  final double size;
  final String? imageUrl;
  final Color? backgroundColor;

  const AvatarWidget({
    super.key,
    required this.initials,
    this.size = 40,
    this.imageUrl,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(imageUrl!),
        backgroundColor: AppColors.primaryLight,
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: backgroundColor ?? AppColors.primary,
      child: Text(
        initials.length > 2 ? initials.substring(0, 2) : initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
