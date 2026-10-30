import 'package:sqflite/sqflite.dart';

import '../../models/agreement.dart';
import '../../models/check_in_record.dart';
import '../../models/context_note.dart';
import '../../models/user_role.dart';

class SocialDao {
  const SocialDao(this.db);

  final Database db;

  // --- Agreements ---

  Future<List<Agreement>> getAgreements() async {
    final rows = await db.query('agreements', orderBy: 'created_at DESC');
    return [
      for (final r in rows)
        Agreement(
          id: r['id'] as String,
          childId: r['child_id'] as String,
          kind: AgreementKind.values.firstWhere(
            (k) => k.name == r['kind'],
            orElse: () => AgreementKind.dailyCap,
          ),
          title: r['title'] as String,
          detail: r['detail'] as String,
          status: AgreementStatus.values.firstWhere(
            (s) => s.name == r['status'],
            orElse: () => AgreementStatus.proposed,
          ),
          proposedBy: UserRole.values.firstWhere(
            (u) => u.name == r['proposed_by'],
            orElse: () => UserRole.child,
          ),
          createdAt: DateTime.parse(r['created_at'] as String),
          responseNote: r['response_note'] as String?,
        ),
    ];
  }

  Future<void> saveAgreement(Agreement agreement) async {
    await db.insert('agreements', {
      'id': agreement.id,
      'child_id': agreement.childId,
      'kind': agreement.kind.name,
      'title': agreement.title,
      'detail': agreement.detail,
      'status': agreement.status.name,
      'proposed_by': agreement.proposedBy.name,
      'created_at': agreement.createdAt.toIso8601String(),
      'response_note': agreement.responseNote,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- Context Notes ---

  Future<List<ContextNote>> getContextNotes() async {
    final rows = await db.query('context_notes', orderBy: 'created_at DESC');
    return [
      for (final r in rows)
        ContextNote(
          id: r['id'] as String,
          childId: r['child_id'] as String,
          createdAt: DateTime.parse(r['created_at'] as String),
          author: UserRole.values.firstWhere(
            (a) => a.name == r['author'],
            orElse: () => UserRole.parent,
          ),
          tag: NoteTag.values.firstWhere(
            (t) => t.name == r['tag'],
            orElse: () => NoteTag.other,
          ),
          text: r['text'] as String,
          scope: NoteScope.values.firstWhere(
            (s) => s.name == r['scope'],
            orElse: () => NoteScope.day,
          ),
          targetId: r['target_id'] as String?,
        ),
    ];
  }

  Future<void> addContextNote(ContextNote note) async {
    await db.insert('context_notes', {
      'id': note.id,
      'child_id': note.childId,
      'created_at': note.createdAt.toIso8601String(),
      'author': note.author.name,
      'tag': note.tag.name,
      'text': note.text,
      'scope': note.scope.name,
      'target_id': note.targetId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteContextNote(String id) async {
    await db.delete('context_notes', where: 'id = ?', whereArgs: [id]);
  }

  // --- Check-Ins ---

  Future<List<CheckInRecord>> getCheckIns() async {
    final rows = await db.query(
      'check_in_records',
      orderBy: 'completed_at DESC',
    );
    return [
      for (final r in rows)
        CheckInRecord(
          childId: r['child_id'] as String,
          weekStart: DateTime.parse(r['week_start'] as String),
          topic: r['topic'] as String,
          question: r['question'] as String,
          completedAt: DateTime.parse(r['completed_at'] as String),
        ),
    ];
  }

  Future<void> saveCheckIn(CheckInRecord record) async {
    final id =
        'checkin-${record.childId}-${record.weekStart.millisecondsSinceEpoch}';
    await db.insert('check_in_records', {
      'id': id,
      'child_id': record.childId,
      'week_start': record.weekStart.toIso8601String(),
      'topic': record.topic,
      'question': record.question,
      'completed_at': record.completedAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
