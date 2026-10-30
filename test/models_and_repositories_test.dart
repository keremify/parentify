import 'package:flutter/material.dart' show Color, Icons;
import 'package:flutter_test/flutter_test.dart';
import 'package:parentify/models/agreement.dart';
import 'package:parentify/models/app_usage.dart';
import 'package:parentify/models/check_in_record.dart';
import 'package:parentify/models/child.dart';
import 'package:parentify/models/context_note.dart';
import 'package:parentify/models/user_role.dart';
import 'package:parentify/models/visibility.dart';
import 'package:parentify/repositories/family_repository.dart';
import 'package:parentify/repositories/social_repository.dart';
import 'package:parentify/services/auth_service.dart';

void main() {
  group('Models Serialization and Equality', () {
    test('Agreement round-trips through JSON', () {
      final agreement = Agreement(
        id: 'agr-1',
        childId: 'child-1',
        kind: AgreementKind.bedtime,
        title: 'Bedtime limit',
        detail: 'No phone after 9 PM',
        status: AgreementStatus.active,
        proposedBy: UserRole.parent,
        createdAt: DateTime.utc(2026, 1, 1, 10, 0),
      );

      final json = agreement.toJson();
      final revived = Agreement.fromJson(json);

      expect(revived, equals(agreement));
      expect(revived.id, 'agr-1');
      expect(revived.childId, 'child-1');
      expect(revived.status, AgreementStatus.active);
      expect(revived.proposedBy, UserRole.parent);
    });

    test('ContextNote round-trips through JSON', () {
      final note = ContextNote(
        id: 'note-1',
        childId: 'child-1',
        createdAt: DateTime.utc(2026, 1, 2, 12, 0),
        author: UserRole.parent,
        tag: NoteTag.school,
        text: 'Studied for math exam',
        scope: NoteScope.day,
        targetId: 'target-1',
      );

      final json = note.toJson();
      final revived = ContextNote.fromJson(json);

      expect(revived, equals(note));
      expect(revived.scope, NoteScope.day);
      expect(revived.author, UserRole.parent);
      expect(revived.targetId, 'target-1');
    });

    test('CheckInRecord round-trips through JSON', () {
      final record = CheckInRecord(
        childId: 'child-1',
        weekStart: DateTime.utc(2026, 1, 1),
        topic: 'Digital Wellness',
        question: 'How do you feel about screen time?',
        completedAt: DateTime.utc(2026, 1, 3, 18, 0),
      );

      final json = record.toJson();
      final revived = CheckInRecord.fromJson(json);

      expect(revived, equals(record));
      expect(revived.topic, 'Digital Wellness');
      expect(revived.childId, 'child-1');
    });

    test('UsageApp round-trips through JSON', () {
      final app = UsageApp(
        id: 'app-1',
        name: 'Duolingo',
        category: AppCategory.education,
        icon: Icons.school,
        color: const Color(0xFF5B67CA),
        last7Days: const [10, 20, 30, 40, 50, 60, 45],
        launchesToday: 4,
      );

      final json = app.toJson();
      final revived = UsageApp.fromJson(json);

      expect(revived, equals(app));
      expect(revived.category, AppCategory.education);
      expect(revived.last7Days, equals([10, 20, 30, 40, 50, 60, 45]));
      expect(revived.launchesToday, 4);
    });

    test('Child and child sub-models round-trip through JSON', () {
      final session = UsageSession(
        id: 'sess-1',
        start: DateTime.utc(2026, 1, 1, 14, 0),
        minutes: 30,
        label: 'Duolingo study',
        category: AppCategory.education,
        apps: const ['Duolingo'],
      );
      final dailyUsage = DailyUsage(
        date: DateTime.utc(2026, 1, 1),
        minutes: 120,
        unlocks: 15,
      );

      final child = Child(
        id: 'child-1',
        name: 'Mert',
        age: 10,
        deviceName: 'iPhone',
        platform: DevicePlatform.ios,
        accent: const Color(0xFF5B67CA),
        apps: [
          UsageApp(
            id: 'app-1',
            name: 'Duolingo',
            category: AppCategory.education,
            icon: Icons.school,
            color: const Color(0xFF5B67CA),
            last7Days: const [10, 20, 30, 40, 50, 60, 45],
            launchesToday: 4,
          ),
        ],
        days: [dailyUsage],
        hourlyToday: List.filled(24, 5),
        sessions: [session],
        unlocksToday: 20,
        notificationsToday: 12,
        lastSyncedAt: DateTime.utc(2026, 1, 1, 20, 0),
      );

      final json = child.toJson();
      final revived = Child.fromJson(json);

      expect(revived.id, child.id);
      expect(revived.name, 'Mert');
      expect(revived.age, 10);
      expect(revived.sessions.length, 1);
      expect(revived.sessions.first.label, 'Duolingo study');
      expect(revived.days.length, 1);
      expect(revived.apps.length, 1);
      expect(revived, equals(child));
    });

    test('AuthSession serializes role, identity and childId only', () {
      const session = AuthSession(
        role: UserRole.child,
        identity: 'mert',
        childId: 'mert',
      );

      final json = session.toJson();
      final revived = AuthSession.fromJson(json);

      expect(revived.role, UserRole.child);
      expect(revived.identity, 'mert');
      expect(revived.childId, 'mert');
      expect(json.containsKey('token'), isFalse);
      expect(json.containsKey('expiresAt'), isFalse);
    });
  });

  group('Repositories', () {
    test(
      'DemoFamilyRepository returns seed family and finds child by id',
      () async {
        final repo = DemoFamilyRepository();
        final family = await repo.getFamily();
        expect(family.children.length, greaterThanOrEqualTo(2));

        final mert = await repo.getChildById('mert');
        expect(mert, isNotNull);
        expect(mert!.name, 'Mert');

        final unknown = await repo.getChildById('non-existent');
        expect(unknown, isNull);
      },
    );

    test('DemoSocialRepository loads initial data and executes mutations without error', () async {
      final repo = DemoSocialRepository();
      final seed = await repo.loadInitialData();
      expect(seed.notes, isNotEmpty);
      expect(seed.agreements, isNotEmpty);

      final newNote = ContextNote(
        id: 'new-note',
        childId: 'mert',
        createdAt: DateTime.now(),
        author: UserRole.parent,
        tag: NoteTag.other,
        text: 'Guitar practice',
        scope: NoteScope.day,
      );
      await expectLater(repo.addNote(newNote), completes);
      await expectLater(repo.deleteNote('new-note'), completes);

      final agreement = Agreement(
        id: 'new-agr',
        childId: 'mert',
        kind: AgreementKind.dailyCap,
        title: 'Weekend Gaming',
        detail: '2 hours max on Saturday',
        status: AgreementStatus.proposed,
        proposedBy: UserRole.child,
        createdAt: DateTime.now(),
      );
      await expectLater(repo.saveAgreement(agreement), completes);
      await expectLater(
        repo.setVisibility('mert', VisibilityLevel.trends),
        completes,
      );

      final record = CheckInRecord(
        childId: 'mert',
        weekStart: DateTime.now(),
        topic: 'Screen time',
        question: 'How did it go?',
        completedAt: DateTime.now(),
      );
      await expectLater(repo.saveCheckIn(record), completes);
    });
  });
}
