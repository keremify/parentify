import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parentify/l10n/app_strings.dart';
import 'package:parentify/main.dart';

void main() {
  testWidgets(
    'BootFailureApp explains a failed bootstrap instead of a blank screen',
    (tester) async {
      await tester.pumpWidget(const BootFailureApp());
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.text(AppStrings.english.somethingWentWrong), findsOneWidget);
      expect(find.text(AppStrings.english.appErrorBody), findsOneWidget);
    },
  );
}
