import 'package:flutter/material.dart';

import '../../models/child.dart';
import '../../theme/app_theme.dart';

/// How far today has moved from yesterday, using the one shared threshold.
enum DayShift { flagged, quieter, steady }

DayShift dayShiftFor(Child child) {
  final ratio = child.dayOverDay.ratio;
  if (ratio > 0.05) return DayShift.flagged;
  if (ratio < -0.05) return DayShift.quieter;
  return DayShift.steady;
}

Color dayShiftTint(DayShift shift) =>
    shift == DayShift.flagged ? AppColors.warning : AppColors.good;
