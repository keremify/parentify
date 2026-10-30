import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:parentify/app.dart';
import 'package:parentify/data/demo_data.dart';
import 'package:parentify/models/visibility.dart';
import 'package:parentify/services/ai_analyzer_service.dart';
import 'package:parentify/state/app_state.dart';
import 'package:parentify/widgets/child_selector_card.dart';

Future<void> _loadAppFonts() async {
  final loader = FontLoader('PlusJakartaSans');
  for (final file in [
    'PlusJakartaSans-Regular.ttf',
    'PlusJakartaSans-Medium.ttf',
    'PlusJakartaSans-SemiBold.ttf',
    'PlusJakartaSans-Bold.ttf',
    'PlusJakartaSans-ExtraBold.ttf',
  ]) {
    loader.addFont(rootBundle.load('assets/fonts/$file'));
  }
  await loader.load();
}

Future<void> _tapChild(WidgetTester tester, String name) async {
  final card = find.ancestor(
    of: find.text(name),
    matching: find.byType(ChildSelectorCard),
  );
  if (card.evaluate().isEmpty) {
    final carousel = find.byWidgetPredicate(
      (widget) =>
          widget is ListView && widget.scrollDirection == Axis.horizontal,
    );
    await tester.dragUntilVisible(
      card,
      find.descendant(of: carousel, matching: find.byType(Scrollable)),
      const Offset(-250, 0),
    );
  }
  await tester.ensureVisible(card.first);
  await tester.pumpAndSettle();
  await tester.tap(card.first);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_loadAppFonts);

  group('Demo data', () {
    test('children have coherent two-week activity', () {
      final family = DemoData.build();
      expect(family.children, hasLength(3));

      for (final child in family.children) {
        expect(child.days, hasLength(14));
        expect(child.hourlyToday, hasLength(24));
        expect(
          child.hourlyToday.fold<int>(0, (total, minutes) => total + minutes),
          child.todayMinutes,
          reason: '${child.name}\'s hourly chart should add up to the day.',
        );
        expect(
          child.apps.fold<int>(0, (total, app) => total + app.weekMinutes),
          child.weekMinutes,
          reason: '${child.name}\'s app totals should add up to the week.',
        );
        expect(child.sessions, isNotEmpty);
        expect(child.topApp, isNotNull);
        expect(child.topApp!.weekMinutes, greaterThan(0));
        expect(child.peakWindowStart, inInclusiveRange(0, 21));
      }
    });

    test('the local analyzer produces day and week observations', () {
      final child = DemoData.build().children[1];
      final report = AiAnalyzerService.buildLocalReport(child);

      expect(report.headline, contains(child.name));
      expect(report.summary, contains('Today'));
      expect(report.observations.length, greaterThanOrEqualTo(4));
      expect(report.suggestions, hasLength(3));
      expect(report.fromModel, isFalse);
    });
  });

  group('App flows', () {
    testWidgets('parent can sign in, pick a child and open insights', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(ParentifyApp(state: AppState()));
      await tester.pumpAndSettle();

      expect(find.text('Parent email'), findsOneWidget);
      expect(find.text('Enter the family space'), findsOneWidget);

      await tester.tap(find.text('Use demo account'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      expect(find.text('Choose a child'), findsOneWidget);
      expect(find.text('Waiting for you'), findsOneWidget);
      expect(find.text('MERT ASKED'), findsOneWidget);
      expect(find.text('Ada'), findsWidgets);

      await _tapChild(tester, 'Zeynep');

      expect(find.text('This week'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Longest stretches'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Longest stretches'), findsOneWidget);

      await tester.tap(find.text('Apps'));
      await tester.pumpAndSettle();
      expect(find.text('All apps'), findsOneWidget);
      expect(find.text('YouTube Kids'), findsWidgets);

      await tester.tap(find.text('Insights'));
      await tester.pumpAndSettle();
      expect(find.text('AI CHECK-IN'), findsOneWidget);
      expect(find.text('What changed'), findsOneWidget);

      await tester.tap(find.text('Refresh'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('Reading 14 days'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();
      expect(find.textContaining('Analysis refreshed'), findsOneWidget);
    });

    testWidgets('wrong password keeps the parent on the login screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(ParentifyApp(state: AppState()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(1), 'wrong-password');
      await tester.tap(find.text('Enter the family space'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      expect(find.text('Choose a child'), findsNothing);
      expect(find.textContaining('do not match'), findsOneWidget);
    });

    testWidgets('child sign-in requires the demo PIN', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(ParentifyApp(state: AppState()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Child'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zeynep'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open my activity'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      expect(find.text('Hi, Zeynep'), findsNothing);
      expect(find.textContaining('PIN'), findsWidgets);
    });

    testWidgets('child can sign in to their own activity', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(ParentifyApp(state: AppState()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Child'));
      await tester.pumpAndSettle();

      expect(find.text('Open my activity'), findsOneWidget);
      expect(find.text('WHO IS CHECKING IN?'), findsOneWidget);

      await tester.tap(find.text('Zeynep'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use demo PIN'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      expect(find.text('Hi, Zeynep'), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Apps'), findsOneWidget);
      expect(find.text('Insights'), findsOneWidget);
      expect(find.text('Together'), findsOneWidget);
      expect(find.text('Ask for more time'), findsOneWidget);
      expect(
        find.textContaining('Your parent sees full detail'),
        findsOneWidget,
      );
    });

    testWidgets('parent sees the visibility ladder for each child', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(ParentifyApp(state: AppState()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use demo account'));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      await _tapChild(tester, 'Ada');
      expect(find.textContaining('Trends only'), findsWidgets);
      await tester.tap(find.text('Apps'));
      await tester.pumpAndSettle();
      expect(find.text('App detail is private'), findsOneWidget);

      await tester.tap(find.byTooltip('Back to family'));
      await tester.pumpAndSettle();
      await _tapChild(tester, 'Mert');
      await tester.tap(find.text('Apps'));
      await tester.pumpAndSettle();
      expect(find.text('All apps'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining(
          'App totals are shared; drill-down stays with Mert',
        ),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      expect(
        find.textContaining(
          'App totals are shared; drill-down stays with Mert',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Back to family'));
      await tester.pumpAndSettle();
      await _tapChild(tester, 'Zeynep');
      await tester.tap(find.text('Apps'));
      await tester.pumpAndSettle();
      expect(find.text('All apps'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Tap an app to see its daily rhythm'),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Tap an app to see its daily rhythm'), findsOneWidget);
    });

    testWidgets('trends sharing keeps day notes out of the overview', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = AppState();
      addTearDown(state.dispose);
      await tester.runAsync(state.signInDemoParent);
      expect(state.visibilityFor('ada'), VisibilityLevel.trends);

      await tester.pumpWidget(ParentifyApp(state: state));
      await tester.pumpAndSettle();
      await _tapChild(tester, 'Ada');
      await tester.pumpAndSettle();

      expect(
        find.text('The late bit was a school-trip group chat, not scrolling.'),
        findsNothing,
      );
      expect(find.text("Today's context"), findsNothing);
      expect(find.text('Add context'), findsNothing);
    });

    testWidgets('guided sharing hides hourly and session detail', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = AppState();
      addTearDown(state.dispose);
      await tester.runAsync(state.signInDemoParent);
      state.setVisibility('mert', VisibilityLevel.guided);

      await tester.pumpWidget(ParentifyApp(state: state));
      await tester.pumpAndSettle();
      await _tapChild(tester, 'Mert');
      await tester.pumpAndSettle();

      // Overview: app totals stay, session cards and the peak window do not.
      expect(find.text('App usage'), findsOneWidget);
      expect(find.text('Longest stretches'), findsNothing);
      expect(find.text('Peak window'), findsNothing);
      expect(find.textContaining('Hourly and session detail'), findsOneWidget);

      await tester.tap(find.text('Insights'));
      await tester.pumpAndSettle();

      expect(find.text('What changed'), findsOneWidget);
      expect(find.text('When the device is busiest'), findsNothing);
      expect(find.text('Longest stretches'), findsNothing);
      expect(find.text('What the analysis noticed'), findsNothing);
    });

    testWidgets('weekly check-in saves and changes the home copy', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(ParentifyApp(state: AppState()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use demo account'));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Open check-in'),
        300,
        scrollable: scrollable,
      );
      await tester.tap(find.text('Open check-in'));
      await tester.pumpAndSettle();

      expect(find.text('Weekly check-in'), findsWidgets);
      expect(find.text('We talked about this'), findsOneWidget);

      await tester.tap(find.text('We talked about this'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Check-in saved'), findsOneWidget);
      expect(
        find.text(
          'This week\'s check-in is done. You can update the focus below.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.textContaining('Last time you talked about'),
        300,
        scrollable: scrollable,
      );
      expect(find.textContaining('Last time you talked about'), findsOneWidget);
    });

    testWidgets('a child note appears in the parent view', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(ParentifyApp(state: AppState()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Child'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zeynep'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use demo PIN'));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add context'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).first,
        'Bike ride after school',
      );
      await tester.pump();
      await tester.tap(find.text('Save note'));
      await tester.pumpAndSettle();
      expect(find.text('Save note'), findsNothing);
      expect(find.text('Bike ride after school'), findsOneWidget);

      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Exit child view'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Exit child view'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Use demo account'));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();
      await _tapChild(tester, 'Zeynep');
      expect(find.text('Bike ride after school'), findsOneWidget);
    });
  });
}
