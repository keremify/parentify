import 'package:flutter/widgets.dart';

import '../models/app_usage.dart';
import '../models/child.dart';
import '../models/context_note.dart';
import '../models/user_role.dart';
import '../models/visibility.dart';

part 'copy/common_copy.dart';
part 'copy/parent_home_copy.dart';
part 'copy/child_detail_copy.dart';
part 'copy/sheets_copy.dart';
part 'copy/widgets_copy.dart';
part 'copy/services_copy.dart';
part 'copy/locale_copy.dart';

/// Every piece of user-facing copy in one library.
///
/// Widgets read the active copy with `context.strings`. Standalone widgets and
/// tests that are not wrapped in an [AppStringsScope] fall back to [english],
/// so adding copy here never requires changing how a widget is mounted.
///
/// The getters live in `copy/` mixins grouped by screen or concern. To add a
/// language, subclass [AppStrings], override the getters that differ, and
/// provide that instance through [AppStringsScope] at the root of the app.
/// No screen imports a translated string directly.
class AppStrings
    with
        CommonCopy,
        ParentHomeCopy,
        ChildDetailCopy,
        SheetsCopy,
        WidgetsCopy,
        ServicesCopy,
        LocaleCopy {
  const AppStrings();

  static const AppStrings english = AppStrings();

  static AppStrings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppStringsScope>()?.strings ??
      english;
}

/// Provides an [AppStrings] instance to the widget tree.
class AppStringsScope extends InheritedWidget {
  const AppStringsScope({
    super.key,
    required this.strings,
    required super.child,
  });

  final AppStrings strings;

  @override
  bool updateShouldNotify(AppStringsScope oldWidget) =>
      strings != oldWidget.strings;
}

/// Reads the active copy for the current widget tree.
extension AppStringsBuildContext on BuildContext {
  AppStrings get strings => AppStrings.of(this);
}
