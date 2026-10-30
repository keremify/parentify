import 'package:flutter_test/flutter_test.dart';

import 'package:parentify/data/demo_data.dart';
import 'package:parentify/utils/clock.dart';
import 'package:parentify/utils/dates.dart';
import 'package:parentify/utils/formatters.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Calendar-day math', () {
    test('addDays keeps the local time across month and year boundaries', () {
      expect(
        addDays(DateTime(2026, 12, 31, 22, 30), 1),
        DateTime(2027, 1, 1, 22, 30),
      );
      expect(addDays(DateTime(2026, 3, 1, 8), -1), DateTime(2026, 2, 28, 8));
    });

    test('daysBetween ignores the time of day', () {
      expect(
        daysBetween(DateTime(2026, 3, 8, 23, 59), DateTime(2026, 3, 9, 0, 1)),
        1,
      );
      expect(
        daysBetween(DateTime(2026, 3, 9, 0, 1), DateTime(2026, 3, 8, 23, 59)),
        -1,
      );
    });

    test('startOfWeek lands on Monday at midnight', () {
      final monday = startOfWeek(DateTime(2026, 3, 11, 15, 42));
      expect(monday, DateTime(2026, 3, 9));
      expect(monday.weekday, DateTime.monday);
    });

    test('relativeDay compares calendar days, not elapsed hours', () {
      final now = DateTime(2026, 3, 11, 0, 15);
      expect(relativeDay(DateTime(2026, 3, 10, 23, 45), now: now), 'Yesterday');
      expect(relativeDay(DateTime(2026, 3, 11, 0, 1), now: now), 'Today');
    });
  });

  group('Immutable and memoised child data', () {
    setUp(() {
      AppClock.now = () => DateTime(2026, 3, 11, 9, 30);
    });

    tearDown(AppClock.reset);

    test('demo collections reject external mutation', () {
      final family = DemoData.build();
      final child = family.children.first;

      expect(() => family.children.add(child), throwsUnsupportedError);
      expect(() => child.apps.clear(), throwsUnsupportedError);
      expect(() => child.days.clear(), throwsUnsupportedError);
      expect(() => child.hourlyToday.clear(), throwsUnsupportedError);
      expect(() => child.sessions.clear(), throwsUnsupportedError);
      expect(() => child.weeklyCategoryMinutes.clear(), throwsUnsupportedError);
    });

    test('derived values are computed once and reused', () {
      final child = DemoData.build().children.first;

      expect(identical(child.appsByUsage, child.appsByUsage), isTrue);
      expect(identical(child.longestSessions, child.longestSessions), isTrue);
      expect(identical(child.last7Days, child.last7Days), isTrue);
      expect(
        identical(child.weeklyCategoryMinutes, child.weeklyCategoryMinutes),
        isTrue,
      );
      expect(child.topApp, same(child.appsByUsage.first));
    });
  });
}
