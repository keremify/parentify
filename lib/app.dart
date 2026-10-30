import 'package:flutter/material.dart';

import 'l10n/app_strings.dart';
import 'screens/child_detail_screen.dart';
import 'screens/login_screen.dart';
import 'screens/parent_home_screen.dart';
import 'state/app_scope.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

class ParentifyApp extends StatefulWidget {
  const ParentifyApp({super.key, this.state});

  /// Tests can inject a pre-seeded state.
  final AppState? state;

  @override
  State<ParentifyApp> createState() => _ParentifyAppState();
}

class _ParentifyAppState extends State<ParentifyApp> {
  late final AppState _state = widget.state ?? AppState();
  late final bool _ownsState = widget.state == null;

  @override
  void dispose() {
    if (_ownsState) _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppStringsScope(
      strings: AppStrings.english,
      child: AppScope(
        state: _state,
        child: MaterialApp(
          title: AppStrings.english.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          themeMode: ThemeMode.light,
          home: const _RootGate(),
        ),
      ),
    );
  }
}

class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final activeChild = state.activeChild;

    final Widget screen;
    if (!state.isSignedIn) {
      screen = const LoginScreen();
    } else if (state.isParent) {
      screen = const ParentHomeScreen();
    } else if (activeChild == null) {
      // A child session without a resolvable profile cannot render the child
      // view safely. Return to login instead of crashing the auth gate.
      screen = const LoginScreen();
    } else {
      screen = ChildDetailScreen(child: activeChild, childMode: true);
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(
        key: ValueKey('${state.role}-${state.activeChild?.id}'),
        child: screen,
      ),
    );
  }
}
