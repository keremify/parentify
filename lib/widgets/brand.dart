import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The compact Parentify mark: a soft "p" with a lemon period.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppGradients.inkCard,
        borderRadius: BorderRadius.circular(size * 0.30),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.18),
            blurRadius: size * 0.45,
            offset: Offset(0, size * 0.16),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Center(
              child: Text(
                'p',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: size * 0.64,
                  height: 0.94,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1.5,
                ),
              ),
            ),
          ),
          Positioned(
            right: size * 0.19,
            top: size * 0.18,
            child: Container(
              width: size * 0.15,
              height: size * 0.15,
              decoration: const BoxDecoration(
                color: AppColors.lemon,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.markSize = 38, this.textColor});

  final double markSize;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: markSize),
        const SizedBox(width: 11),
        Text(
          'parentify',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: markSize * 0.55,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.9,
            color: textColor ?? AppColors.ink,
          ),
        ),
      ],
    );
  }
}
