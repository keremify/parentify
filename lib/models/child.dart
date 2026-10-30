import 'dart:ui' show Color;

import 'app_usage.dart';

/// The device family shown in the demo. Labels live in `AppStrings`.
enum DevicePlatform { ios, android }

class DailyUsage {
  const DailyUsage({
    required this.date,
    required this.minutes,
    required this.unlocks,
  });

  factory DailyUsage.fromJson(Map<String, dynamic> json) => DailyUsage(
    date: DateTime.parse(json['date'] as String),
    minutes: json['minutes'] as int,
    unlocks: json['unlocks'] as int? ?? 0,
  );

  final DateTime date;
  final int minutes;
  final int unlocks;

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'minutes': minutes,
    'unlocks': unlocks,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyUsage &&
          other.date == date &&
          other.minutes == minutes &&
          other.unlocks == unlocks;

  @override
  int get hashCode => Object.hash(date, minutes, unlocks);
}

/// A continuous stretch of device use. Used for the "longest stretches" view.
class UsageSession {
  const UsageSession({
    required this.id,
    required this.start,
    required this.minutes,
    required this.label,
    required this.category,
    required this.apps,
  });

  factory UsageSession.fromJson(Map<String, dynamic> json) => UsageSession(
    id: json['id'] as String,
    start: DateTime.parse(json['start'] as String),
    minutes: json['minutes'] as int,
    label: json['label'] as String,
    category: AppCategory.values.firstWhere(
      (c) => c.name == json['category'],
      orElse: () => AppCategory.utilities,
    ),
    apps: (json['apps'] as List<dynamic>?)?.cast<String>() ?? const [],
  );

  final String id;
  final DateTime start;
  final int minutes;
  final String label;
  final AppCategory category;
  final List<String> apps;

  DateTime get end => start.add(Duration(minutes: minutes));

