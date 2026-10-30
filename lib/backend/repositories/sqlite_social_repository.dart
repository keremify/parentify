import '../../data/demo_social.dart';
import '../../models/agreement.dart';
import '../../models/check_in_record.dart';
import '../../models/context_note.dart';
import '../../models/sync_entry.dart';
import '../../models/visibility.dart';
import '../../repositories/social_repository.dart';
import '../daos/child_dao.dart';
import '../daos/social_dao.dart';
import '../services/cloud_sync_service.dart';

/// SQLite-backed implementation of [SocialRepository].
class SqliteSocialRepository implements SocialRepository {
  const SqliteSocialRepository({
    required this.socialDao,
    required this.childDao,
    this.syncService,
  });

  final SocialDao socialDao;
  final ChildDao childDao;
  final CloudSyncService? syncService;

  @override
  Future<SocialSeed> loadInitialData() async {
    final notes = await socialDao.getContextNotes();
    final agreements = await socialDao.getAgreements();
    final visibility = await childDao.getVisibilityMap();
    final checkIns = await socialDao.getCheckIns();

    return SocialSeed(
      notes: notes,
      agreements: agreements,
      visibility: visibility,
      lastCheckIn: checkIns.isEmpty ? null : checkIns.first,
      parentTodayMinutes: 48,
      parentWeekMinutes: 340,
    );
  }

  @override
  Future<void> addNote(ContextNote note) async {
    await socialDao.addContextNote(note);
    await syncService?.enqueueContextNote(
      note,
      operation: SyncOperation.create,
    );
  }

  @override
  Future<void> deleteNote(String noteId) async {
    await socialDao.deleteContextNote(noteId);
    final now = DateTime.now().toUtc();
    await syncService?.enqueueSync(
      SyncEntry(
        id: 'sync-note-del-$noteId-${now.millisecondsSinceEpoch}',
        entityType: 'context_note',
        entityId: noteId,
        operation: SyncOperation.delete,
        payload: {'id': noteId},
        status: SyncStatus.pending,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<void> saveAgreement(Agreement agreement) async {
    await socialDao.saveAgreement(agreement);
    await syncService?.enqueueAgreement(agreement);
  }

  @override
  Future<void> setVisibility(String childId, VisibilityLevel level) async {
    await childDao.updateVisibility(childId, level);
    await syncService?.enqueueVisibility(childId, level);
  }

  @override
  Future<void> saveCheckIn(CheckInRecord record) async {
    await socialDao.saveCheckIn(record);
    await syncService?.enqueueCheckIn(record);
  }
}
