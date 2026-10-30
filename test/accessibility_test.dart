import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:parentify/app.dart';
import 'package:parentify/models/context_note.dart';
import 'package:parentify/state/app_state.dart';
import 'package:parentify/theme/app_theme.dart';
import 'package:parentify/widgets/charts.dart';
import 'package:parentify/widgets/child_selector_card.dart';
import 'package:parentify/widgets/common.dart';
import 'package:parentify/widgets/context_chip.dart';

double _linear(double channel) => channel <= 0.03928
    ? channel / 12.92
    : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color color) =>
    0.2126 * _linear(color.r) +
    0.7152 * _linear(color.g) +
    0.0722 * _linear(color.b);

double _contrast(Color foreground, Color background) {
  final first = _luminance(foreground);
  final second = _luminance(background);
  final lighter = math.max(first, second);
  final darker = math.min(first, second);
  return (lighter + 0.05) / (darker + 0.05);
}

Future<void> _pumpCharts(WidgetTester tester) async {
  final now = DateTime(2026, 3, 11);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              WeeklyBarChart(
                minutes: const [60, 120, 90, 150, 75, 210, 100],
                dates: [
                  for (var index = 6; index >= 0; index--)
                    now.subtract(Duration(days: index)),
                ],
                color: AppColors.violet,
              ),
              const MiniSparkline(
                values: [40, 55, 30, 70, 65, 80, 50],
                color: AppColors.mint,
              ),
              TrendChart(
                values: [
                  for (var index = 0; index < 14; index++) 60 + index * 5,
                ],
                dates: [
                  for (var index = 13; index >= 0; index--)
                    now.subtract(Duration(days: index)),
                ],
                color: AppColors.violet,
              ),
              const CategoryDonut(
                total: 300,
                slices: [
                  DonutSlice(
                    label: 'Games',
                    value: 150,
                    color: AppColors.violet,
                  ),
                  DonutSlice(label: 'Social', value: 90, color: AppColors.sky),
                  DonutSlice(label: 'Video', value: 60, color: AppColors.coral),
                ],
              ),
              HourlyActivityStrip(
                hourly: [
                  for (var hour = 0; hour < 24; hour++) hour == 20 ? 50 : 8,
                ],
                color: AppColors.violet,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Contrast', () {
    test('muted and subtle text meet WCAG AA on every card surface', () {
      const surfaces = [
        AppColors.paper,
        AppColors.cream,
        AppColors.parchment,
        AppColors.violetSoft,
        AppColors.mintSoft,
      ];

      for (final color in [AppColors.muted, AppColors.subtle]) {
        for (final surface in surfaces) {
          expect(
            _contrast(color, surface),
            greaterThanOrEqualTo(4.5),
            reason: 'Text $color on $surface is below the AA 4.5:1 threshold.',
          );
        }
      }
    });
  });

  group('Chart semantics', () {
    testWidgets('every chart exposes a readable label', (tester) async {
      final handle = tester.ensureSemantics();

      await _pumpCharts(tester);
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(RegExp('Weekly screen time')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('Recent screen time trend')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('Fourteen-day screen time trend')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('App categories this week')),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp('Today by hour')), findsOneWidget);

      handle.dispose();
    });
  });

  group('Tap targets', () {
    testWidgets('round icon buttons keep a 48dp hit area', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RoundIconButton(
                icon: Icons.close_rounded,
                size: 34,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(RoundIconButton)), const Size(48, 48));
    });

    testWidgets('section actions and tag chips are at least 48dp tall', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SectionHeader(
                  title: 'Longest stretches',
                  actionLabel: 'See all',
                  onAction: () {},
                ),
                NoteTagChip(tag: NoteTag.school, selected: false, onTap: () {}),
              ],
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(TextButton)).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSize(find.byType(NoteTagChip)).height,
        greaterThanOrEqualTo(48),
      );
    });
  });

  group('Custom controls', () {
    testWidgets('chips expose one labelled button each', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                NoteTagChip(tag: NoteTag.school, selected: true, onTap: () {}),
                ContextNoteChip(
                  note: ContextNote(
                    id: 'note-1',
                    childId: 'ada',
                    createdAt: DateTime(2026, 3, 11),
                    author: UserRole.parent,
                    tag: NoteTag.sleep,
                    text: 'Early night.',
                    scope: NoteScope.day,
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );

      final tagData = tester
          .getSemantics(find.byType(NoteTagChip))
          .getSemanticsData();
      expect(tagData.label, 'School');
      expect(tagData.hasAction(SemanticsAction.tap), isTrue);

      final noteData = tester
          .getSemantics(find.byType(ContextNoteChip))
          .getSemanticsData();
      expect(noteData.label, 'Note: Early night.');
      expect(noteData.hasAction(SemanticsAction.tap), isTrue);

      // The child text is excluded from semantics, so the label appears once
      // instead of being announced twice.
      expect(find.bySemanticsLabel(RegExp(r'^School$')), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(r'^Note: Early night\.$')),
        findsOneWidget,
      );

      handle.dispose();
    });
  });

  group('Large text', () {
    testWidgets('parent home and child detail survive 200% text scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final state = AppState();
      addTearDown(state.dispose);
      await tester.runAsync(state.signInDemoParent);

      await tester.pumpWidget(ParentifyApp(state: state));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byType(ChildSelectorCard).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
