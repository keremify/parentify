import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:parentify/data/demo_data.dart';
import 'package:parentify/models/app_usage.dart';
import 'package:parentify/models/child.dart';
import 'package:parentify/services/ai_analyzer_service.dart';
import 'package:parentify/services/change_explainer.dart';
import 'package:parentify/state/app_state.dart';

Child _child({
  String id = 'child-1',
  List<DailyUsage> days = const [],
  List<UsageApp> apps = const [],
  List<int> hourlyToday = const [],
  int unlocksToday = 0,
}) {
  return Child(
    id: id,
    name: 'Test Child',
    age: 10,
    deviceName: 'Test phone',
    platform: DevicePlatform.android,
    accent: const Color(0xFF4A90D9),
    apps: apps,
    days: days,
    hourlyToday: hourlyToday,
    sessions: const [],
    unlocksToday: unlocksToday,
    notificationsToday: 0,
    lastSyncedAt: DateTime(2026, 1, 1),
  );
}

DailyUsage _day(int index, {int minutes = 60, int unlocks = 10}) {
  return DailyUsage(
    date: DateTime(2026, 1, 1).add(Duration(days: index)),
    minutes: minutes,
    unlocks: unlocks,
  );
}

UsageApp _app({int weekMinutes = 0}) {
  return UsageApp(
    id: 'app-1',
    name: 'Test App',
    category: AppCategory.social,
    icon: Icons.circle,
    color: const Color(0xFF000000),
    last7Days: List<int>.filled(7, weekMinutes ~/ 7),
    launchesToday: 1,
  );
}

void main() {
  group('Child tolerates partial synced data', () {
    test('empty days and apps return safe defaults', () {
      final child = _child();

      expect(child.today, isNull);
      expect(child.yesterday, isNull);
      expect(child.todayMinutes, 0);
      expect(child.yesterdayMinutes, 0);
      expect(child.last7Days, isEmpty);
      expect(child.previous7Days, isEmpty);
      expect(child.weekMinutes, 0);
      expect(child.previousWeekMinutes, 0);
      expect(child.weeklyAverage, 0);
      expect(child.topApp, isNull);
      expect(child.peakWindowStart, 0);
      expect(child.lateNightMinutes, 0);
      expect(child.dayOverDay.ratio, 0);
      expect(child.weekOverWeek.ratio, 0);
    });

    test('five days of history keeps previous7Days empty', () {
      final child = _child(days: [for (var i = 0; i < 5; i++) _day(i)]);

      expect(child.previous7Days, isEmpty);
      expect(child.previousWeekMinutes, 0);
      expect(child.weeklyAverage, 60);
      expect(child.dayOverDay.current, 60);
      expect(child.dayOverDay.previous, 60);
    });

    test('ten days of history exposes the partial previous week', () {
      final child = _child(days: [for (var i = 0; i < 10; i++) _day(i)]);

      expect(child.previous7Days, hasLength(3));
      expect(child.previousWeekMinutes, 180);
      expect(child.weekMinutes, 420);
    });
  });

  group('Analysis tolerates partial data', () {
    test('empty child does not crash the explainer or report', () {
      final child = _child();

      expect(ChangeExplainer.explainDay(child), isEmpty);
      expect(
        ChangeExplainer.answerFor(child, InsightQuestion.week),
        isNotEmpty,
      );
      expect(() => AiAnalyzerService.buildLocalReport(child), returnsNormally);
      expect(() => AiAnalyzerService.buildSummary(child), returnsNormally);
      expect(() => AiAnalyzerService.buildPrompt(child), returnsNormally);
    });

    test('short hourly history does not index past the end', () {
      final child = _child(
        days: [for (var i = 0; i < 14; i++) _day(i)],
        hourlyToday: List<int>.filled(10, 3),
      );

      expect(() => AiAnalyzerService.buildLocalReport(child), returnsNormally);
    });

    test('zero app minutes does not divide by zero', () {
      final child = _child(
        days: [for (var i = 0; i < 14; i++) _day(i)],
        apps: [_app()],
        hourlyToday: List<int>.filled(24, 0),
      );

      expect(() => AiAnalyzerService.buildLocalReport(child), returnsNormally);
      expect(AiAnalyzerService.buildSummary(child), isNotEmpty);
    });
  });

  group('Family week aggregation', () {
    test('fills missing days with zero across partial histories', () {
      final state = AppState(
        family: DemoFamily(
          parentName: 'Parent',
          parentEmail: 'parent@example.com',
          familyName: 'Test family',
          children: [
            _child(id: 'empty'),
            _child(id: 'one', days: [_day(0, minutes: 30)]),
            _child(
              id: 'three',
              days: [for (var i = 0; i < 3; i++) _day(i, minutes: 10)],
            ),
          ],
        ),
      );
      addTearDown(state.dispose);

      expect(state.familyWeekByDay, [40, 10, 10, 0, 0, 0, 0]);
    });
  });

  group('AppState guards missing children', () {
    test('childById returns null for an unknown id', () {
      final state = AppState(
        family: DemoFamily(
          parentName: 'Parent',
          parentEmail: 'parent@example.com',
          familyName: 'Test family',
          children: [],
        ),
      );
      addTearDown(state.dispose);

      expect(state.childById('missing'), isNull);
    });

    test('signing in as a child without profiles stays signed out', () async {
      final state = AppState(
        family: DemoFamily(
          parentName: 'Parent',
          parentEmail: 'parent@example.com',
          familyName: 'Test family',
          children: [],
        ),
      );
      addTearDown(state.dispose);

      await state.signInDemoChild(childId: 'missing');

      expect(state.isSignedIn, isFalse);
      expect(state.activeChild, isNull);
    });
  });
}
