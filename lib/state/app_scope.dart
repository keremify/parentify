import 'package:flutter/widgets.dart';

import 'app_state.dart';

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    return scope?.notifier ??
        (throw FlutterError('AppScope was not found above this widget.'));
  }

  static AppState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    return scope?.notifier ??
        (throw FlutterError('AppScope was not found above this widget.'));
  }
}
