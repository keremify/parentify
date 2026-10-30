import 'dart:async';

import '../../models/agreement.dart';
import '../../models/app_usage.dart';
import '../../models/check_in_record.dart';
import '../../models/child.dart';
import '../../models/context_note.dart';
import '../../models/sync_entry.dart';
import '../../models/visibility.dart';
import '../daos/sync_queue_dao.dart';

/// Summary of a synchronization operation batch.
class SyncResult {
  const SyncResult({
    required this.processedCount,
    required this.successCount,
    required this.failedCount,
    required this.isOffline,
  });

  final int processedCount;
  final int successCount;
  final int failedCount;
  final bool isOffline;

  bool get hasErrors => failedCount > 0;
  bool get isClean => successCount == processedCount && !isOffline;
}

/// Abstract contract for cloud backend synchronization.
abstract interface class CloudSyncService {
  bool get isOnline;
  set isOnline(bool value);
  Future<void> enqueueSync(SyncEntry entry);
  Future<void> enqueueAgreement(
    Agreement agreement, {
    SyncOperation operation = SyncOperation.update,
  });
  Future<void> enqueueContextNote(
    ContextNote note, {
    SyncOperation operation = SyncOperation.create,
  });
  Future<void> enqueueVisibility(String childId, VisibilityLevel level);
  Future<void> enqueueCheckIn(CheckInRecord record);
  Future<void> enqueueAppLaunch(String childId, String appId);
  Future<void> enqueueAppCategory(
    String childId,
    String appId,
    AppCategory category,
  );
  Future<void> enqueueUsageSession(String childId, UsageSession session);
  Future<void> enqueueChildMetrics(
    String childId, {
    int? unlocksToday,
    int? notificationsToday,
    DateTime? lastSyncedAt,
  });
  Future<SyncResult> syncPending();
  Future<int> getPendingCount();
}

/// Simulated cloud backend sync client demonstrating production offline-first sync.
///
/// Simulates remote API endpoints (e.g. Supabase, Firebase, or custom GraphQL/REST)
/// with realistic latency, idempotency handling, and simulated offline connectivity.
class SimulatedCloudSyncService implements CloudSyncService {
  SimulatedCloudSyncService({
    required this.syncQueueDao,
    this.isOnline = true,
    this.simulatedLatency = const Duration(milliseconds: 60),
  });

  final SyncQueueDao syncQueueDao;
  final Duration simulatedLatency;

  @override
  bool isOnline;
  Future<SyncResult>? _inFlightSync;

  bool get isSyncing => _inFlightSync != null;

  @override
  Future<void> enqueueSync(SyncEntry entry) => syncQueueDao.enqueue(entry);

  @override
  Future<int> getPendingCount() => syncQueueDao.getPendingCount();

