import 'package:flutter_test/flutter_test.dart';

import 'package:parentify/data/demo_credentials.dart';
import 'package:parentify/data/demo_data.dart';
import 'package:parentify/data/demo_social.dart';
import 'package:parentify/models/agreement.dart';
import 'package:parentify/models/check_in_record.dart';
import 'package:parentify/models/context_note.dart';
import 'package:parentify/models/visibility.dart';
import 'package:parentify/services/auth_service.dart';
import 'package:parentify/state/app_state.dart';

AppState _state() {
  final now = DateTime.now();
  return AppState(
    family: DemoData.build(),
    social: DemoSocial.build(now: now),
    auth: DemoAuthService(latency: Duration.zero),
  );
}

Future<bool> _signInParent(AppState state) => state.signInParent(
  email: state.parentEmail,
  password: DemoCredentials.instance.parentPassword,
);

Future<bool> _signInChild(AppState state, String childId) =>
    state.signInChild(childId: childId, pin: DemoCredentials.instance.childPin);

DateTime _weekStart(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  return day.subtract(Duration(days: day.weekday - 1));
}

Agreement _request({
  required UserRole proposedBy,
  String id = 'agreement-test',
  String childId = 'mert',
}) {
  return Agreement(
    id: id,
    childId: childId,
    kind: AgreementKind.flexDay,
    title: '30 more minutes on Saturday',
    detail: 'A tournament with classmates.',
    status: AgreementStatus.proposed,
    proposedBy: proposedBy,
    createdAt: DateTime.now(),
  );
}

