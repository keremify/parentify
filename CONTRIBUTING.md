# Contributing to Parentify

Thank you for your interest in contributing to **Parentify**! Parentify is an open-source, humane family screen-time and digital wellbeing platform designed around transparency, shared agreements, and healthy communication rather than punitive locks or invasive surveillance.

This guide outlines our architectural patterns, local backend simulation, development workflows, and contribution standards.

---

## Architecture Overview

Parentify is built with a layered **Clean Architecture** to ensure clean separation of concerns, testability, and effortless backend swappability:

```
lib/
├── models/                     # Immutable domain entities & JSON serialization
│   ├── agreement.dart          # Family agreements & pacts
│   ├── app_usage.dart          # App categories, daily usage, and app metadata
│   ├── check_in_record.dart    # Weekly family reflection check-ins
│   ├── child.dart              # Child profile, device usage, and metrics
│   ├── context_note.dart       # Sticky notes & day context tags
│   ├── sync_entry.dart         # Outbox sync queue records
│   └── user_role.dart          # Parent / Child roles
│
├── backend/
│   ├── database/               # SQLite schema & seeding
│   │   ├── app_database.dart   # Database lifecycle (mobile sqflite & desktop ffi)
│   │   ├── schema.dart         # DDL tables & indexes
│   │   └── seed_data.dart      # Seed accounts & 14-day sample history
│   ├── daos/                   # Data Access Objects (SQL queries & mutations)
│   │   ├── child_dao.dart      # Children, apps, usage, and metrics queries
│   │   ├── social_dao.dart     # Agreements, context notes, and check-ins
│   │   ├── sync_queue_dao.dart # Outbox queue persistence & status tracking
│   │   └── user_dao.dart       # User authentication & family metadata
│   ├── repositories/           # SQLite implementations of repository contracts
│   │   ├── sqlite_family_repository.dart
│   │   └── sqlite_social_repository.dart
│   └── services/               # Backend services
│       ├── cloud_sync_service.dart  # Offline-first sync service & simulation
│       └── sqlite_auth_service.dart # Password hashing & token simulation
│
├── repositories/               # Abstract repository contracts (domain interfaces)
│   ├── family_repository.dart
│   └── social_repository.dart
│
├── state/
│   └── app_state.dart          # Reactive state management (ChangeNotifier)
│
├── screens/                    # Presentation layer (feature screens)
├── widgets/                    # Reusable atomic UI components
└── theme/                      # Design system tokens, typography, and palettes
```

---

## Local Simulation & Test Accounts

To allow open-source contributors and prospective founders to develop and evaluate Parentify without configuring cloud infrastructure or third-party API keys, Parentify runs a **production-grade local SQLite backend**.

### Seed Accounts
When the application starts for the first time, it automatically initializes the SQLite schema and seeds realistic test accounts:

- **Parent Account:**
  - **Email:** `parent@parentify.dev`
  - **Password:** `Parentify2026!`
- **Child Account:**
  - **Name:** Leo (Age 11)
  - **PIN:** `2026`

All initial data (14 days of screen time, category breakdowns, hourly patterns, and family agreements) is persisted in the local SQLite database file on device or in memory during automated tests.

---

## Offline-First Outbox Synchronization

Parentify implements an **Offline-First Outbox Pattern**:

1. **Local Mutation First:** Every user action (saving an agreement, logging a context note, changing sharing visibility, recording an app launch) immediately writes to SQLite tables for instant UI feedback with zero latency.
2. **Outbox Enqueue:** Simultaneously, an idempotent `SyncEntry` is appended to the `sync_queue` table with status `pending`.
3. **Background Sync:** The `CloudSyncService` dequeues pending entries in FIFO order and dispatches them to remote API endpoints. If the device is offline, entries safely accumulate in SQLite and are dispatched once connectivity is restored.
4. **Error Handling & Retries:** Failed dispatches record the error and increment `retry_count` without blocking subsequent independent mutations.

### Connecting a Real Cloud Backend

If you are deploying Parentify with a live cloud service (such as **Supabase**, **Firebase Firestore**, or a **custom GraphQL / REST backend**):
1. Implement the `CloudSyncService` interface defined in [`lib/backend/services/cloud_sync_service.dart`](file:///lib/backend/services/cloud_sync_service.dart).
2. Wire your remote API calls inside `syncPending()` and batch dispatch handlers.
3. Replace `SimulatedCloudSyncService` in `AppState.createFromSqlite(...)`.

---

## Development Workflow

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (`v3.47.0` or later)
- [Dart SDK](https://dart.dev/get-dart) (`v3.13.0` or later)

### Getting Started

```bash
# 1. Clone repository
git clone https://github.com/keremify/parentify.git
cd parentify

# 2. Install dependencies
flutter pub get

# 3. Run the development app
flutter run
```

---

## Quality Gates & Verification

Parentify maintains strict quality, security, and accessibility standards. Every contribution must pass all gates:

### 1. Code Formatting
All Dart files must adhere to the standard Dart style:
```bash
# Verify formatting
dart format --output=none --set-exit-if-changed .

# Auto-format files
dart format .
```

### 2. Static Code Analysis
Zero analyzer warnings or infos are allowed:
```bash
flutter analyze --fatal-infos
```

### 3. Automated Test Suites
Run the backend, model serialization, and accessibility test suites:
```bash
flutter test test/sqlite_backend_test.dart test/models_and_repositories_test.dart test/accessibility_test.dart
```

---

## Pull Request Guidelines

1. **Keep Changes Focused:** A pull request should address a single feature, refactor, or bug fix.
2. **Preserve Layering:** Business logic belongs in services or repositories; UI widgets must remain focused on presentation.
3. **Write Tests:** Include comprehensive unit or integration tests for any new repository, DAO, or service methods.
4. **Verify CI:** Ensure the GitHub Actions CI pipeline passes before requesting review.
5. **No Secrets in Code:** Never commit credentials, private keys, or `.env` files with production values. The bundled demo config (`assets/env.defaults`) is checked in and must stay keyless — pass `GEMINI_API_KEY` with `--dart-define` or enter it in Settings.

Thank you for helping build healthy, trust-centered digital experiences for families!
