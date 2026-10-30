import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Soft colour washes used behind the login experience.
class AmbientBackdrop extends StatelessWidget {
  const AmbientBackdrop({super.key, this.child, this.showOrbs = true});

  final Widget? child;
  final bool showOrbs;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(gradient: AppGradients.loginBackdrop),
        ),
        if (showOrbs) ...[
          Positioned(
            top: -130,
            right: -90,
            child: _Orb(
              size: 300,
              colors: [
                AppColors.violet.withValues(alpha: 0.20),
                AppColors.violet.withValues(alpha: 0.0),
              ],
            ),
          ),
          Positioned(
            top: 180,
            left: -120,
            child: _Orb(
              size: 280,
              colors: [
                AppColors.mint.withValues(alpha: 0.18),
                AppColors.mint.withValues(alpha: 0.0),
              ],
            ),
          ),
          Positioned(
            bottom: -140,
            right: -70,
            child: _Orb(
              size: 320,
              colors: [
                AppColors.lemon.withValues(alpha: 0.24),
                AppColors.lemon.withValues(alpha: 0.0),
              ],
            ),
          ),
        ],
        ?child,
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}
