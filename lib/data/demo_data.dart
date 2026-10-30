import 'package:flutter/material.dart';

import '../models/app_usage.dart';
import '../models/child.dart';
import '../theme/app_theme.dart';
import '../utils/clock.dart';
import '../utils/dates.dart';

part 'demo_seeds/builder.dart';
part 'demo_seeds/leo.dart';
part 'demo_seeds/ada.dart';
part 'demo_seeds/mert.dart';
part 'demo_seeds/zeynep.dart';

class DemoFamily {
  DemoFamily({
    required this.parentName,
    required this.parentEmail,
    required this.familyName,
    required List<Child> children,
  }) : children = List.unmodifiable(children);

  final String parentName;
  final String parentEmail;
  final String familyName;
  final List<Child> children;

  DemoFamily copyWith({
    String? parentName,
    String? parentEmail,
    String? familyName,
    List<Child>? children,
  }) => DemoFamily(
    parentName: parentName ?? this.parentName,
    parentEmail: parentEmail ?? this.parentEmail,
    familyName: familyName ?? this.familyName,
    children: children ?? this.children,
  );
}

/// A deterministic local data set for the demo. No network, no persistence.
///
/// Fourteen days of activity are generated for each child, including per-app
/// minutes and hourly distribution, so all views agree with each other.
abstract final class DemoData {
  static DemoFamily build() {
    final now = AppClock.now();
    final today = DateTime(now.year, now.month, now.day);

    return DemoFamily(
      parentName: 'Elif',
      parentEmail: 'parent@parentify.dev',
      familyName: 'Yilmaz family',
      children: [_adaSeed(today), _mertSeed(today), _zeynepSeed(today)],
    );
  }

  static DemoFamily buildSingleChild() {
    final now = AppClock.now();
    final today = DateTime(now.year, now.month, now.day);

    return DemoFamily(
      parentName: 'Sarah',
      parentEmail: 'parent@parentify.dev',
      familyName: 'Miller Family',
      children: [_leoSeed(today)],
    );
  }

  static Child buildAdaChild() {
    final now = AppClock.now();
    final today = DateTime(now.year, now.month, now.day);
    return _adaSeed(today);
  }
}

class _AppSeed {
  const _AppSeed({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.color,
    required this.share,
    required this.launches,
  });

  final String id;
  final String name;
  final AppCategory category;
  final IconData icon;
  final Color color;
  final double share;
  final int launches;
}

class _SessionSeed {
  const _SessionSeed({
    required this.daysAgo,
    required this.hour,
    required this.minute,
    required this.minutes,
    required this.label,
    required this.category,
    required this.apps,
  });

  final int daysAgo;
  final int hour;
  final int minute;
  final int minutes;
  final String label;
  final AppCategory category;
  final List<String> apps;
}
