import 'package:flutter/material.dart';

import '../models/app_usage.dart';
import 'app_theme.dart';

extension AppCategoryVisuals on AppCategory {
  Color get color => switch (this) {
    AppCategory.social => AppColors.rose,
    AppCategory.gaming => AppColors.violet,
    AppCategory.video => AppColors.coral,
    AppCategory.education => AppColors.mint,
    AppCategory.messaging => AppColors.sky,
    AppCategory.creativity => AppColors.lemon,
    AppCategory.utilities => AppColors.muted,
  };

  Color get softColor => color.withValues(alpha: 0.12);

  IconData get icon => switch (this) {
    AppCategory.social => Icons.camera_alt_rounded,
    AppCategory.gaming => Icons.sports_esports_rounded,
    AppCategory.video => Icons.play_circle_rounded,
    AppCategory.education => Icons.school_rounded,
    AppCategory.messaging => Icons.chat_bubble_rounded,
    AppCategory.creativity => Icons.brush_rounded,
    AppCategory.utilities => Icons.widgets_rounded,
  };
}
