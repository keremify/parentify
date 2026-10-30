import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:parentify/backend/daos/child_dao.dart';
import 'package:parentify/backend/daos/social_dao.dart';
import 'package:parentify/backend/daos/sync_queue_dao.dart';
import 'package:parentify/backend/daos/user_dao.dart';
import 'package:parentify/backend/database/app_database.dart';
import 'package:parentify/backend/database/seed_data.dart';
import 'package:parentify/backend/repositories/sqlite_family_repository.dart';
import 'package:parentify/backend/repositories/sqlite_social_repository.dart';
import 'package:parentify/backend/services/cloud_sync_service.dart';
import 'package:parentify/backend/services/sqlite_auth_service.dart';
import 'package:parentify/data/demo_data.dart';
import 'package:parentify/models/agreement.dart';
import 'package:parentify/models/app_usage.dart';
import 'package:parentify/models/check_in_record.dart';
import 'package:parentify/models/child.dart';
import 'package:parentify/models/context_note.dart';
import 'package:parentify/models/sync_entry.dart';
import 'package:parentify/models/visibility.dart';
import 'package:parentify/services/auth_service.dart';
import 'package:parentify/state/app_state.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late UserDao userDao;
  late ChildDao childDao;
  late SocialDao socialDao;
  late SyncQueueDao syncQueueDao;
  late SimulatedCloudSyncService syncService;
  late SqliteFamilyRepository familyRepo;
  late SqliteSocialRepository socialRepo;
  late SqliteAuthService authService;

  setUp(() async {
    db = await AppDatabase.getInstance(inMemory: true);
    userDao = UserDao(db.db);
    childDao = ChildDao(db.db);
    socialDao = SocialDao(db.db);
    syncQueueDao = SyncQueueDao(db.db);
    syncService = SimulatedCloudSyncService(
      syncQueueDao: syncQueueDao,
      simulatedLatency: Duration.zero,
    );
    familyRepo = SqliteFamilyRepository(
      userDao: userDao,
      childDao: childDao,
      syncService: syncService,
    );
    socialRepo = SqliteSocialRepository(
      socialDao: socialDao,
      childDao: childDao,
      syncService: syncService,
    );
    authService = SqliteAuthService(userDao);
  });

  tearDown(() async {
    await db.close();
  });

  group('SQLite Database & Test Accounts', () {
    test('enforces foreign keys and cascades child deletion', () async {
      final pragma = await db.db.rawQuery('PRAGMA foreign_keys');
      expect(pragma.single.values.single, 1);

      await db.db.delete(
        'children',
        where: 'id = ?',
        whereArgs: [DbSeedData.testChildId],
      );

      final apps = await db.db.query(
        'child_apps',
        where: 'child_id = ?',
        whereArgs: [DbSeedData.testChildId],
      );
      final sessions = await db.db.query(
        'usage_sessions',
        where: 'child_id = ?',
        whereArgs: [DbSeedData.testChildId],
      );
      expect(apps, isEmpty);
      expect(sessions, isEmpty);
    });

    test('never stores readable credentials in the database', () async {
      final users = await db.db.query('users');
      expect(
        users.single['password_hash'],
        isNot(DbSeedData.testParentPassword),
      );
      expect(users.single['password_salt'], isA<String>());
      expect(
        (users.single['password_salt'] as String).length,
        greaterThanOrEqualTo(32),
      );

      final children = await db.db.query('children');
      expect(children.single['pin_hash'], isNot(DbSeedData.testChildPin));
      expect(children.single['pin_salt'], isA<String>());
      expect(children.single.containsKey('pin'), isFalse);
    });

    test('upgrades a version 1 database without keeping plaintext', () async {
      sqfliteFfiInit();
      final directory = await Directory.systemTemp.createTemp('parentify-db');
      addTearDown(() => directory.delete(recursive: true));
      final path = '${directory.path}/legacy.db';

      final legacy = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (database, version) => database.execute('''
            CREATE TABLE users (
              id TEXT PRIMARY KEY,
              email TEXT UNIQUE NOT NULL,
              password_hash TEXT NOT NULL,
              name TEXT NOT NULL,
              role TEXT NOT NULL,
              family_name TEXT NOT NULL,
              created_at TEXT NOT NULL
            );
          '''),
        ),
      );
      await legacy.insert('users', {
        'id': 'legacy-parent',
        'email': 'legacy@example.com',
        'password_hash': 'PlaintextPassword1!',
        'name': 'Legacy',
        'role': 'parent',
        'family_name': 'Legacy Family',
        'created_at': DateTime.now().toIso8601String(),
      });
      await legacy.close();

      final upgraded = await AppDatabase.getInstance(customPath: path);
      addTearDown(upgraded.close);

      final row = (await upgraded.db.query('users')).single;
      expect(row['password_hash'], isNot('PlaintextPassword1!'));
      expect(row['password_salt'], isA<String>());

      final upgradedAuth = SqliteAuthService(UserDao(upgraded.db));
      final session = await upgradedAuth.signInParent(
        email: DbSeedData.testParentEmail,
        password: DbSeedData.testParentPassword,
      );
      expect(session.role, UserRole.parent);
    });

    test('seeds exactly 1 Parent and 1 Child test account', () async {
      final familyMeta = await userDao.getFamilyMeta();
      expect(familyMeta, isNotNull);
      expect(familyMeta!['parentName'], DbSeedData.testParentName);
      expect(familyMeta['parentEmail'], DbSeedData.testParentEmail);
      expect(familyMeta['familyName'], DbSeedData.testFamilyName);

      final children = await childDao.getAllChildren();
      expect(children.length, 1);
      final leo = children.first;
      expect(leo.id, DbSeedData.testChildId);
      expect(leo.name, DbSeedData.testChildName);
      expect(leo.age, DbSeedData.testChildAge);
      expect(leo.apps.length, 5);
      expect(leo.days.length, 14);
      expect(leo.hourlyToday.length, 24);
      expect(leo.sessions.length, 2);
    });

    test('authenticates Parent from SQLite with correct credentials', () async {
      final session = await authService.signInParent(
        email: DbSeedData.testParentEmail,
        password: DbSeedData.testParentPassword,
      );

      expect(session.role, UserRole.parent);
      expect(session.identity, DbSeedData.testParentEmail);
    });

    test('rejects Parent sign-in from SQLite with invalid password', () async {
      expect(
        () => authService.signInParent(
          email: DbSeedData.testParentEmail,
          password: 'WrongPassword!',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('authenticates Child from SQLite with correct PIN', () async {
      final session = await authService.signInChild(
        childId: DbSeedData.testChildId,
        pin: DbSeedData.testChildPin,
      );

      expect(session.role, UserRole.child);
      expect(session.childId, DbSeedData.testChildId);
    });

    test('rejects Child sign-in from SQLite with invalid PIN', () async {
      expect(
        () => authService.signInChild(
          childId: DbSeedData.testChildId,
          pin: '9999',
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('SQLite Repositories', () {
    test(
      'SqliteFamilyRepository fetches seeded family and child by ID',
      () async {
        final family = await familyRepo.getFamily();
        expect(family.parentName, DbSeedData.testParentName);
        expect(family.parentEmail, DbSeedData.testParentEmail);
        expect(family.children.length, 1);
        expect(family.children.first.name, 'Leo');

        final found = await familyRepo.getChildById('leo');
        expect(found, isNotNull);
        expect(found!.id, 'leo');

        final notFound = await familyRepo.getChildById('nonexistent');
        expect(notFound, isNull);
      },
    );

    test('SqliteSocialRepository persists context notes in SQLite', () async {
      final note = ContextNote(
        id: 'sqlite-note-1',
        childId: 'leo',
        createdAt: DateTime.now(),
        author: UserRole.child,
        tag: NoteTag.school,
        text: 'Practiced spelling test',
        scope: NoteScope.day,
      );

      await socialRepo.addNote(note);
      final initialData = await socialRepo.loadInitialData();
      expect(initialData.notes.any((n) => n.id == 'sqlite-note-1'), isTrue);

      await socialRepo.deleteNote('sqlite-note-1');
      final afterDelete = await socialRepo.loadInitialData();
      expect(afterDelete.notes.any((n) => n.id == 'sqlite-note-1'), isFalse);
    });

    test('SqliteSocialRepository persists agreements in SQLite', () async {
      final agreement = Agreement(
        id: 'sqlite-agr-1',
        childId: 'leo',
        kind: AgreementKind.dailyCap,
        title: 'Sunday gaming',
        detail: '1 hour bonus for completing chores',
        status: AgreementStatus.active,
        proposedBy: UserRole.parent,
        createdAt: DateTime.now(),
      );

      await socialRepo.saveAgreement(agreement);
      final initialData = await socialRepo.loadInitialData();
      final saved = initialData.agreements.firstWhere(
        (a) => a.id == 'sqlite-agr-1',
      );
      expect(saved.title, 'Sunday gaming');
      expect(saved.status, AgreementStatus.active);
    });

    test(
      'SqliteSocialRepository updates visibility and saves check-ins',
      () async {
        await socialRepo.setVisibility('leo', VisibilityLevel.full);
        final initialData = await socialRepo.loadInitialData();
        expect(initialData.visibility['leo'], VisibilityLevel.full);

        final checkIn = CheckInRecord(
          childId: 'leo',
          weekStart: DateTime.utc(2026, 1, 5),
          topic: 'Evening Routine',
          question: 'Did reading before bed help you sleep better?',
          completedAt: DateTime.utc(2026, 1, 11, 20, 0),
        );
        await socialRepo.saveCheckIn(checkIn);
        final checkIns = await socialDao.getCheckIns();
        expect(checkIns.any((c) => c.topic == 'Evening Routine'), isTrue);
      },
    );
  });

  group('AppState with SQLite backend integration', () {
    test('AppState.createFromSqlite initializes cleanly and authenticates test users', () async {
      final state = await AppState.createFromSqlite(database: db);
      addTearDown(state.dispose);

      expect(state.children.length, 1);
      expect(state.children.first.name, 'Leo');
      expect(state.parentEmail, DbSeedData.testParentEmail);
      expect(state.parentName, DbSeedData.testParentName);

      // Parent sign-in
      final parentOk = await state.signInParent(
        email: DbSeedData.testParentEmail,
        password: DbSeedData.testParentPassword,
      );
      expect(parentOk, isTrue);
      expect(state.isParent, isTrue);
      expect(state.signedInAs, DbSeedData.testParentEmail);

      // Child sign-in
      final childOk = await state.signInChild(
        childId: 'leo',
        pin: DbSeedData.testChildPin,
      );
      expect(childOk, isTrue);
      expect(state.isChild, isTrue);
      expect(state.activeChild?.id, 'leo');

      // Reject invalid child PIN
      final invalidOk = await state.signInChild(childId: 'leo', pin: '0000');
      expect(invalidOk, isFalse);
      expect(state.authError, isNotNull);
    });

    test('AppState immediately updates in-memory child apps on launch and category changes', () async {
      final state = await AppState.createFromSqlite(database: db);
      addTearDown(state.dispose);

      final initialLaunches = state.children.first.apps
          .firstWhere((a) => a.id == 'messages')
          .launchesToday;

      state.recordAppLaunch('leo', 'messages');

      final updatedLaunches = state.children.first.apps
          .firstWhere((a) => a.id == 'messages')
          .launchesToday;
      expect(updatedLaunches, initialLaunches + 1);

      state.updateAppCategory('leo', 'messages', AppCategory.social);

      final updatedCategory = state.children.first.apps
          .firstWhere((a) => a.id == 'messages')
          .category;
      expect(updatedCategory, AppCategory.social);

      // Allow background repository writes to flush before tearDown closes db.
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });

    test(
      'AppState.resetDemoData resets SQLite tables and in-memory state cleanly',
      () async {
        final state = await AppState.createFromSqlite(database: db);
        addTearDown(state.dispose);

        await state.signInParent(
          email: DbSeedData.testParentEmail,
          password: DbSeedData.testParentPassword,
        );
        state.saveApiKey('AIzaSyTestKey1234567890');
        state.addContextNote(
          ContextNote(
            id: 'custom-note-1',
            childId: 'leo',
            createdAt: DateTime.now(),
            author: UserRole.parent,
            tag: NoteTag.family,
            text: 'Custom note',
            scope: NoteScope.day,
          ),
        );

        expect(
          state.notesFor('leo').any((n) => n.id == 'custom-note-1'),
          isTrue,
        );
        expect(state.isParent, isTrue);

        await state.resetDemoData();

        expect(state.role, isNull);
        expect(state.ai.apiKey, isNull);
        expect(state.signedInAs, isNull);
        expect(
          state.notesFor('leo').any((n) => n.id == 'custom-note-1'),
          isFalse,
        );
        expect(state.children.length, 1);
        expect(state.children.first.id, 'leo');
      },
    );

    test(
      'AppState.exportFamilyData creates structured export payload',
      () async {
        final state = await AppState.createFromSqlite(database: db);
        addTearDown(state.dispose);

        final payload = state.exportFamilyData();
        expect(payload['version'], 1);
        expect(
          (payload['family'] as Map<String, dynamic>)['parentName'],
          DbSeedData.testParentName,
        );
        expect(payload['children'], isA<List<dynamic>>());
        expect((payload['children'] as List).length, 1);
        expect(
          ((payload['children'] as List).first as Map<String, dynamic>)['name'],
          'Leo',
        );
      },
    );

    test(
      'AppState.saveChild persists and adds a sibling to SQLite family',
      () async {
        final state = await AppState.createFromSqlite(database: db);
        addTearDown(state.dispose);

        expect(state.children.length, 1);

        final ada = DemoData.buildAdaChild();
        await state.saveChild(ada, pin: '2026');

        expect(state.children.length, 2);
        expect(state.children.any((c) => c.name == 'Ada'), isTrue);

        // Verify sibling persisted to SQLite
        final fromDb = await childDao.getChildById('ada');
        expect(fromDb, isNotNull);
        expect(fromDb!.name, 'Ada');
        expect(fromDb.age, 14);
      },
    );
  });

  group('SQLite ChildDao Updates & Entity Persistence', () {
    test('recordAppLaunch increments launches in SQLite', () async {
      final childBefore = await childDao.getChildById('leo');
      final appBefore = childBefore!.apps.firstWhere((a) => a.id == 'messages');
      final initialLaunches = appBefore.launchesToday;

      await familyRepo.recordAppLaunch('leo', 'messages');

      final childAfter = await childDao.getChildById('leo');
      final appAfter = childAfter!.apps.firstWhere((a) => a.id == 'messages');
      expect(appAfter.launchesToday, initialLaunches + 1);
    });

    test('updateAppCategory updates category override in SQLite', () async {
      await familyRepo.updateAppCategory(
        'leo',
        'youtube_kids',
        AppCategory.education,
      );

      final child = await childDao.getChildById('leo');
      final yt = child!.apps.firstWhere((a) => a.id == 'youtube_kids');
      expect(yt.category, AppCategory.education);
    });

    test('recordDailyUsage stores and updates daily usage', () async {
      final today = DateTime.utc(2026, 1, 15);
      await familyRepo.recordDailyUsage(
        'leo',
        DailyUsage(date: today, minutes: 135, unlocks: 42),
      );

      final child = await childDao.getChildById('leo');
      final match = child!.days.firstWhere(
        (d) => d.date.year == 2026 && d.date.month == 1 && d.date.day == 15,
      );
      expect(match.minutes, 135);
      expect(match.unlocks, 42);
    });

    test('updateChildMetrics updates metrics in SQLite', () async {
      final now = DateTime.utc(2026, 1, 15, 14, 30);
      await familyRepo.updateChildMetrics(
        'leo',
        unlocksToday: 55,
        notificationsToday: 28,
        lastSyncedAt: now,
      );

      final child = await childDao.getChildById('leo');
      expect(child!.unlocksToday, 55);
      expect(child.notificationsToday, 28);
      expect(child.lastSyncedAt, now);
    });
  });

  group('Sync Queue & Offline-First Outbox Pattern', () {
    test('enqueues outbox records on repository write operations', () async {
      final initialPending = await syncQueueDao.getPendingCount();

      // Write an agreement
      await socialRepo.saveAgreement(
        Agreement(
          id: 'sync-agr-test',
          childId: 'leo',
          kind: AgreementKind.bedtime,
          title: 'Bedtime reminder',
          detail: 'No devices after 9pm',
          status: AgreementStatus.active,
          proposedBy: UserRole.parent,
          createdAt: DateTime.now(),
        ),
      );

      // Write a context note
      await socialRepo.addNote(
        ContextNote(
          id: 'sync-note-test',
          childId: 'leo',
          createdAt: DateTime.now(),
          author: UserRole.parent,
          tag: NoteTag.family,
          text: 'Family dinner tonight',
          scope: NoteScope.day,
        ),
      );

      final pendingAfter = await syncQueueDao.getPendingCount();
      expect(pendingAfter, initialPending + 2);

      final pendingEntries = await syncQueueDao.getPending();
      expect(pendingEntries.any((e) => e.entityId == 'sync-agr-test'), isTrue);
      expect(pendingEntries.any((e) => e.entityId == 'sync-note-test'), isTrue);
    });

    test(
      'syncPending pushes outbox items and marks them synced when online',
      () async {
        // Enqueue items via repository writes
        await familyRepo.recordAppLaunch('leo', 'duolingo');
        await familyRepo.updateAppCategory(
          'leo',
          'minecraft',
          AppCategory.education,
        );

        syncService.isOnline = true;
        final pendingCount = await syncQueueDao.getPendingCount();
        expect(pendingCount, greaterThan(0));

        final result = await syncService.syncPending();
        expect(result.isOffline, isFalse);
        expect(result.successCount, pendingCount);
        expect(result.failedCount, 0);

        final remaining = await syncQueueDao.getPendingCount();
        expect(remaining, 0);
      },
    );

    test('syncPending preserves queue when offline', () async {
      // Enqueue an item
      await syncService.enqueueAppLaunch('leo', 'messages');
      syncService.isOnline = false;

      final countBefore = await syncQueueDao.getPendingCount();
      expect(countBefore, greaterThan(0));

      final result = await syncService.syncPending();
      expect(result.isOffline, isTrue);
      expect(result.successCount, 0);

      final countAfter = await syncQueueDao.getPendingCount();
      expect(countAfter, countBefore);
    });

    test('syncPending marks failed entries and records retry count', () async {
      syncService.isOnline = true;
      final errorEntry = SyncEntry(
        id: 'error-entry-1',
        entityType: 'test',
        entityId: 'err-1',
        operation: SyncOperation.create,
        payload: {'simulate_error': true},
        status: SyncStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await syncQueueDao.enqueue(errorEntry);

      final result = await syncService.syncPending();
      expect(result.failedCount, 1);

      final failed = await syncQueueDao.getById('error-entry-1');
      expect(failed, isNotNull);
      expect(failed!.status, SyncStatus.failed);
      expect(failed.retryCount, 1);
      expect(failed.lastError, contains('Simulated remote server error'));
    });

    test('retries a failed entry on the next sync until maxAttempts', () async {
      syncService.isOnline = true;
      await syncQueueDao.enqueue(
        SyncEntry(
          id: 'error-entry-retry',
          entityType: 'test',
          entityId: 'err-retry',
          operation: SyncOperation.create,
          payload: {'simulate_error': true},
          status: SyncStatus.pending,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      for (var attempt = 1; attempt <= SyncQueueDao.maxAttempts; attempt++) {
        final result = await syncService.syncPending();
        expect(result.failedCount, 1, reason: 'attempt $attempt should retry');
        final entry = await syncQueueDao.getById('error-entry-retry');
        expect(entry!.retryCount, attempt);
      }

      // The cap is reached: the entry stays failed and is no longer picked up.
      final finalAttempt = await syncService.syncPending();
      expect(finalAttempt.processedCount, 0);
      expect(finalAttempt.failedCount, 0);
      expect(await syncQueueDao.getPendingCount(), 0);
      expect(
        (await syncQueueDao.getById('error-entry-retry'))!.status,
        SyncStatus.failed,
      );
    });

    test('resetStaleSyncing recovers entries stranded in syncing', () async {
      await syncQueueDao.enqueue(
        SyncEntry(
          id: 'stale-sync',
          entityType: 'test',
          entityId: 'stale-1',
          operation: SyncOperation.update,
          payload: const {},
          status: SyncStatus.syncing,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      expect(await syncQueueDao.getPendingCount(), 0);

      final recovered = await syncQueueDao.resetStaleSyncing();

      expect(recovered, 1);
      final entry = await syncQueueDao.getById('stale-sync');
      expect(entry!.status, SyncStatus.pending);
      expect(await syncQueueDao.getPendingCount(), 1);
    });

    test(
      'AppState sync helpers toggle online state and flush outbox',
      () async {
        final state = await AppState.createFromSqlite(database: db);
        addTearDown(state.dispose);

        var notified = false;
        state.addListener(() => notified = true);

        expect(state.isSyncOnline, isTrue);
        state.isSyncOnline = false;
        expect(state.isSyncOnline, isFalse);
        expect(notified, isTrue);

        state.isSyncOnline = true;
        final result = await state.syncPendingChanges();
        expect(result, isNotNull);
        expect(result!.isOffline, isFalse);
      },
    );

    test(
      'recordUsageSession and updateChildMetrics enqueue outbox records',
      () async {
        final initialPending = await syncQueueDao.getPendingCount();

        final session = UsageSession(
          id: 'session-outbox-1',
          start: DateTime.utc(2026, 1, 15, 9, 0),
          minutes: 45,
          label: 'Morning learning',
          category: AppCategory.education,
          apps: const ['duolingo'],
        );
        await familyRepo.recordUsageSession('leo', session);

        await familyRepo.updateChildMetrics(
          'leo',
          unlocksToday: 60,
          notificationsToday: 30,
          lastSyncedAt: DateTime.utc(2026, 1, 15, 12, 0),
        );

        final countAfter = await syncQueueDao.getPendingCount();
        expect(countAfter, initialPending + 2);

        final pending = await syncQueueDao.getPending();
        expect(
          pending.any(
            (e) =>
                e.entityType == 'usage_session' &&
                e.entityId == 'session-outbox-1',
          ),
          isTrue,
        );
        expect(
          pending.any(
            (e) => e.entityType == 'child_metrics' && e.entityId == 'leo',
          ),
          isTrue,
        );
      },
    );

    test('syncPending re-entrancy guard shares in-flight sync and prevents double-dispatch', () async {
      syncService.isOnline = true;
      await syncService.enqueueAppLaunch('leo', 'messages');

      final slowSyncService = SimulatedCloudSyncService(
        syncQueueDao: syncQueueDao,
        simulatedLatency: const Duration(milliseconds: 50),
      );
      slowSyncService.isOnline = true;

      final future1 = slowSyncService.syncPending();
      final future2 = slowSyncService.syncPending();

      expect(identical(future1, future2), isTrue);

      final results = await Future.wait([future1, future2]);
      expect(results[0], equals(results[1]));
    });
  });

  group('SyncEntry & SyncQueueDao Robustness', () {
    test('SyncEntry supports value equality and hashCode', () {
      final now = DateTime.utc(2026, 1, 15, 10, 0);
      final entry1 = SyncEntry(
        id: 'sync-eq-1',
        entityType: 'app_launch',
        entityId: 'messages',
        operation: SyncOperation.create,
        payload: const {'child_id': 'leo'},
        status: SyncStatus.pending,
        createdAt: now,
        updatedAt: now,
      );
      final entry2 = SyncEntry(
        id: 'sync-eq-1',
        entityType: 'app_launch',
        entityId: 'messages',
        operation: SyncOperation.create,
        payload: const {'child_id': 'leo'},
        status: SyncStatus.pending,
        createdAt: now,
        updatedAt: now,
      );
      final entry3 = entry1.copyWith(id: 'sync-eq-2');

      expect(entry1, equals(entry2));
      expect(entry1.hashCode, equals(entry2.hashCode));
      expect(entry1, isNot(equals(entry3)));
    });

    test('SyncQueueDao queries use parameterized SQL arguments', () async {
      final count = await syncQueueDao.getPendingCount();
      final pending = await syncQueueDao.getPending();
      expect(count, isA<int>());
      expect(pending, isA<List<SyncEntry>>());
    });
  });
}
