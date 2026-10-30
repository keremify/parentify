part of '../app_strings.dart';

const _weekdaysShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _weekdaysLetter = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const _monthsShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
const _monthsLong = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

mixin LocaleCopy {
  // ---------------------------------------------------------------------------
  // Locale data and formatting
  // ---------------------------------------------------------------------------

  String categoryLabel(AppCategory category) => switch (category) {
    AppCategory.social => 'Social',
    AppCategory.gaming => 'Gaming',
    AppCategory.video => 'Video',
    AppCategory.education => 'Learning',
    AppCategory.messaging => 'Messaging',
    AppCategory.creativity => 'Creativity',
    AppCategory.utilities => 'Utilities',
  };

  String visibilityLabel(VisibilityLevel level) => switch (level) {
    VisibilityLevel.full => 'Full detail',
    VisibilityLevel.guided => 'Guided',
    VisibilityLevel.trends => 'Trends only',
  };

  String visibilityShortLabel(VisibilityLevel level) => switch (level) {
    VisibilityLevel.full => 'full detail',
    VisibilityLevel.guided => 'guided summaries',
    VisibilityLevel.trends => 'weekly trends',
  };

  String visibilityDescription(VisibilityLevel level) => switch (level) {
    VisibilityLevel.full =>
      'Daily totals, app totals and session detail. Best for younger '
          'children.',
    VisibilityLevel.guided =>
      'Summaries, app totals and shared notes. Hourly and session detail '
          'are hidden.',
    VisibilityLevel.trends =>
      'Weekly trends and daily totals only. No hourly, app or session '
          'detail.',
  };

  String noteTagLabel(NoteTag tag) => switch (tag) {
    NoteTag.school => 'School',
    NoteTag.friends => 'Friends',
    NoteTag.family => 'Family',
    NoteTag.sleep => 'Sleep',
    NoteTag.bored => 'Bored',
    NoteTag.other => 'Other',
  };

  String platformLabel(DevicePlatform platform) => switch (platform) {
    DevicePlatform.ios => 'iOS',
    DevicePlatform.android => 'Android',
  };

  String get zeroMinutes => '0m';
  String minutesOnly(int minutes) => '${minutes}m';
  String hoursOnly(int hours) => '${hours}h';
  String hoursAndMinutes(int hours, int minutes) => '${hours}h ${minutes}m';
  String get noChange => 'no change';
  String differenceMore(String duration) => '$duration more';
  String differenceLess(String duration) => '$duration less';

  String weekdayShort(DateTime date) => _weekdaysShort[date.weekday - 1];
  String weekdayLetter(DateTime date) => _weekdaysLetter[date.weekday - 1];
  String monthShort(DateTime date) => _monthsShort[date.month - 1];
  String monthLong(DateTime date) => _monthsLong[date.month - 1];
  String dateShort(DateTime date) =>
      '${weekdayShort(date)}, ${date.day} ${monthShort(date)}';
  String dateHeading(DateTime date) =>
      '${weekdayShort(date)}, ${date.day} ${monthLong(date)}'.toUpperCase();
  String dateLong(DateTime date) => '${date.day} ${monthLong(date)}';
  String dateUpper(DateTime date) => dateShort(date).toUpperCase();
  String get justNow => 'Just now';
  String get oneMinAgo => '1 min ago';
  String minutesAgo(int minutes) => '$minutes min ago';
  String get oneHourAgo => '1 hour ago';
  String hoursAgo(int hours) => '$hours hours ago';
  String get goodMorning => 'Good morning';
  String get goodAfternoon => 'Good afternoon';
  String get goodEvening => 'Good evening';
  String get noData => 'no data';

  String formatMinutes(int minutes) {
    if (minutes <= 0) return zeroMinutes;
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (hours == 0) return minutesOnly(remainder);
    if (remainder == 0) return hoursOnly(hours);
    return hoursAndMinutes(hours, remainder);
  }

  String signedPercent(double ratio) {
    final percentage = (ratio * 100).round();
    if (percentage > 0) return '+$percentage%';
    return '$percentage%';
  }

  String percent(int value) => '$value%';

  String difference(int minutes) {
    if (minutes == 0) return noChange;
    final absolute = formatMinutes(minutes.abs());
    return minutes > 0 ? differenceMore(absolute) : differenceLess(absolute);
  }

  String hourLabel(int hour) {
    final normalized = hour % 24;
    final display = normalized % 12 == 0 ? 12 : normalized % 12;
    final suffix = normalized < 12 ? 'AM' : 'PM';
    return '$display $suffix';
  }

  String hourRange(int startHour, int endHour) {
    final start = startHour % 24;
    final end = endHour % 24;
    final startDisplay = start % 12 == 0 ? 12 : start % 12;
    final endDisplay = end % 12 == 0 ? 12 : end % 12;
    final startSuffix = start < 12 ? 'AM' : 'PM';
    final endSuffix = end < 12 ? 'AM' : 'PM';
    if (startSuffix == endSuffix) {
      return '$startDisplay–$endDisplay $endSuffix';
    }
    return '$startDisplay $startSuffix–$endDisplay $endSuffix';
  }

  String timeOfDay(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $suffix';
  }

  String greeting(DateTime time) {
    if (time.hour < 12) return goodMorning;
    if (time.hour < 18) return goodAfternoon;
    return goodEvening;
  }

  String greetingWithName(DateTime time, String name) =>
      '${greeting(time)}, $name';
}
