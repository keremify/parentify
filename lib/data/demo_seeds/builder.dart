part of '../demo_data.dart';

Child _buildChild({
  required String id,
  required String name,
  required int age,
  required String deviceName,
  required DevicePlatform platform,
  required Color accent,
  required int baseMinutes,
  required int todayMinutes,
  required int yesterdayMinutes,
  required int unlocksToday,
  required int notificationsToday,
  required List<double> jitter,
  required List<int> hourWeights,
  required List<_AppSeed> seeds,
  required List<_SessionSeed> sessions,
  required int syncMinutesAgo,
  required DateTime today,
}) {
  const weekdayFactors = [0.88, 1.0, 0.94, 1.02, 1.14, 1.34, 1.24];

  // Fourteen days of daily screen time.
  final days = <DailyUsage>[];
  for (var index = 0; index < 14; index++) {
    final date = addDays(today, index - 13);
    final weekdayFactor = weekdayFactors[date.weekday - 1];
    var minutes = (baseMinutes * weekdayFactor * jitter[index]).round();
    if (index == 13) minutes = todayMinutes;
    if (index == 12) minutes = yesterdayMinutes;
    days.add(
      DailyUsage(
        date: date,
        minutes: minutes,
        unlocks: (minutes / 4).round() + (index % 5) * 2,
      ),
    );
  }

  // Per-app minutes for each of the fourteen days. The remainder is
  // distributed so app totals always add up to the day's screen time.
  final appDaily = List.generate(seeds.length, (_) => <int>[]);
  for (var dayIndex = 0; dayIndex < days.length; dayIndex++) {
    final weights = <double>[
      for (var appIndex = 0; appIndex < seeds.length; appIndex++)
        seeds[appIndex].share *
            (0.80 + ((dayIndex * 17 + appIndex * 23) % 41) / 100),
    ];
    final allocated = _allocate(days[dayIndex].minutes, weights);
    for (var appIndex = 0; appIndex < seeds.length; appIndex++) {
      appDaily[appIndex].add(allocated[appIndex]);
    }
  }

  final apps = <UsageApp>[
    for (var appIndex = 0; appIndex < seeds.length; appIndex++)
      UsageApp(
        id: seeds[appIndex].id,
        name: seeds[appIndex].name,
        category: seeds[appIndex].category,
        icon: seeds[appIndex].icon,
        color: seeds[appIndex].color,
        last7Days: appDaily[appIndex].sublist(appDaily[appIndex].length - 7),
        launchesToday: seeds[appIndex].launches,
      ),
  ];

  // Today's hour-by-hour shape.
  final hourWeightsAdjusted = <double>[
    for (var hour = 0; hour < 24; hour++)
      hourWeights[hour] * (0.82 + ((hour * 37) % 31) / 100),
  ];
  final hourlyToday = _allocate(todayMinutes, hourWeightsAdjusted);

  final now = AppClock.now();
  final anchor = dateOnly(today);
  final generatedSessions = <UsageSession>[
    for (var index = 0; index < sessions.length; index++)
      UsageSession(
        id: '$id-session-$index',
        start: addDays(anchor, -sessions[index].daysAgo).add(
          Duration(
            hours: sessions[index].hour,
            minutes: sessions[index].minute,
          ),
        ),
        minutes: sessions[index].minutes,
        label: sessions[index].label,
        category: sessions[index].category,
        apps: sessions[index].apps,
      ),
  ];

  return Child(
    id: id,
    name: name,
    age: age,
    deviceName: deviceName,
    platform: platform,
    accent: accent,
    apps: apps,
    days: days,
    hourlyToday: hourlyToday,
    sessions: generatedSessions,
    unlocksToday: unlocksToday,
    notificationsToday: notificationsToday,
    lastSyncedAt: now.subtract(Duration(minutes: syncMinutesAgo)),
  );
}

/// Splits [total] across [weights] without losing or duplicating minutes.
List<int> _allocate(int total, List<double> weights) {
  final sum = weights.fold<double>(0, (value, weight) => value + weight);
  if (sum <= 0 || total <= 0) return List<int>.filled(weights.length, 0);

  final exact = [for (final weight in weights) total * weight / sum];
  final result = [for (final value in exact) value.floor()];
  var remainder = total - result.fold(0, (value, part) => value + part);

  final order = List<int>.generate(weights.length, (index) => index)
    ..sort((a, b) {
      final fractionA = exact[a] - exact[a].floor();
      final fractionB = exact[b] - exact[b].floor();
      return fractionB.compareTo(fractionA);
    });

  var cursor = 0;
  while (remainder > 0) {
    result[order[cursor % order.length]] += 1;
    cursor++;
    remainder--;
  }
  return result;
}
