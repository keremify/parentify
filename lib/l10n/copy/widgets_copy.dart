part of '../app_strings.dart';

mixin WidgetsCopy {
  // ---------------------------------------------------------------------------
  // Widgets
  // ---------------------------------------------------------------------------

  String get together => 'Together';
  String get ourFamilyPlan => 'Our family plan';
  String get madeTogether => 'Made together with your parent';
  String agreedNotImposed(String name) => 'Agreed with $name, not imposed';
  String get activeBadge => 'ACTIVE';
  String get noPlanChild =>
      'No plan yet. Ask for one gentle change whenever it helps.';
  String get noAgreementParent =>
      'No agreement yet. Start with one gentle rule together.';
  String parentSeesShort(String label) => 'Your parent sees $label.';
  String sharingWithChild(String name, String label) =>
      'Sharing with $name: $label';
  String get adjust => 'Adjust';
  String get requestWaiting => 'Your request is waiting for a reply.';
  String childHasOpenRequest(String name) => '$name has an open request.';
  String get review => 'Review';
  String get parentRepliedNoNote => 'Your parent replied to your last request';
  String parentRepliedWithNote(String note) =>
      'Your parent replied to your last request: $note';
  String lastReplySaved(String name) =>
      'Your last reply to $name is saved in the plan';
  String askedUpper(String name) => '${name.toUpperCase()} ASKED';
  String get newBadge => 'NEW';
  String askedAt(String time) => 'Asked $time';
  String get reviewRequest => 'Review request';
  String todaySuffix(String minutes) => '$minutes today';
  String noteSemantics(String text) => 'Note: $text';
  String get childNote => 'child note';
  String get parentNote => 'parent note';
  String noteMeta(String tag, String author) => '$tag · $author';
  String sessionTime(String day, String start, String end) =>
      '$day · $start – $end';
  String get last7DaysLower => 'last 7 days';
  String get thisWeekLower => 'this week';
  String get weeklyChartNoData => 'Weekly screen time chart, no data yet.';
  String dayNumber(int index) => 'Day $index';
  String weeklyChartPart(
    String label,
    String minutes, {
    bool isToday = false,
  }) => '$label $minutes${isToday ? ' today' : ''}';
  String weeklyChartSummary(String parts) => 'Weekly screen time: $parts.';
  String get recentTrendNoData => 'Recent screen time trend, no data yet.';
  String recentTrendSummary(String lowest, String highest, String latest) =>
      'Recent screen time trend: lowest $lowest, highest $highest, '
      'latest $latest.';
  String get fourteenDayNoData => 'Fourteen-day trend chart, no data yet.';
  String get screenTimeNoData => 'no data';
  String trendSummarySingle(int days, String average, String today) =>
      'Screen time trend. The last $days days averaged $average a day; '
      'today is $today.';
  String trendSummary(
    String earlierAverage,
    int recentDays,
    String recentAverage,
    String today,
  ) =>
      'Fourteen-day screen time trend. The earlier week averaged '
      '$earlierAverage a day; the last $recentDays days averaged '
      '$recentAverage. Today is $today.';
  String get categoryChartNoData => 'App category chart, no data yet.';
  String categoryShare(String label, int percent) => '$label $percent percent';
  String categorySummary(String total, String parts) =>
      'App categories this week, $total total: $parts.';
  String get hourlyChartNoData => 'Hourly activity chart, no data yet.';
  String hourlySummary(String total, String peakHour, String peakMinutes) =>
      'Today by hour, $total in total. Busiest around $peakHour with '
      '$peakMinutes.';
  String get hour12a => '12a';
  String get hour6a => '6a';
  String get hour12p => '12p';
  String get hour6p => '6p';
  String get demoBadge => 'DEMO';
}