  /// Enqueues an agreement change for cloud sync.
  @override
  Future<void> enqueueAgreement(
    Agreement agreement, {
    SyncOperation operation = SyncOperation.update,
  }) {
    final now = DateTime.now().toUtc();
    return enqueueSync(
      SyncEntry(
        id: 'sync-agreement-${agreement.id}-${now.millisecondsSinceEpoch}',
        entityType: 'agreement',
        entityId: agreement.id,
        operation: operation,
        payload: {
          'id': agreement.id,
          'child_id': agreement.childId,
          'kind': agreement.kind.name,
          'title': agreement.title,
          'detail': agreement.detail,
          'status': agreement.status.name,
          'proposed_by': agreement.proposedBy.name,
          'created_at': agreement.createdAt.toIso8601String(),
          'response_note': agreement.responseNote,
        },
        status: SyncStatus.pending,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  /// Enqueues a context note addition or deletion for cloud sync.
  @override
  Future<void> enqueueContextNote(
    ContextNote note, {
    SyncOperation operation = SyncOperation.create,
  }) {
    final now = DateTime.now().toUtc();
    return enqueueSync(
      SyncEntry(
        id: 'sync-note-${note.id}-${now.millisecondsSinceEpoch}',
        entityType: 'context_note',
        entityId: note.id,
        operation: operation,
        payload: {
          'id': note.id,
          'child_id': note.childId,
          'author': note.author.name,
          'tag': note.tag.name,
          'text': note.text,
          'scope': note.scope.name,
          'target_id': note.targetId,
          'created_at': note.createdAt.toIso8601String(),
        },
        status: SyncStatus.pending,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  /// Enqueues a visibility sharing level change for cloud sync.
  @override
  Future<void> enqueueVisibility(String childId, VisibilityLevel level) {
    final now = DateTime.now().toUtc();
    return enqueueSync(
      SyncEntry(
        id: 'sync-vis-$childId-${now.millisecondsSinceEpoch}',
        entityType: 'visibility',
        entityId: childId,
        operation: SyncOperation.update,
        payload: {'child_id': childId, 'visibility': level.name},
        status: SyncStatus.pending,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  /// Enqueues a completed weekly check-in for cloud sync.
  @override
  Future<void> enqueueCheckIn(CheckInRecord record) {
    final now = DateTime.now().toUtc();
    return enqueueSync(
      SyncEntry(
        id: 'sync-checkin-${record.childId}-${now.millisecondsSinceEpoch}',
        entityType: 'check_in',
        entityId: record.childId,
        operation: SyncOperation.create,
        payload: {
          'child_id': record.childId,
          'week_start': record.weekStart.toIso8601String(),
          'topic': record.topic,
          'question': record.question,
          'completed_at': record.completedAt.toIso8601String(),
        },
        status: SyncStatus.pending,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  /// Enqueues an app launch event.
  @override
  Future<void> enqueueAppLaunch(String childId, String appId) {
    final now = DateTime.now().toUtc();
    return enqueueSync(
      SyncEntry(
        id: 'sync-launch-$childId-$appId-${now.millisecondsSinceEpoch}',
        entityType: 'app_launch',
        entityId: appId,
        operation: SyncOperation.update,
        payload: {
          'child_id': childId,
          'app_id': appId,
          'timestamp': now.toIso8601String(),
        },
        status: SyncStatus.pending,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  /// Enqueues an app category override.
  @override
  Future<void> enqueueAppCategory(
    String childId,
    String appId,
    AppCategory category,
  ) {
    final now = DateTime.now().toUtc();
    return enqueueSync(
      SyncEntry(
        id: 'sync-cat-$childId-$appId-${now.millisecondsSinceEpoch}',
        entityType: 'app_category',
        entityId: appId,
        operation: SyncOperation.update,
        payload: {
          'child_id': childId,
          'app_id': appId,
          'category': category.name,
        },
        status: SyncStatus.pending,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  /// Enqueues a continuous screen-time usage session.
  @override
  Future<void> enqueueUsageSession(String childId, UsageSession session) {
    final now = DateTime.now().toUtc();
    return enqueueSync(
      SyncEntry(
        id: 'sync-session-$childId-${session.id}-${now.millisecondsSinceEpoch}',
        entityType: 'usage_session',
        entityId: session.id,
        operation: SyncOperation.create,
        payload: {'child_id': childId, ...session.toJson()},
        status: SyncStatus.pending,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  /// Enqueues child metric updates (unlocks, notifications, sync timestamp).
  @override
  Future<void> enqueueChildMetrics(
    String childId, {
    int? unlocksToday,
    int? notificationsToday,
    DateTime? lastSyncedAt,
  }) {
    final now = DateTime.now().toUtc();
    return enqueueSync(
      SyncEntry(
        id: 'sync-metrics-$childId-${now.millisecondsSinceEpoch}',
        entityType: 'child_metrics',
        entityId: childId,
        operation: SyncOperation.update,
        payload: {
          'child_id': childId,
          'unlocks_today': ?unlocksToday,
          'notifications_today': ?notificationsToday,
          'last_synced_at': ?lastSyncedAt?.toIso8601String(),
        },
        status: SyncStatus.pending,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  /// Processes all pending entries in the queue, pushing them to the simulated remote API.
  ///
  /// Re-entrant calls while a sync is in flight share the same future to avoid
  /// duplicate processing or race conditions.
  @override
  Future<SyncResult> syncPending() {
    if (!isOnline) {
      return _buildOfflineResult();
    }
    if (_inFlightSync != null) {
      return _inFlightSync!;
    }
    return _inFlightSync = _runSyncBatch().whenComplete(() {
      _inFlightSync = null;
    });
  }

  Future<SyncResult> _buildOfflineResult() async {
    final pendingCount = await syncQueueDao.getPendingCount();
    return SyncResult(
      processedCount: pendingCount,
      successCount: 0,
      failedCount: 0,
      isOffline: true,
    );
  }

  Future<SyncResult> _runSyncBatch() async {
    final entries = await syncQueueDao.getPending(limit: 100);
    var success = 0;
    var failed = 0;

    for (final entry in entries) {
      // Mark entry in-flight
      await syncQueueDao.updateStatus(entry.id, SyncStatus.syncing);

      // Simulate network hop
      if (simulatedLatency > Duration.zero) {
        await Future<void>.delayed(simulatedLatency);
      }

      try {
        // Simulated remote API endpoint handler
        await _dispatchRemoteSync(entry);
        await syncQueueDao.markSynced(entry.id);
        success++;
      } catch (e) {
        await syncQueueDao.updateStatus(
          entry.id,
          SyncStatus.failed,
          error: e.toString(),
          retryCount: entry.retryCount + 1,
        );
        failed++;
      }
    }

    return SyncResult(
      processedCount: entries.length,
      successCount: success,
      failedCount: failed,
      isOffline: false,
    );
  }

  /// Simulates dispatching to a REST or GraphQL cloud endpoint.
  Future<void> _dispatchRemoteSync(SyncEntry entry) async {
    // Check for simulated failure trigger in payload (e.g. for testing error backoff)
    if (entry.payload['simulate_error'] == true) {
      throw Exception('Simulated remote server error for ${entry.entityType}');
    }
    // Otherwise, simulate successful server acceptance: HTTP 200 OK
  }
}
