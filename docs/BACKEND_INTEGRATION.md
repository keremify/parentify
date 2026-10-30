# Backend Integration Blueprint & Cloud Sync Guide

Parentify is engineered with a **local-first, offline-ready architecture** using the **Outbox Pattern**. Every write operation (agreements, context notes, check-ins, app launches, category changes) commits immediately to the on-device SQLite database for instant zero-latency feedback, while an idempotent `SyncEntry` is recorded in the `sync_queue` table.

This guide provides concrete, copy-ready blueprints for connecting Parentify to live cloud backends: **Supabase**, **Firebase Firestore**, and **Custom REST / GraphQL APIs**.

---

## 1. Clean Architecture Overview

```
┌────────────────────────────────────────────────────────┐
│             Presentation & State (AppState)             │
└───────────────────────────┬────────────────────────────┘
                            │
               ┌────────────┴────────────┐
               ▼                         ▼
    ┌──────────────────────┐  ┌──────────────────────┐
    │   FamilyRepository   │  │   SocialRepository   │
    └──────────┬───────────┘  └──────────┬───────────┘
               │                         │
               ├─────────────────────────┤
               ▼                         ▼
    ┌──────────────────────┐  ┌──────────────────────┐
    │     Local SQLite     │  │   CloudSyncService   │
    │  (ChildDao/UserDao)  │  │   (Outbox Pattern)   │
    └──────────────────────┘  └──────────┬───────────┘
                                         │
                         ┌───────────────┼───────────────┐
                         ▼               ▼               ▼
                    [ Supabase ]    [ Firebase ]    [ Custom API ]
```

All synchronization flows through the abstract `CloudSyncService` contract defined in `lib/backend/services/cloud_sync_service.dart`. To wire up any cloud provider, simply implement this interface and inject it during app initialization.

---

## 2. Supabase Integration (PostgreSQL + Row-Level Security)