  Map<String, dynamic> toJson() => {
    'id': id,
    'start': start.toIso8601String(),
    'minutes': minutes,
    'label': label,
    'category': category.name,
    'apps': apps,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UsageSession && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class UsageComparison {
  const UsageComparison({required this.current, required this.previous});

  final int current;
  final int previous;

  int get difference => current - previous;

  bool get hasPrevious => previous > 0;

  /// A signed ratio, e.g. 0.24 for +24%.
  double get ratio {
    if (previous == 0) return current == 0 ? 0 : 1;
    return (current - previous) / previous;
  }

  bool get isHigher => difference > 0;

  bool get isFlat => difference.abs() < 1;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsageComparison &&
          other.current == current &&
          other.previous == previous;

  @override
  int get hashCode => Object.hash(current, previous);
}

/// Everything the demo knows about one child.
///
/// Inputs are copied into unmodifiable lists, and the derived values a view
/// needs repeatedly (sorted apps, weekly totals, peak window, ranked sessions)
/// are computed once on first access instead of on every rebuild.
class Child {
  Child({
    required this.id,
    required this.name,
    required this.age,
    required this.deviceName,
    required this.platform,
    required this.accent,
    required List<UsageApp> apps,
    required List<DailyUsage> days,
    required List<int> hourlyToday,
    required List<UsageSession> sessions,
    required this.unlocksToday,
    required this.notificationsToday,
    required this.lastSyncedAt,
  }) : apps = List.unmodifiable(apps),
       days = List.unmodifiable(days),
       hourlyToday = List.unmodifiable(hourlyToday),
       sessions = List.unmodifiable(sessions);

  final String id;
  final String name;
  final int age;
  final String deviceName;
  final DevicePlatform platform;
  final Color accent;
  final List<UsageApp> apps;

  /// The last fourteen days, oldest first, ending with today.
  final List<DailyUsage> days;

  /// Minutes per hour for today, 24 entries.
  final List<int> hourlyToday;
  final List<UsageSession> sessions;
  final int unlocksToday;
  final int notificationsToday;
  final DateTime lastSyncedAt;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  late final DailyUsage? today = days.isEmpty ? null : days.last;

  late final int todayMinutes = today?.minutes ?? 0;

  late final DailyUsage? yesterday = days.length < 2
      ? null
      : days[days.length - 2];

  late final int yesterdayMinutes = yesterday?.minutes ?? 0;

  late final List<DailyUsage> last7Days = days.length <= 7
      ? List.unmodifiable(days)
      : List.unmodifiable(days.sublist(days.length - 7));

  /// The seven days before [last7Days]. Empty until there is more than one
  /// week of history.
  late final List<DailyUsage> previous7Days = days.length <= 7
      ? const []
      : List.unmodifiable(days.sublist(0, days.length - 7));

  late final List<DailyUsage> last14Days = days.length <= 14
      ? List.unmodifiable(days)
      : List.unmodifiable(days.sublist(days.length - 14));

  late final int weekMinutes = last7Days.fold(
    0,
    (total, day) => total + day.minutes,
  );

  late final int previousWeekMinutes = previous7Days.fold(
    0,
    (total, day) => total + day.minutes,
  );

  late final int weeklyAverage = last7Days.isEmpty
      ? 0
      : (weekMinutes / last7Days.length).round();

  late final int maxDailyMinutes = days.fold(
    0,
    (max, day) => day.minutes > max ? day.minutes : max,
  );

  UsageComparison get dayOverDay =>
      UsageComparison(current: todayMinutes, previous: yesterdayMinutes);

  UsageComparison get weekOverWeek =>
      UsageComparison(current: weekMinutes, previous: previousWeekMinutes);

  late final List<UsageApp> appsByUsage = _sortedApps();

  late final UsageApp? topApp = appsByUsage.isEmpty ? null : appsByUsage.first;

  late final Map<AppCategory, int> weeklyCategoryMinutes =
      _computeWeeklyCategoryMinutes();

  late final List<MapEntry<AppCategory, int>> weeklyCategories =
      List.unmodifiable(weeklyCategoryMinutes.entries);

  late final int weekAppMinutes = apps.fold(
    0,
    (total, app) => total + app.weekMinutes,
  );

  late final int peakHour = _computePeakHour();

  /// Start of the busiest three-hour window today.
  late final int peakWindowStart = _computePeakWindowStart();

  late final int eveningMinutes = _sumHours(const [18, 19, 20, 21]);

  late final int lateNightMinutes = _sumHours(const [22, 23, 0, 1]);

  late final List<UsageSession> longestSessions = _sortSessions();

  late final UsageSession? longestSession = sessions.isEmpty
      ? null
      : longestSessions.first;

  late final int maxSessionMinutes = sessions.isEmpty
      ? 0
      : longestSessions.first.minutes;

  /// How much of the week's screen time happened today.
  double get shareOfWeekTotal {
    if (weekMinutes == 0) return 0;
    return todayMinutes / weekMinutes;
  }

  List<UsageApp> _sortedApps() {
    final sorted = [...apps]
      ..sort((a, b) => b.weekMinutes.compareTo(a.weekMinutes));
    return List.unmodifiable(sorted);
  }

  Map<AppCategory, int> _computeWeeklyCategoryMinutes() {
    final totals = <AppCategory, int>{};
    for (final app in apps) {
      totals.update(
        app.category,
        (value) => value + app.weekMinutes,
        ifAbsent: () => app.weekMinutes,
      );
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.unmodifiable({
      for (final entry in sorted) entry.key: entry.value,
    });
  }

  int _computePeakHour() {
    if (hourlyToday.isEmpty) return 0;
    var best = 0;
    for (var hour = 1; hour < hourlyToday.length; hour++) {
      if (hourlyToday[hour] > hourlyToday[best]) best = hour;
    }
    return best;
  }

  int _computePeakWindowStart() {
    if (hourlyToday.length < 3) return peakHour;
    var bestStart = 0;
    var bestTotal = -1;
    for (var start = 0; start <= hourlyToday.length - 3; start++) {
      final total =
          hourlyToday[start] + hourlyToday[start + 1] + hourlyToday[start + 2];
      if (total > bestTotal) {
        bestTotal = total;
        bestStart = start;
      }
    }
    return bestStart;
  }

  int _sumHours(List<int> hours) {
    var total = 0;
    for (final hour in hours) {
      if (hour < hourlyToday.length) total += hourlyToday[hour];
    }
    return total;
  }

  List<UsageSession> _sortSessions() {
    final sorted = [...sessions]
      ..sort((a, b) => b.minutes.compareTo(a.minutes));
    return List.unmodifiable(sorted);
  }

  Child copyWith({
    String? id,
    String? name,
    int? age,
    String? deviceName,
    DevicePlatform? platform,
    Color? accent,
    List<UsageApp>? apps,
    List<DailyUsage>? days,
    List<int>? hourlyToday,
    List<UsageSession>? sessions,
    int? unlocksToday,
    int? notificationsToday,
    DateTime? lastSyncedAt,
  }) => Child(
    id: id ?? this.id,
    name: name ?? this.name,
    age: age ?? this.age,
    deviceName: deviceName ?? this.deviceName,
    platform: platform ?? this.platform,
    accent: accent ?? this.accent,
    apps: apps ?? this.apps,
    days: days ?? this.days,
    hourlyToday: hourlyToday ?? this.hourlyToday,
    sessions: sessions ?? this.sessions,
    unlocksToday: unlocksToday ?? this.unlocksToday,
    notificationsToday: notificationsToday ?? this.notificationsToday,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
  );

  factory Child.fromJson(Map<String, dynamic> json) => Child(
    id: json['id'] as String,
    name: json['name'] as String,
    age: json['age'] as int,
    deviceName: json['deviceName'] as String,
    platform: DevicePlatform.values.firstWhere(
      (p) => p.name == json['platform'],
      orElse: () => DevicePlatform.ios,
    ),
    accent: Color(json['accent'] as int),
    apps:
        (json['apps'] as List<dynamic>?)
            ?.map((a) => UsageApp.fromJson(a as Map<String, dynamic>))
            .toList() ??
        const [],
    days:
        (json['days'] as List<dynamic>?)
            ?.map((d) => DailyUsage.fromJson(d as Map<String, dynamic>))
            .toList() ??
        const [],
    hourlyToday:
        (json['hourlyToday'] as List<dynamic>?)?.cast<int>() ?? const [],
    sessions:
        (json['sessions'] as List<dynamic>?)
            ?.map((s) => UsageSession.fromJson(s as Map<String, dynamic>))
            .toList() ??
        const [],
    unlocksToday: json['unlocksToday'] as int? ?? 0,
    notificationsToday: json['notificationsToday'] as int? ?? 0,
    lastSyncedAt: DateTime.parse(json['lastSyncedAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'age': age,
    'deviceName': deviceName,
    'platform': platform.name,
    'accent': accent.toARGB32(),
    'apps': apps.map((a) => a.toJson()).toList(),
    'days': days.map((d) => d.toJson()).toList(),
    'hourlyToday': hourlyToday,
    'sessions': sessions.map((s) => s.toJson()).toList(),
    'unlocksToday': unlocksToday,
    'notificationsToday': notificationsToday,
    'lastSyncedAt': lastSyncedAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Child && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
