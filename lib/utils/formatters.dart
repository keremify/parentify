import '../l10n/app_strings.dart';
import 'clock.dart';
import 'dates.dart';

/// "3h 42m", "45m", "2h".
String formatMinutes(int minutes, {AppStrings strings = AppStrings.english}) =>
    strings.formatMinutes(minutes);

/// Signed percentage with a rounded value: "+24%", "-9%", "0%".
String formatSignedPercent(
  double ratio, {
  AppStrings strings = AppStrings.english,
}) => strings.signedPercent(ratio);

/// A readable difference: "1h 12m more", "23m less".
String formatDifference(
  int minutes, {
  AppStrings strings = AppStrings.english,
}) => strings.difference(minutes);

String weekdayShort(DateTime date, {AppStrings strings = AppStrings.english}) =>
    strings.weekdayShort(date);

String weekdayLetter(
  DateTime date, {
  AppStrings strings = AppStrings.english,
}) => strings.weekdayLetter(date);

String monthShort(DateTime date, {AppStrings strings = AppStrings.english}) =>
    strings.monthShort(date);

String monthLong(DateTime date, {AppStrings strings = AppStrings.english}) =>
    strings.monthLong(date);

/// "Mon, 26 Oct"
String formatDateShort(
  DateTime date, {
  AppStrings strings = AppStrings.english,
}) => strings.dateShort(date);

/// "26 October"
String formatDateLong(
  DateTime date, {
  AppStrings strings = AppStrings.english,
}) => strings.dateLong(date);

/// "TODAY · MON, 26 OCT"
String formatDateUpper(
  DateTime date, {
  AppStrings strings = AppStrings.english,
}) => strings.dateUpper(date);

/// "Today", "Yesterday", "Sat, 24 Oct"
String relativeDay(
  DateTime date, {
  DateTime? now,
  AppStrings strings = AppStrings.english,
}) {
  final reference = now ?? AppClock.now();
  final difference = daysBetween(date, reference);
  if (difference == 0) return strings.today;
  if (difference == 1) return strings.yesterday;
  return formatDateShort(date, strings: strings);
}

/// "8 PM"
String formatHourLabel(int hour, {AppStrings strings = AppStrings.english}) =>
    strings.hourLabel(hour);

/// A friendly window: "8–10 PM", "11 AM–1 PM".
String formatHourRange(
  int startHour,
  int endHour, {
  AppStrings strings = AppStrings.english,
}) => strings.hourRange(startHour, endHour);

/// "7:40 PM"
String formatTime(DateTime time, {AppStrings strings = AppStrings.english}) =>
    strings.timeOfDay(time);

String greetingFor(DateTime time, {AppStrings strings = AppStrings.english}) =>
    strings.greeting(time);

String formatSyncedAt(
  DateTime time, {
  DateTime? now,
  AppStrings strings = AppStrings.english,
}) {
  final reference = now ?? AppClock.now();
  final diff = reference.difference(time).inMinutes;
  if (diff <= 0) return strings.justNow;
  if (diff == 1) return strings.oneMinAgo;
  if (diff < 60) return strings.minutesAgo(diff);
  final hours = diff ~/ 60;
  return hours == 1 ? strings.oneHourAgo : strings.hoursAgo(hours);
}
