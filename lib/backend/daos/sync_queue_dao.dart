import 'package:sqflite/sqflite.dart';

import '../../models/sync_entry.dart';

/// Data Access Object for managing the offline sync queue outbox table.
class SyncQueueDao {
  const SyncQueueDao(this.db);

  final Database db;

  /// A failed entry is offered to the next sync until this many attempts have
  /// been made, then it stays visible as failed instead of retrying forever.
  static const int maxAttempts = 5;

  static const String _retryableWhere =
      '(status = ? OR (status = ? AND retry_count < ?))';

  /// Appends or updates an entity mutation in the sync queue outbox.
  Future<void> enqueue(SyncEntry entry) async {
    await db.insert(
      'sync_queue',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves pending sync entries and retryable failures, oldest first.
  Future<List<SyncEntry>> getPending({int limit = 50}) async {
    final rows = await db.query(
      'sync_queue',
      where: _retryableWhere,
      whereArgs: [SyncStatus.pending.name, SyncStatus.failed.name, maxAttempts],
      orderBy: 'created_at ASC',
      limit: limit,
    );
    return [for (final row in rows) SyncEntry.fromMap(row)];
  }

  /// Recovers entries left in-flight by a crash or a killed process.
  Future<int> resetStaleSyncing() => db.update(
    'sync_queue',
    {
      'status': SyncStatus.pending.name,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    },
    where: 'status = ?',
    whereArgs: [SyncStatus.syncing.name],
  );

  /// Retrieves all sync queue items regardless of status.
  Future<List<SyncEntry>> getAllEntries() async {
    final rows = await db.query('sync_queue', orderBy: 'created_at DESC');
    return [for (final row in rows) SyncEntry.fromMap(row)];
  }

  /// Retrieves a single sync entry by its unique ID.
  Future<SyncEntry?> getById(String id) async {
    final rows = await db.query(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SyncEntry.fromMap(rows.first);
  }

  /// Updates the status, retry count, and optional error of a sync entry.
  Future<void> updateStatus(
    String id,
    SyncStatus status, {
    String? error,
    int? retryCount,
  }) async {
    final values = <String, Object?>{
      'status': status.name,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (error != null) values['last_error'] = error;
    if (retryCount != null) values['retry_count'] = retryCount;

    await db.update('sync_queue', values, where: 'id = ?', whereArgs: [id]);
  }

  /// Marks an entry as successfully synced.
  Future<void> markSynced(String id) async {
    await updateStatus(id, SyncStatus.synced, error: null);
  }

  /// Purges old synced entries to keep the local database compact.
  Future<int> purgeSynced({
    Duration olderThan = const Duration(days: 7),
  }) async {
    final cutoff = DateTime.now().toUtc().subtract(olderThan).toIso8601String();
    return db.delete(
      'sync_queue',
      where: 'status = ? AND updated_at < ?',
      whereArgs: [SyncStatus.synced.name, cutoff],
    );
  }

  /// Returns the current count of unsynced changes the next sync will attempt.
  Future<int> getPendingCount() async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM sync_queue WHERE $_retryableWhere',
      [SyncStatus.pending.name, SyncStatus.failed.name, maxAttempts],
    );
    return (result.first['count'] as num?)?.toInt() ?? 0;
  }

  /// Clears all entries from the queue (useful for test resets).
  Future<void> clearAll() async {
    await db.delete('sync_queue');
  }
}