void main() {
  group('Social state', () {
    test('seeds notes, agreements, visibility and a check-in', () {
      final state = _state();

      expect(state.notesFor('ada'), isNotEmpty);
      expect(state.notesFor('mert'), isNotEmpty);
      expect(state.notesFor('zeynep'), isNotEmpty);
      expect(state.agreementsFor('ada').any((entry) => entry.isActive), isTrue);
      expect(state.pendingRequests, hasLength(1));
      expect(state.pendingRequestFor('mert')?.title, contains('Saturday'));
      expect(state.latestDeclinedFor('ada')?.responseNote, isNotNull);
      expect(state.visibilityFor('ada'), VisibilityLevel.trends);
      expect(state.visibilityFor('mert'), VisibilityLevel.guided);
      expect(state.visibilityFor('zeynep'), VisibilityLevel.full);
      expect(state.visibilityFor('unknown-child'), VisibilityLevel.trends);
      expect(state.lastCheckIn?.topic, 'wind-down');
    });

    test('adds a context note and resolves it by scope', () {
      final state = _state();
      final note = ContextNote(
        id: 'note-test',
        childId: 'mert',
        createdAt: DateTime.now(),
        author: UserRole.child,
        tag: NoteTag.school,
        text: 'Homework ran late.',
        scope: NoteScope.session,
        targetId: 'mert-session-0',
      );

      state.addContextNote(note);

      expect(state.notesFor('mert').first.id, 'note-test');
      expect(
        state.noteForSession('mert', 'mert-session-0')?.text,
        'Homework ran late.',
      );
      expect(
        state.dayNotesFor('mert').any((entry) => entry.id == 'note-test'),
        isFalse,
      );
    });

    test('app and session note lookups stay inside one child', () {
      final state = _state();
      final now = DateTime.now();

      state.addContextNote(
        ContextNote(
          id: 'note-ada-app',
          childId: 'ada',
          createdAt: now,
          author: UserRole.parent,
          tag: NoteTag.school,
          text: 'Ada app note',
          scope: NoteScope.app,
          targetId: 'shared-target',
        ),
      );
      state.addContextNote(
        ContextNote(
          id: 'note-mert-app',
          childId: 'mert',
          createdAt: now,
          author: UserRole.parent,
          tag: NoteTag.school,
          text: 'Mert app note',
          scope: NoteScope.app,
          targetId: 'shared-target',
        ),
      );
      state.addContextNote(
        ContextNote(
          id: 'note-ada-session',
          childId: 'ada',
          createdAt: now,
          author: UserRole.parent,
          tag: NoteTag.school,
          text: 'Ada session note',
          scope: NoteScope.session,
          targetId: 'shared-session',
        ),
      );

      expect(state.notesForApp('ada', 'shared-target').map((note) => note.id), [
        'note-ada-app',
      ]);
      expect(
        state.notesForApp('mert', 'shared-target').map((note) => note.id),
        ['note-mert-app'],
      );
      expect(state.notesForApp('zeynep', 'shared-target'), isEmpty);
      expect(
        state.noteForSession('ada', 'shared-session')?.id,
        'note-ada-session',
      );
      expect(state.noteForSession('mert', 'shared-session'), isNull);
    });

    test('child proposes and parent approves across sign-ins', () async {
      final state = _state();
      await _signInChild(state, 'mert');

      final proposed = _request(proposedBy: UserRole.child);
      expect(state.proposeAgreement(proposed), isTrue);
      expect(state.pendingRequestFor('mert')?.id, 'agreement-test');

      state.signOut();
      await _signInParent(state);

      expect(
        state.respondToAgreement('agreement-test', AgreementStatus.active),
        isTrue,
      );
      expect(state.activeAgreementFor('mert')?.id, 'agreement-test');
      expect(
        state.pendingRequests.any((entry) => entry.id == 'agreement-test'),
        isFalse,
      );
    });

    test('parent decline keeps the history and the reply', () async {
      final state = _state();
      await _signInParent(state);

      final declined = state.respondToAgreement(
        'agreement-mert-request',
        AgreementStatus.declined,
        note: 'Let us try Saturday morning instead.',
      );

      expect(declined, isTrue);
      expect(state.pendingRequests, isEmpty);
      final report = state.latestDeclinedFor('mert');
      expect(report?.status, AgreementStatus.declined);
      expect(report?.responseNote, 'Let us try Saturday morning instead.');
    });

    test('guards role-specific mutations', () async {
      final state = _state();
      await _signInChild(state, 'mert');

      expect(
        state.proposeAgreement(_request(proposedBy: UserRole.parent)),
        isFalse,
      );
      expect(
        state.proposeAgreement(
          _request(
            id: 'agreement-other',
            childId: 'ada',
            proposedBy: UserRole.child,
          ),
        ),
        isFalse,
      );
      state.addContextNote(
        ContextNote(
          id: 'note-other-child',
          childId: 'ada',
          createdAt: DateTime.now(),
          author: UserRole.child,
          tag: NoteTag.other,
          text: 'Not mine to write.',
          scope: NoteScope.day,
        ),
      );
      expect(
        state.notesFor('ada').any((entry) => entry.id == 'note-other-child'),
        isFalse,
      );
      expect(
        state.respondToAgreement(
          'agreement-mert-request',
          AgreementStatus.active,
        ),
        isFalse,
      );
      expect(state.setVisibility('mert', VisibilityLevel.full), isFalse);

      state.signOut();
      await _signInParent(state);

      expect(
        state.proposeAgreement(_request(proposedBy: UserRole.child)),
        isFalse,
      );
      expect(state.setVisibility('mert', VisibilityLevel.full), isTrue);
      expect(state.visibilityFor('mert'), VisibilityLevel.full);
    });

    test('check-ins persist, keep a streak and replace the same week', () {
      final state = _state();
      final seeded = state.lastCheckIn;
      expect(seeded?.topic, 'wind-down');
      expect(state.checkInStreak, 1);

      final first = CheckInRecord(
        childId: 'mert',
        weekStart: _weekStart(DateTime.now()),
        topic: 'gaming',
        question: 'What made the tournament fun?',
        completedAt: DateTime.now(),
      );
      state.completeCheckIn(first);

      expect(state.lastCheckIn?.topic, 'gaming');
      expect(state.checkInHistory, hasLength(2));
      expect(state.checkInStreak, 2);

      final updated = CheckInRecord(
        childId: 'mert',
        weekStart: _weekStart(DateTime.now()),
        topic: 'friendship',
        question: 'Who did you play with?',
        completedAt: DateTime.now(),
      );
      state.completeCheckIn(updated);

      expect(state.checkInHistory, hasLength(2));
      expect(state.lastCheckIn?.topic, 'friendship');
    });

    test('only a parent can save the AI key', () async {
      final state = _state();
      await _signInChild(state, 'mert');

      final problem = state.saveApiKey('AIzaSyDemoKeyForTestsOnly1234567890');

      expect(problem, isNotEmpty);
      expect(state.ai.apiKey, isNull);
    });

    test('sign out clears the in-memory AI key', () async {
      final state = _state();
      await _signInParent(state);
      expect(state.saveApiKey('AIzaSyDemoKeyForTestsOnly1234567890'), isNull);
      expect(state.ai.apiKey, isNotNull);

      state.signOut();

      expect(state.ai.apiKey, isNull);
    });

    test('reset re-seeds social state and clears the session', () async {
      final state = _state();
      await _signInParent(state);
      state.saveApiKey('AIzaSyDemoKeyForTestsOnly1234567890');
      state.addContextNote(
        ContextNote(
          id: 'note-reset',
          childId: 'ada',
          createdAt: DateTime.now(),
          author: UserRole.parent,
          tag: NoteTag.other,
          text: 'Temporary.',
          scope: NoteScope.day,
        ),
      );
      state.setVisibility('ada', VisibilityLevel.full);
      expect(
        state.notesFor('ada').any((entry) => entry.id == 'note-reset'),
        isTrue,
      );

      await state.resetDemoData();

      expect(state.role, isNull);
      expect(state.ai.apiKey, isNull);
      expect(
        state.notesFor('ada').any((entry) => entry.id == 'note-reset'),
        isFalse,
      );
      expect(state.visibilityFor('ada'), VisibilityLevel.trends);
      expect(state.pendingRequests, hasLength(1));
    });
  });
}
