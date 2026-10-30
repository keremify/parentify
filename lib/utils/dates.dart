/// Calendar-day helpers.
///
/// Adding and subtracting [Duration]s is not date math: across a daylight
/// saving change, `midnight + 1 day` can land on 23:00 or 01:00 of the
/// neighbouring date. Everything in the demo that means "the next calendar
/// day" goes through these helpers instead.
DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Moves by whole calendar days while keeping the local time of day.
DateTime addDays(DateTime value, int days) => DateTime(
  value.year,
  value.month,
  value.day + days,
  value.hour,
  value.minute,
  value.second,
  value.millisecond,
  value.microsecond,
);

/// Whole calendar days from [from] to [to], ignoring time and DST.
int daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// Monday at local midnight for the week containing [value].
DateTime startOfWeek(DateTime value) {
  final day = dateOnly(value);
  return addDays(day, DateTime.monday - day.weekday);
}
