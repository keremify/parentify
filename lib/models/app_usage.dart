import 'package:flutter/material.dart';

/// How an app is grouped in the parent-facing insights.
///
/// The visible label lives in `AppStrings`, so this enum stays language-neutral.
enum AppCategory {
  social,
  gaming,
  video,
  education,
  messaging,
  creativity,
  utilities,
}

/// A single app on a child's device.
///
/// The demo keeps seven days of daily minutes so every chart in the app can be
/// derived from the same source of truth.
class UsageApp {
  UsageApp({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.color,
    required List<int> last7Days,
    required this.launchesToday,
  }) : last7Days = List.unmodifiable(last7Days);

  final String id;
  final String name;
  final AppCategory category;
  final IconData icon;
  final Color color;

  /// Oldest first, today last. Always seven entries in the demo.
  final List<int> last7Days;
  final int launchesToday;

  int get todayMinutes => last7Days.isEmpty ? 0 : last7Days.last;

  int get yesterdayMinutes =>
      last7Days.length < 2 ? 0 : last7Days[last7Days.length - 2];

  int get weekMinutes => last7Days.fold(0, (total, minutes) => total + minutes);

  int get dailyAverage =>
      last7Days.isEmpty ? 0 : (weekMinutes / last7Days.length).round();

  int get peakDayMinutes =>
      last7Days.fold(0, (max, minutes) => minutes > max ? minutes : max);

  UsageApp copyWith({
    String? id,
    String? name,
    AppCategory? category,
    IconData? icon,
    Color? color,
    List<int>? last7Days,
    int? launchesToday,
  }) => UsageApp(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    last7Days: last7Days ?? this.last7Days,
    launchesToday: launchesToday ?? this.launchesToday,
  );

  factory UsageApp.fromJson(Map<String, dynamic> json) => UsageApp(
    id: json['id'] as String,
    name: json['name'] as String,
    category: AppCategory.values.firstWhere(
      (c) => c.name == json['category'],
      orElse: () => AppCategory.utilities,
    ),
    icon: Icons.apps_rounded,
    color: Color(json['color'] as int? ?? 0xFF6C5CE7),
    last7Days: (json['last7Days'] as List<dynamic>?)?.cast<int>() ?? const [],
    launchesToday: json['launchesToday'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category.name,
    'color': color.toARGB32(),
    'last7Days': last7Days,
    'launchesToday': launchesToday,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UsageApp && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