[Supabase](https://supabase.com) provides managed PostgreSQL with real-time subscriptions and Row-Level Security (RLS), making it an ideal choice for multi-tenant family privacy.

### Database Schema & RLS Policies (SQL)

```sql
-- 1. Family Accounts Table
create table families (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz default now()
);

-- 2. Children Table
create table children (
  id text primary key,
  family_id uuid references families(id) on delete cascade not null,
  name text not null,
  age int not null,
  unlocks_today int default 0,
  notifications_today int default 0,
  last_synced_at timestamptz default now()
);

-- 3. Outbox Operations Table (Idempotent Event Log)
create table sync_events (
  id text primary key,
  family_id uuid references families(id) on delete cascade not null,
  entity_type text not null,
  entity_id text not null,
  operation text not null,
  payload jsonb not null,
  created_at timestamptz default now()
);

-- Enable Row-Level Security (RLS)
alter table families enable row level security;
alter table children enable row level security;
alter table sync_events enable row level security;

-- Policy: Only members of the family can read/write family data
create policy "Family isolation policy" on sync_events
  for all using (
    family_id = (select auth.jwt() ->> 'family_id')::uuid
  );
```

### Dart Implementation: `SupabaseCloudSyncService`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:parentify/backend/daos/sync_queue_dao.dart';
import 'package:parentify/backend/services/cloud_sync_service.dart';
import 'package:parentify/models/sync_entry.dart';

class SupabaseCloudSyncService extends CloudSyncService {
  SupabaseCloudSyncService({
    required this.supabase,
    required this.syncQueueDao,
  });

  final SupabaseClient supabase;
  final SyncQueueDao syncQueueDao;
  
  bool _isOnline = true;
  Future<SyncResult>? _inFlightSync;

  @override
  bool get isOnline => _isOnline;

  @override
  set isOnline(bool value) => _isOnline = value;

  @override
  Future<void> enqueueSync(SyncEntry entry) async {
    await syncQueueDao.enqueue(entry);
  }

  @override
  Future<SyncResult> syncPending() {
    if (!_isOnline) return _buildOfflineResult();
    if (_inFlightSync != null) return _inFlightSync!;
    
    return _inFlightSync = _dispatchBatch().whenComplete(() {
      _inFlightSync = null;
    });
  }

  Future<SyncResult> _dispatchBatch() async {
    final pending = await syncQueueDao.getPending(limit: 50);
    var success = 0;
    var failed = 0;

    for (final entry in pending) {
      await syncQueueDao.updateStatus(entry.id, SyncStatus.syncing);
      try {
        await supabase.from('sync_events').upsert({
          'id': entry.id,
          'entity_type': entry.entityType,
          'entity_id': entry.entityId,
          'operation': entry.operation.name,
          'payload': entry.payload,
          'created_at': entry.createdAt.toIso8601String(),
        });
        await syncQueueDao.markSynced(entry.id);
        success++;
      } catch (error) {
        await syncQueueDao.markFailed(entry.id, error.toString());
        failed++;
      }
    }

    return SyncResult(
      processedCount: pending.length,
      successCount: success,
      failedCount: failed,
    );
  }

  Future<SyncResult> _buildOfflineResult() async {
    final count = await syncQueueDao.getPendingCount();
    return SyncResult(
      processedCount: count,
      successCount: 0,
      failedCount: 0,
      isOffline: true,
    );
  }
}
```

---

## 3. Firebase Firestore Integration

For teams already on Google Cloud / Firebase:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parentify/backend/daos/sync_queue_dao.dart';
import 'package:parentify/backend/services/cloud_sync_service.dart';
import 'package:parentify/models/sync_entry.dart';

class FirebaseCloudSyncService extends CloudSyncService {
  FirebaseCloudSyncService({
    required this.firestore,
    required this.familyId,
    required this.syncQueueDao,
  });

  final FirebaseFirestore firestore;
  final String familyId;
  final SyncQueueDao syncQueueDao;

  @override
  Future<SyncResult> syncPending() async {
    final pending = await syncQueueDao.getPending(limit: 50);
    var success = 0;
    var failed = 0;

    final batch = firestore.batch();
    for (final entry in pending) {
      final docRef = firestore
          .collection('families')
          .doc(familyId)
          .collection('events')
          .doc(entry.id);

      batch.set(docRef, {
        ...entry.payload,
        'entityType': entry.entityType,
        'entityId': entry.entityId,
        'operation': entry.operation.name,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    try {
      await batch.commit();
      for (final entry in pending) {
        await syncQueueDao.markSynced(entry.id);
        success++;
      }
    } catch (e) {
      for (final entry in pending) {
        await syncQueueDao.markFailed(entry.id, e.toString());
        failed++;
      }
    }

    return SyncResult(
      processedCount: pending.length,
      successCount: success,
      failedCount: failed,
    );
  }
}
```

---

## 4. Custom REST / GraphQL Backend Integration

If connecting to a custom backend service (Node.js, Go, Python, Ruby, or Java):

### Proposed Endpoint Specification
- **Method:** `POST /api/v1/family/sync/batch`
- **Headers:** `Authorization: Bearer <TOKEN>`
- **Request Body:**
  ```json
  {
    "client_timestamp": "2026-10-30T14:00:00Z",
    "batch": [
      {
        "id": "sync-agr-1730294400000",
        "entity_type": "agreement",
        "entity_id": "agr-101",
        "operation": "create",
        "payload": {
          "child_id": "leo",
          "kind": "dailyCap",
          "title": "Sunday gaming cap"
        }
      }
    ]
  }
  ```
- **Response Body:**
  ```json
  {
    "synced_ids": ["sync-agr-1730294400000"],
    "rejected_ids": []
  }
  ```

---

## 5. Wiring into `AppState` Initialization

In `lib/main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize SQLite Database
  final appDb = await AppDatabase.getInstance();

  // 2. Initialize your real CloudSyncService (e.g., Supabase, Firebase, or REST)
  final syncService = SupabaseCloudSyncService(
    supabase: Supabase.instance.client,
    syncQueueDao: SyncQueueDao(appDb.db),
  );

  // 3. Initialize AppState backed by SQLite and Cloud Sync
  final appState = await AppState.createFromSqlite(
    database: appDb,
  );

  runApp(ParentifyApp(state: appState));
}
```

---

## 6. Migration Checklist

When transitioning from the simulation to production:
1. Replace `SqliteAuthService` with your real authentication provider adhering to `AuthService` (`signInParent`, `signInChild`, `signOut`).
2. Add background periodic sync triggers via `workmanager` (Android) or `BackgroundTasks` (iOS).
3. Enable conflict resolution policies (e.g. Last-Write-Wins based on ISO-8601 timestamps).
4. Review GDPR / COPPA compliance: ensure all child data is stored with end-to-end encryption or strict family-scoped row-level security.
