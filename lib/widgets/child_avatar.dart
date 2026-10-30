import 'package:flutter/material.dart';

import '../models/child.dart';
import '../theme/app_theme.dart';

class ChildAvatar extends StatelessWidget {
  const ChildAvatar({
    super.key,
    required this.child,
    this.size = 54,
    this.showDeviceBadge = true,
    this.heroTag,
  });

  final Child child;
  final double size;
  final bool showDeviceBadge;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final avatar = SizedBox(
      width: size + (showDeviceBadge ? size * 0.08 : 0),
      height: size + (showDeviceBadge ? size * 0.08 : 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  child.accent,
                  Color.lerp(child.accent, Colors.white, 0.34)!,
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.75),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: child.accent.withValues(alpha: 0.24),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              child.initials,
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                color: Colors.white,
                fontSize: size * 0.35,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (showDeviceBadge)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.32,
                height: size * 0.32,
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cream, width: 1.5),
                  boxShadow: AppShadows.soft,
                ),
                alignment: Alignment.center,
                child: Icon(
                  child.platform == DevicePlatform.ios
                      ? Icons.apple_rounded
                      : Icons.android_rounded,
                  size: size * 0.19,
                  color: AppColors.ink,
                ),
              ),
            ),
        ],
      ),
    );

    if (heroTag == null) return avatar;
    return Hero(tag: heroTag!, child: avatar);
  }
}
