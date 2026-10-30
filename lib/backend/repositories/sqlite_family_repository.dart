import '../../data/demo_data.dart';
import '../../models/app_usage.dart';
import '../../models/child.dart';
import '../../models/sync_entry.dart';
import '../../repositories/family_repository.dart';
import '../daos/child_dao.dart';
import '../daos/user_dao.dart';
import '../services/cloud_sync_service.dart';

/// SQLite-backed implementation of [FamilyRepository].
class SqliteFamilyRepository implements FamilyRepository {
  const SqliteFamilyRepository({
    required this.userDao,
    required this.childDao,
    this.syncService,
  });

  final UserDao userDao;
  final ChildDao childDao;
  final CloudSyncService? syncService;

  @override
  Future<DemoFamily> getFamily() async {
    final meta = await userDao.getFamilyMeta();
    final children = await childDao.getAllChildren();

    return DemoFamily(
      parentName: meta?['parentName'] ?? 'Sarah',
      parentEmail: meta?['parentEmail'] ?? 'parent@parentify.dev',
      familyName: meta?['familyName'] ?? 'Miller Family',
      children: children,
    );
  }

  @override
  Future<Child?> getChildById(String id) async {
    return childDao.getChildById(id);
  }

  @override
  Future<void> recordAppLaunch(String childId, String appId) async {
    await childDao.recordAppLaunch(childId, appId);
    await syncService?.enqueueAppLaunch(childId, appId);
  }

  @override
  Future<void> updateAppCategory(
    String childId,
    String appId,
    AppCategory category,
  ) async {
    await childDao.updateAppCategory(childId, appId, category);
    await syncService?.enqueueAppCategory(childId, appId, category);
  }

  @override
  Future<void> recordDailyUsage(String childId, DailyUsage usage) async {
    await childDao.recordDailyUsage(childId, usage);
    final now = DateTime.now().toUtc();
    await syncService?.enqueueSync(
      SyncEntry(
        id: 'sync-usage-$childId-${now.millisecondsSinceEpoch}',
        entityType: 'daily_usage',
        entityId: childId,
        operation: SyncOperation.create,
        payload: {
          'child_id': childId,
          'date': usage.date.toIso8601String(),
          'minutes': usage.minutes,
          'unlocks': usage.unlocks,
        },
        status: SyncStatus.pending,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<void> recordUsageSession(String childId, UsageSession session) async {
    await childDao.recordUsageSession(childId, session);
    await syncService?.enqueueUsageSession(childId, session);
  }

  @override
  Future<void> updateChildMetrics(
    String childId, {
    int? unlocksToday,
    int? notificationsToday,
    DateTime? lastSyncedAt,
  }) async {
    await childDao.updateChildMetrics(
      childId,
      unlocksToday: unlocksToday,
      notificationsToday: notificationsToday,
      lastSyncedAt: lastSyncedAt,
    );
    await syncService?.enqueueChildMetrics(
      childId,
      unlocksToday: unlocksToday,
      notificationsToday: notificationsToday,
      lastSyncedAt: lastSyncedAt,
    );
  }

  @override
  Future<void> saveChild(Child child) async {
    await childDao.saveChild(child);
    final now = DateTime.now().toUtc();
    await syncService?.enqueueSync(
      SyncEntry(
        id: 'sync-child-${child.id}-${now.millisecondsSinceEpoch}',
        entityType: 'child',
        entityId: child.id,
        operation: SyncOperation.update,
        payload: {
          'child_id': child.id,
          'name': child.name,
          'age': child.age,
          'device_name': child.deviceName,
          'platform': child.platform.name,
        },
        status: SyncStatus.pending,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}
