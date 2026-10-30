import 'package:sqflite/sqflite.dart';

/// Database schema definition and migration manager for Parentify SQLite backend.
abstract final class DbSchema {
  /// Version 2 replaced plaintext credentials with salted digests.
  static const int version = 2;

  /// Dependent tables first, so a foreign-key-checked drop always succeeds.
  static const List<String> _tables = [
    'sync_queue',
    'check_in_records',
    'context_notes',
    'agreements',
    'hourly_usages',
    'usage_sessions',
    'daily_usages',
    'child_apps',
    'children',
    'users',
  ];

  /// Drops and recreates the demo schema.
  ///
  /// The local database is derived from the seed data, so an incompatible
  /// upgrade (version 1 stored plaintext credentials) starts clean instead of
  /// carrying the old values forward.
  static Future<void> resetForDemo(Database db) async {
    final batch = db.batch();
    for (final table in _tables) {
      batch.execute('DROP TABLE IF EXISTS $table');
    }
    await batch.commit(noResult: true);
    await createTables(db);
  }

  static Future<void> createTables(Database db) async {
    final batch = db.batch();

    // 1. Users / Family Admin
    batch.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        password_salt TEXT NOT NULL,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        family_name TEXT NOT NULL,
        created_at TEXT NOT NULL
      );
    ''');

    // 2. Children
    batch.execute('''
      CREATE TABLE IF NOT EXISTS children (
        id TEXT PRIMARY KEY,
        parent_id TEXT NOT NULL,
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        device_name TEXT NOT NULL,
        platform TEXT NOT NULL,
        accent_color INTEGER NOT NULL,
        pin_hash TEXT NOT NULL,
        pin_salt TEXT NOT NULL,
        visibility TEXT NOT NULL,
        unlocks_today INTEGER NOT NULL,
        notifications_today INTEGER NOT NULL,
        last_synced_at TEXT NOT NULL,
        FOREIGN KEY (parent_id) REFERENCES users (id) ON DELETE CASCADE
      );
    ''');

    // 3. Child Installed Apps & Usage
    batch.execute('''
      CREATE TABLE IF NOT EXISTS child_apps (
        id TEXT NOT NULL,
        child_id TEXT NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        icon_code_point INTEGER NOT NULL,
        last7_days_json TEXT NOT NULL,
        launches_today INTEGER NOT NULL,
        PRIMARY KEY (child_id, id),
        FOREIGN KEY (child_id) REFERENCES children (id) ON DELETE CASCADE
      );
    ''');

    // 4. Daily Usage History
    batch.execute('''
      CREATE TABLE IF NOT EXISTS daily_usages (
        child_id TEXT NOT NULL,
        date TEXT NOT NULL,
        minutes INTEGER NOT NULL,
        unlocks INTEGER NOT NULL,
        PRIMARY KEY (child_id, date),
        FOREIGN KEY (child_id) REFERENCES children (id) ON DELETE CASCADE
      );
    ''');

    // 5. Usage Sessions (longest stretches)
    batch.execute('''
      CREATE TABLE IF NOT EXISTS usage_sessions (
        id TEXT PRIMARY KEY,
        child_id TEXT NOT NULL,
        start_time TEXT NOT NULL,
        minutes INTEGER NOT NULL,
        label TEXT NOT NULL,
        category TEXT NOT NULL,
        apps_json TEXT NOT NULL,
        FOREIGN KEY (child_id) REFERENCES children (id) ON DELETE CASCADE
      );
    ''');

    // 6. Hourly Usage for Today (0..23)
    batch.execute('''
      CREATE TABLE IF NOT EXISTS hourly_usages (
        child_id TEXT NOT NULL,
        hour INTEGER NOT NULL,
        minutes INTEGER NOT NULL,
        PRIMARY KEY (child_id, hour),
        FOREIGN KEY (child_id) REFERENCES children (id) ON DELETE CASCADE
      );
    ''');

    // 7. Agreements
    batch.execute('''
      CREATE TABLE IF NOT EXISTS agreements (
        id TEXT PRIMARY KEY,
        child_id TEXT NOT NULL,
        kind TEXT NOT NULL,
        title TEXT NOT NULL,
        detail TEXT NOT NULL,
        status TEXT NOT NULL,
        proposed_by TEXT NOT NULL,
        created_at TEXT NOT NULL,
        response_note TEXT,
        FOREIGN KEY (child_id) REFERENCES children (id) ON DELETE CASCADE
      );
    ''');

    // 8. Context Notes
    batch.execute('''
      CREATE TABLE IF NOT EXISTS context_notes (
        id TEXT PRIMARY KEY,
        child_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        author TEXT NOT NULL,
        tag TEXT NOT NULL,
        text TEXT NOT NULL,
        scope TEXT NOT NULL,
        target_id TEXT,
        FOREIGN KEY (child_id) REFERENCES children (id) ON DELETE CASCADE
      );
    ''');

    // 9. Check-In Records
    batch.execute('''
      CREATE TABLE IF NOT EXISTS check_in_records (
        id TEXT PRIMARY KEY,
        child_id TEXT NOT NULL,
        week_start TEXT NOT NULL,
        topic TEXT NOT NULL,
        question TEXT NOT NULL,
        completed_at TEXT NOT NULL,
        FOREIGN KEY (child_id) REFERENCES children (id) ON DELETE CASCADE
      );
    ''');

    // 10. Offline-First Sync Queue
    batch.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        status TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');

    batch.execute('''
      CREATE INDEX IF NOT EXISTS idx_sync_queue_status ON sync_queue (status);
    ''');

    await batch.commit(noResult: true);
  }
}
