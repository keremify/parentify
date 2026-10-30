import 'package:flutter_test/flutter_test.dart';

import 'package:parentify/data/demo_data.dart';
import 'package:parentify/data/demo_social.dart';
import 'package:parentify/models/agreement.dart';
import 'package:parentify/services/ai_analyzer_service.dart';
import 'package:parentify/services/change_explainer.dart';

void main() {
  final now = DateTime.now();
  final family = DemoData.build();
  final social = DemoSocial.build(now: now);

  group('Change explainer', () {
    for (final child in family.children) {
      test('${child.name}: app attribution sums to the day delta', () {
        final rows = ChangeExplainer.attribution(child);
        final total = rows.fold<int>(0, (sum, row) => sum + row.minutes);
        expect(total, child.dayOverDay.difference);
      });

      test('${child.name}: every driver carries evidence', () {
        final rows = ChangeExplainer.explainDay(child, limit: 8);
        expect(rows, isNotEmpty);
        for (final row in rows) {
          expect(row.evidence, isNotEmpty);
          expect(row.label, isNotEmpty);
          expect(row.detail, isNotEmpty);
        }
      });

      test('${child.name}: answers are deterministic', () {
        for (final question in InsightQuestion.values) {
          final first = ChangeExplainer.answerFor(child, question);
          final second = ChangeExplainer.answerFor(child, question);
          expect(first, second);
          expect(first, isNotEmpty);
        }
      });
    }

    test('explainDay is capped, ranked and marks context rows', () {
      for (final child in family.children) {
        final rows = ChangeExplainer.explainDay(child);
        expect(rows.length, lessThanOrEqualTo(4));
        for (var index = 1; index < rows.length; index++) {
          expect(
            rows[index - 1].minutes.abs(),
            greaterThanOrEqualTo(rows[index].minutes.abs()),
          );
        }
        final remainder = ChangeExplainer.remainderMinutes(child, rows);
        final attributed = rows
            .where((row) => row.isAttribution)
            .fold<int>(0, (sum, row) => sum + row.minutes);
        expect(attributed + remainder, child.dayOverDay.difference);
      }
    });

    test('app shares stay inside the positive attribution', () {
      for (final child in family.children) {
        final rows = ChangeExplainer.attribution(child);
        for (final row in rows.where((row) => row.isHigher)) {
          expect(row.share, inInclusiveRange(0, 1));
        }
      }
    });
  });

  group('AI report compatibility', () {
    test(
      'local report adds drivers and starters without breaking old fields',
      () {
        final child = family.children.first;
        final report = AiAnalyzerService.buildLocalReport(child, now: now);

        expect(report.headline, isNotEmpty);
        expect(report.observations, isNotEmpty);
        expect(report.suggestions, hasLength(3));
        expect(report.fromModel, isFalse);
        expect(report.drivers, isNotEmpty);
        expect(report.conversationStarters, hasLength(3));
      },
    );

    test('local report remembers the last check-in topic', () {
      final child = family.children.first;
      final report = AiAnalyzerService.buildLocalReport(
        child,
        now: now,
        lastCheckIn: social.lastCheckIn,
      );

      final ritual = report.observations.where(
        (entry) => entry.tag == 'Ritual',
      );
      expect(ritual, isNotEmpty);
      expect(ritual.first.detail, contains('wind-down'));
    });

    test('prompt includes notes, agreement and check-in when provided', () {
      final child = family.children.first;
      final agreement = social.agreements.firstWhere(
        (entry) => entry.status == AgreementStatus.active,
      );
      final prompt = AiAnalyzerService.buildPrompt(
        child,
        notes: social.notes.where((note) => note.childId == child.id).toList(),
        agreement: agreement,
        lastCheckIn: social.lastCheckIn,
      );

      expect(prompt, contains('What moved today'));
      expect(prompt, contains('Context notes'));
      expect(prompt, contains(agreement.title));
      expect(prompt, contains('wind-down'));
      expect(prompt, contains(child.name));
    });

    test('trends summary keeps app names out of the copy', () {
      for (final child in family.children) {
        final full = AiAnalyzerService.buildSummary(child);
        final trends = AiAnalyzerService.buildSummary(
          child,
          includeAppDetail: false,
        );

        expect(full, contains(child.topApp!.name));
        expect(trends, isNot(contains(child.topApp!.name)));
        expect(trends, contains('weekly rhythm'));
      }
    });

    test('trends prompt omits app detail, sessions and family notes', () {
      final child = family.children.first;
      final note = social.notes.firstWhere((note) => note.childId == child.id);
      final prompt = AiAnalyzerService.buildPrompt(
        child,
        notes: social.notes.where((note) => note.childId == child.id).toList(),
        includeAppDetail: false,
      );

      expect(prompt, contains('trends-only'));
      expect(prompt, isNot(contains(child.topApp!.name)));
      expect(prompt, isNot(contains(child.longestSessions.first.label)));
      expect(prompt, isNot(contains(note.text)));
    });

    test('trends local report keeps observations and ideas aggregate', () {
      for (final child in family.children) {
        final report = AiAnalyzerService.buildLocalReport(
          child,
          includeAppDetail: false,
        );
        final suggestionCopy = report.suggestions
            .map((entry) => '${entry.title} ${entry.detail}')
            .join(' ');

        expect(
          report.observations.map((entry) => entry.tag),
          isNot(contains('Apps')),
        );
        expect(report.drivers, isEmpty);
        expect(report.summary, isNot(contains(child.topApp!.name)));
        expect(suggestionCopy, isNot(contains(child.topApp!.name)));
      }
    });

    test('prompt still works with only a child', () {
      final prompt = AiAnalyzerService.buildPrompt(family.children[1]);
      expect(prompt, contains('No context notes yet.'));
      expect(prompt, contains('No active family agreement.'));
      expect(prompt, contains('No family check-in recorded yet'));
    });
  });
}
