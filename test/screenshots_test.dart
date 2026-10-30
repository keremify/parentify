import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:parentify/app.dart';
import 'package:parentify/screens/child_detail_screen.dart';
import 'package:parentify/screens/weekly_checkin_sheet.dart';
import 'package:parentify/state/app_scope.dart';
import 'package:parentify/state/app_state.dart';
import 'package:parentify/theme/app_theme.dart';
import 'package:parentify/utils/clock.dart';

/// A fixed instant for every golden. Keep the weekday and hour stable so the
/// greeting, date header, and relative labels never change between runs.
final DateTime _frozenNow = DateTime(2026, 3, 11, 9, 30);

File? _findMaterialIconsFont() {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  final candidates = <String>[
    if (flutterRoot != null)
      '$flutterRoot/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
  ];

  var directory = File(Platform.resolvedExecutable).parent;
  for (var depth = 0; depth < 6; depth++) {
    candidates.add(
      '${directory.path}/cache/artifacts/material_fonts/materialicons-regular.otf',
    );
    directory = directory.parent;
  }

  for (final path in candidates) {
    final file = File(path);
    if (file.existsSync()) return file;
  }
  return null;
}

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

  final iconFile = _findMaterialIconsFont();
  if (iconFile == null) {
    throw StateError(
      'MaterialIcons font not found. Set FLUTTER_ROOT to the Flutter SDK root.',
    );
  }
  final iconBytes = await iconFile.readAsBytes();
  final iconLoader = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.view(iconBytes.buffer)));
  await iconLoader.load();
}

void _setPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(780, 1688);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _shot(WidgetTester tester, String name) async {
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$name.png'),
  );
}

Future<void> _pumpChild(
  WidgetTester tester, {
  required AppState state,
  required int tab,
  int childIndex = 0,
  bool childMode = false,
}) async {
  await tester.pumpWidget(
    AppScope(
      state: state,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: ChildDetailScreen(
          child: state.children[childIndex],
          initialTab: tab,
          childMode: childMode,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _signInParent(WidgetTester tester) async {
  await tester.tap(find.text('Use demo account'));
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pumpAndSettle();
}

Finder get _horizontalList => find.byWidgetPredicate(
  (widget) => widget is ListView && widget.scrollDirection == Axis.horizontal,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await _loadAppFonts();
    AppClock.now = () => _frozenNow;
  });
  tearDownAll(AppClock.reset);

  testWidgets('screens', (tester) async {
    _setPhone(tester);
    final state = AppState();

    await tester.pumpWidget(ParentifyApp(state: state));
    await tester.pumpAndSettle();
    await _shot(tester, '01_login_parent');

    await tester.tap(find.text('Child'));
    await tester.pumpAndSettle();
    await _shot(tester, '02_login_child');

    await tester.tap(find.text('Parent'));
    await tester.pumpAndSettle();
    await _signInParent(tester);
    await _shot(tester, '03_home');

    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -560),
    );
    await tester.pumpAndSettle();
    await _shot(tester, '04_home_lower');

    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, 560),
    );
    await tester.pumpAndSettle();
    await tester.drag(_horizontalList, const Offset(-520, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zeynep').first);
    await tester.pumpAndSettle();
    await _shot(tester, '05_child_overview');

    await tester.tap(find.text('Apps'));
    await tester.pumpAndSettle();
    await _shot(tester, '06_child_apps');

    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();
    await _shot(tester, '07_child_insights');

    await tester.drag(find.byType(ListView).first, const Offset(0, -520));
    await tester.pumpAndSettle();
    await _shot(tester, '08_insights_middle');

    await tester.drag(find.byType(ListView).first, const Offset(0, -620));
    await tester.pumpAndSettle();
    await _shot(tester, '09_insights_lower');
  });

  testWidgets('apps sheet', (tester) async {
    _setPhone(tester);
    final state = AppState();
    await _pumpChild(tester, state: state, tab: 1, childIndex: 2);
    await tester.tap(find.text('YouTube Kids').first);
    await tester.pumpAndSettle();
    await _shot(tester, '10_app_sheet');
  });

  testWidgets('settings sheet', (tester) async {
    _setPhone(tester);
    final state = AppState();
    await _pumpChild(tester, state: state, tab: 0);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await _shot(tester, '11_settings');
  });

  testWidgets('tablet home', (tester) async {
    tester.view.physicalSize = const Size(1640, 2360);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState();
    await tester.pumpWidget(ParentifyApp(state: state));
    await tester.pumpAndSettle();
    await _signInParent(tester);
    await _shot(tester, '12_tablet_home');
  });

  testWidgets('child request card', (tester) async {
    _setPhone(tester);
    final state = AppState();
    await tester.runAsync(() => state.signInDemoChild(childId: 'mert'));
    await _pumpChild(
      tester,
      state: state,
      tab: 0,
      childIndex: 1,
      childMode: true,
    );
    await _shot(tester, '13_request_card');
  });

  testWidgets('context note sheet', (tester) async {
    _setPhone(tester);
    final state = AppState();
    await _pumpChild(tester, state: state, tab: 0, childIndex: 2);
    await tester.ensureVisible(find.text('Add context').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add context').first);
    await tester.pumpAndSettle();
    await _shot(tester, '14_context_sheet');
  });

  testWidgets('show the math', (tester) async {
    _setPhone(tester);
    final state = AppState();
    await _pumpChild(tester, state: state, tab: 2, childIndex: 2);
    await tester.scrollUntilVisible(
      find.text('Show the math'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show the math'));
    await tester.pumpAndSettle();
    await _shot(tester, '15_show_the_math');
  });

  testWidgets('weekly check-in sheet', (tester) async {
    _setPhone(tester);
    final state = AppState();
    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => showWeeklyCheckInSheet(
                    context,
                    child: state.children.first,
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await _shot(tester, '16_checkin');
  });

  testWidgets('teen trends view', (tester) async {
    _setPhone(tester);
    final state = AppState();
    await _pumpChild(tester, state: state, tab: 1, childIndex: 0);
    await _shot(tester, '17_teen_trends');
  });

  testWidgets('privacy receipt', (tester) async {
    _setPhone(tester);
    final state = AppState();
    await tester.pumpWidget(ParentifyApp(state: state));
    await tester.pumpAndSettle();
    await _signInParent(tester);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Privacy receipt'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Privacy receipt'));
    await tester.pumpAndSettle();
    await _shot(tester, '18_privacy_receipt');
  });

  testWidgets('why changed card', (tester) async {
    _setPhone(tester);
    final state = AppState();
    await _pumpChild(tester, state: state, tab: 2, childIndex: 2);
    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    await _shot(tester, '19_why_changed');
  });

  testWidgets('child together card', (tester) async {
    _setPhone(tester);
    final state = AppState();
    await tester.runAsync(() => state.signInDemoChild(childId: 'ada'));
    await _pumpChild(
      tester,
      state: state,
      tab: 0,
      childIndex: 0,
      childMode: true,
    );
    await _shot(tester, '22_child_together');
  });

  testWidgets('teen trends insights', (tester) async {
    _setPhone(tester);
    final state = AppState();
    await _pumpChild(tester, state: state, tab: 2, childIndex: 0);
    await _shot(tester, '21_trends_insights');
  });

  testWidgets('pending request card', (tester) async {
    _setPhone(tester);
    final state = AppState();
    await tester.pumpWidget(ParentifyApp(state: state));
    await tester.pumpAndSettle();
    await _signInParent(tester);
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -260),
    );
    await tester.pumpAndSettle();
    await _shot(tester, '20_pending_request');
  });
}
