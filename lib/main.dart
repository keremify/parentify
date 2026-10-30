import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'backend/database/app_database.dart';
import 'config/env.dart';
import 'l10n/app_strings.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'widgets/app_error_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // A demo should fail calmly. Build failures render a friendly explanation
  // instead of the red box, and unhandled async errors are logged rather than
  // taking the process down. There is no telemetry and nothing is uploaded.
  ErrorWidget.builder = (_) => const AppErrorView();
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Parentify unhandled error: $error');
    return true;
  };

  await AppEnv.load();
  AppDatabase.initFfiIfNeeded();

  final AppState appState;
  try {
    appState = await AppState.createFromSqlite();
  } catch (error, stack) {
    // A corrupt database file, a full disk, or a missing FFI factory used to
    // reach runApp with nothing to show and leave a black screen. Render the
    // same calm explanation the widget tree uses instead.
    debugPrint('Parentify bootstrap failed: $error\n$stack');
    runApp(const BootFailureApp());
    return;
  }

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFFF7F4EE),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(ParentifyApp(state: appState));
}

/// Shown when the local database cannot be opened during bootstrap.
///
/// Kept as its own widget so the fallback can be widget-tested without
/// simulating a database failure.
class BootFailureApp extends StatelessWidget {
  const BootFailureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppStringsScope(
      strings: AppStrings.english,
      child: MaterialApp(
        title: AppStrings.english.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const Scaffold(body: SafeArea(child: AppErrorView())),
      ),
    );
  }
}
