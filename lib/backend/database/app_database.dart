import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../daos/sync_queue_dao.dart';
import 'schema.dart';
import 'seed_data.dart';

/// Database management service for Parentify's local SQLite backend simulation.
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;
  static AppDatabase? _instance;

  static void initFfiIfNeeded() {
    if (kIsWeb) return;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  /// Opens or retrieves the shared SQLite database instance.
  ///
  /// Automatically runs schema creation and test account seeding.
  static Future<AppDatabase> getInstance({
    String? customPath,
    bool inMemory = false,
  }) async {
    if (_instance != null && !inMemory && customPath == null) {
      return _instance!;
    }

    initFfiIfNeeded();

    final String dbPath;
    if (inMemory) {
      dbPath = inMemoryDatabasePath;
    } else if (customPath != null) {
      dbPath = customPath;
    } else {
      final defaultDatabasesPath = await getDatabasesPath();
      dbPath = p.join(defaultDatabasesPath, 'parentify_local.db');
    }

    final database = await openDatabase(
      dbPath,
      version: DbSchema.version,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await DbSchema.createTables(db);
        await DbSeedData.seed(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // The local database is derived from seed data. Rebuilding it on an
        // incompatible upgrade guarantees a version 1 file cannot keep its
        // plaintext credentials.
        await DbSchema.resetForDemo(db);
        await DbSeedData.seed(db);
      },
      onOpen: (db) async {
        // A crash between "syncing" and the result leaves rows stranded. Put
        // them back in the queue so the next sync can retry them.
        await SyncQueueDao(db).resetStaleSyncing();
      },
    );

    final appDb = AppDatabase._(database);
    if (!inMemory && customPath == null) {
      _instance = appDb;
    }
    return appDb;
  }

  Future<void> close() async {
    await db.close();
    if (_instance == this) {
      _instance = null;
    }
  }
}
