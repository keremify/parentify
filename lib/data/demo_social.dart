import '../models/agreement.dart';
import '../models/check_in_record.dart';
import '../models/context_note.dart';
import '../models/user_role.dart';
import '../models/visibility.dart';
import '../utils/clock.dart';
import '../utils/dates.dart';

/// The social layer that sits on top of the generated device data: notes,
/// agreements, sharing levels and the last family check-in.
class SocialSeed {
  const SocialSeed({
    required this.notes,
    required this.agreements,
    required this.visibility,
    required this.lastCheckIn,
    required this.parentTodayMinutes,
    required this.parentWeekMinutes,
  });

  final List<ContextNote> notes;
  final List<Agreement> agreements;
  final Map<String, VisibilityLevel> visibility;
  final CheckInRecord? lastCheckIn;
  final int parentTodayMinutes;
  final int parentWeekMinutes;
}

abstract final class DemoSocial {
  static SocialSeed buildSingleChild({DateTime? now}) {
    final reference = now ?? AppClock.now();

    return SocialSeed(
      notes: [
        ContextNote(
          id: 'note-leo-1',
          childId: 'leo',
          createdAt: reference.subtract(const Duration(hours: 3)),
          author: UserRole.child,
          tag: NoteTag.school,
          text: 'Watched Spanish tutorial videos for homework project.',
          scope: NoteScope.day,
        ),
        ContextNote(
          id: 'note-leo-2',
          childId: 'leo',
          createdAt: addDays(reference, -1).subtract(const Duration(hours: 2)),
          author: UserRole.parent,
          tag: NoteTag.family,
          text: 'Family movie night; put screens away early.',
          scope: NoteScope.day,
        ),
      ],
      agreements: [
        Agreement(
          id: 'agr-leo-1',
          childId: 'leo',
          kind: AgreementKind.bedtime,
          title: 'Screens away by 8:30 PM',
          detail: 'Device stays on the hallway charger before lights out.',
          status: AgreementStatus.active,
          proposedBy: UserRole.parent,
          createdAt: addDays(reference, -5),
          responseNote: 'Agreed together on Sunday.',
        ),
        Agreement(
          id: 'agr-leo-2',
          childId: 'leo',
          kind: AgreementKind.flexDay,
          title: 'Saturday extra Minecraft with friends',
          detail:
              'Add 45 minutes on Saturday after finishing science homework.',
          status: AgreementStatus.proposed,
          proposedBy: UserRole.child,
          createdAt: reference.subtract(const Duration(hours: 4)),
        ),
      ],
      visibility: const {'leo': VisibilityLevel.guided},
      lastCheckIn: CheckInRecord(
        childId: 'leo',
        weekStart: addDays(startOfWeek(reference), -7),
        topic: 'Digital balance & sleep quality',
        question: 'How refreshed did you feel in the mornings this week?',
        completedAt: addDays(reference, -6),
      ),
      parentTodayMinutes: 48,
      parentWeekMinutes: 340,
    );
  }

  static SocialSeed build({DateTime? now}) {
    final reference = now ?? AppClock.now();

    return SocialSeed(
      notes: [
        ContextNote(
          id: 'note-ada-session',
          childId: 'ada',
          createdAt: addDays(reference, -1).subtract(const Duration(hours: 3)),
          author: UserRole.child,
          tag: NoteTag.friends,
          text:
              'Group chat ran long after practice — catching up with the team.',
          scope: NoteScope.session,
          targetId: 'ada-session-0',
        ),
        ContextNote(
          id: 'note-ada-sleep',
          childId: 'ada',
          createdAt: addDays(reference, -1).subtract(const Duration(hours: 1)),
          author: UserRole.parent,
          tag: NoteTag.sleep,
          text: 'The late bit was a school-trip group chat, not scrolling.',
          scope: NoteScope.day,
        ),
        ContextNote(
          id: 'note-mert-day',
          childId: 'mert',
          createdAt: reference.subtract(const Duration(hours: 2)),
          author: UserRole.child,
          tag: NoteTag.friends,
          text: 'Roblox tournament with classmates — we made the final.',
          scope: NoteScope.day,
        ),
        ContextNote(
          id: 'note-mert-roblox',
          childId: 'mert',
          createdAt: addDays(reference, -2),
          author: UserRole.child,
          tag: NoteTag.friends,
          text: 'New season dropped this week; the squad plays after homework.',
          scope: NoteScope.app,
          targetId: 'roblox',
        ),
        ContextNote(
          id: 'note-zeynep-learning',
          childId: 'zeynep',
          createdAt: addDays(reference, -1).subtract(const Duration(hours: 5)),
          author: UserRole.child,
          tag: NoteTag.family,
          text: 'Read-along with mum before bed.',
          scope: NoteScope.app,
          targetId: 'khan-academy',
        ),
      ],
      agreements: [
        Agreement(
          id: 'agreement-ada-bedtime',
          childId: 'ada',
          kind: AgreementKind.bedtime,
          title: 'Devices in the kitchen by 10:00 PM',
          detail: 'Chargers live in the kitchen. Any app is fine until then.',
          status: AgreementStatus.active,
          proposedBy: UserRole.parent,
          createdAt: addDays(reference, -14),
        ),
        Agreement(
          id: 'agreement-zeynep-learning',
          childId: 'zeynep',
          kind: AgreementKind.appWindow,
          title: 'Learning apps are always allowed',
          detail:
              'Khan Academy and Duolingo do not count toward weekend limits.',
          status: AgreementStatus.active,
          proposedBy: UserRole.parent,
          createdAt: addDays(reference, -21),
        ),
        Agreement(
          id: 'agreement-mert-request',
          childId: 'mert',
          kind: AgreementKind.flexDay,
          title: '30 more minutes on Saturday',
          detail: 'Roblox tournament with classmates — we made the final.',
          status: AgreementStatus.proposed,
          proposedBy: UserRole.child,
          createdAt: reference.subtract(const Duration(hours: 2)),
        ),
        Agreement(
          id: 'agreement-ada-declined',
          childId: 'ada',
          kind: AgreementKind.dailyCap,
          title: 'An extra hour on a school night',
          detail: 'Wanted to finish a series with friends.',
          status: AgreementStatus.declined,
          proposedBy: UserRole.child,
          createdAt: addDays(reference, -9),
          responseNote:
              'Let\'s keep school nights steady and revisit on Friday.',
        ),
      ],
      visibility: const {
        'ada': VisibilityLevel.trends,
        'mert': VisibilityLevel.guided,
        'zeynep': VisibilityLevel.full,
      },
      lastCheckIn: CheckInRecord(
        childId: 'ada',
        weekStart: addDays(startOfWeek(reference), -7),
        topic: 'wind-down',
        question: 'What would make the last 30 minutes of the day feel calmer?',
        completedAt: addDays(reference, -6),
      ),
      parentTodayMinutes: 96,
      parentWeekMinutes: 714,
    );
  }
}
