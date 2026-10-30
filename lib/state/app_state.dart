import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';

import '../backend/daos/child_dao.dart';
import '../backend/daos/social_dao.dart';
import '../backend/daos/sync_queue_dao.dart';
import '../backend/daos/user_dao.dart';
import '../backend/database/app_database.dart';
import '../backend/database/schema.dart';
import '../backend/database/seed_data.dart';
import '../backend/repositories/sqlite_family_repository.dart';
import '../backend/repositories/sqlite_social_repository.dart';
import '../backend/services/cloud_sync_service.dart';
import '../backend/services/sqlite_auth_service.dart';
import '../data/demo_data.dart';
import '../data/demo_social.dart';
import '../l10n/app_strings.dart';
import '../models/agreement.dart';
import '../models/app_usage.dart';
import '../models/check_in_record.dart';
import '../models/child.dart';
import '../models/context_note.dart';
import '../models/user_role.dart';
import '../models/visibility.dart';
import '../repositories/family_repository.dart';
import '../repositories/social_repository.dart';
import '../services/ai_analyzer_service.dart';
import '../services/auth_service.dart';
import '../utils/clock.dart';
import '../utils/dates.dart';

export '../models/user_role.dart' show UserRole;

class AppState extends ChangeNotifier {
  AppState({
    DemoFamily? family,
    AiAnalyzerService? analyzer,
    SocialSeed? social,
    AuthService? auth,
    FamilyRepository? familyRepository,
    SocialRepository? socialRepository,
    this.syncService,
    this.database,
  }) : _family = family ?? DemoData.build(),
       ai = analyzer ?? AiAnalyzerService(),
       _auth = auth ?? defaultAuthService(),
       familyRepo = familyRepository ?? DemoFamilyRepository(family: family),
       socialRepo = socialRepository ?? DemoSocialRepository(seed: social) {
    _seedSocial(social ?? DemoSocial.build());
  }

  /// Asynchronously creates an [AppState] backed directly by the local SQLite database.
  static Future<AppState> createFromSqlite({
    AppDatabase? database,
    AiAnalyzerService? analyzer,
  }) async {
    final appDb = database ?? await AppDatabase.getInstance();
    final userDao = UserDao(appDb.db);
    final childDao = ChildDao(appDb.db);
    final socialDao = SocialDao(appDb.db);
    final syncQueueDao = SyncQueueDao(appDb.db);
    final syncService = SimulatedCloudSyncService(syncQueueDao: syncQueueDao);

    final familyRepo = SqliteFamilyRepository(
      userDao: userDao,
      childDao: childDao,
      syncService: syncService,
    );
    final socialRepo = SqliteSocialRepository(
      socialDao: socialDao,
      childDao: childDao,
      syncService: syncService,
    );
    final authService = demoAuthEnabled
        ? SqliteAuthService(userDao)
        : const UnconfiguredAuthService();

    final family = await familyRepo.getFamily();
    final socialSeed = await socialRepo.loadInitialData();

    return AppState(
      family: family,
      analyzer: analyzer,
      social: socialSeed,
      auth: authService,
      familyRepository: familyRepo,
      socialRepository: socialRepo,
      syncService: syncService,
      database: appDb,
    );
  }

  DemoFamily _family;
  final AiAnalyzerService ai;
  final AuthService _auth;
  final FamilyRepository familyRepo;
  final SocialRepository socialRepo;
  final CloudSyncService? syncService;
  final AppDatabase? database;

  UserRole? _role;
  String? _activeChildId;
  String? _signedInAs;
  String? _authError;
  bool _notificationsEnabled = true;
  bool _includeParentUsage = false;

  List<ContextNote> _notes = const [];
  List<Agreement> _agreements = const [];
  Map<String, VisibilityLevel> _visibility = const {};
  List<CheckInRecord> _checkIns = const [];
  int _parentTodayMinutes = 0;
  int _parentWeekMinutes = 0;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  List<Child> get children => _family.children;
  String get parentName => _family.parentName;
  String get parentEmail => _family.parentEmail;
  String get familyName => _family.familyName;

  UserRole? get role => _role;
  bool get isSignedIn => _role != null;
  bool get isParent => _role == UserRole.parent;
  bool get isChild => _role == UserRole.child;
  String? get signedInAs => _signedInAs;
  String? get authError => _authError;

  /// True when this build can sign in through the test/demo path.
  bool get demoAuthAvailable =>
      _auth is DemoAuthService || _auth is SqliteAuthService;

  /// Signs in with verified parent credentials.
  ///
  /// The session role comes from [AuthService]; callers cannot choose it.
  Future<bool> signInParent({
    required String email,
    required String password,
    AppStrings strings = AppStrings.english,
  }) => _authenticate(
    () =>
        _auth.signInParent(email: email, password: password, strings: strings),
    strings,
  );

  /// Signs in a child with their PIN.
  Future<bool> signInChild({
    required String childId,
    required String pin,
    AppStrings strings = AppStrings.english,
  }) => _authenticate(
    () => _auth.signInChild(childId: childId, pin: pin, strings: strings),
    strings,
  );

  /// One-tap entry. Available when DemoAuthService or SqliteAuthService is active.
  Future<bool> signInDemoParent({AppStrings strings = AppStrings.english}) {
    final auth = _auth;
    if (auth is DemoAuthService) {
      return _authenticate(auth.signInDemoParent, strings);
    }
    if (auth is SqliteAuthService) {
      return _authenticate(auth.signInTestParent, strings);
    }
    return Future<bool>.value(false);
  }

  /// One-tap entry for a child profile.
  Future<bool> signInDemoChild({
    required String childId,
    AppStrings strings = AppStrings.english,
  }) {
    final auth = _auth;
    if (auth is DemoAuthService) {
      return _authenticate(
        () => auth.signInDemoChild(childId: childId),
        strings,
      );
    }
    if (auth is SqliteAuthService) {
      return _authenticate(
        () => auth.signInTestChild(childId: childId),
        strings,
      );
    }
    return Future<bool>.value(false);
  }

  Future<bool> _authenticate(
    Future<AuthSession> Function() run,
    AppStrings strings,
  ) async {
    _authError = null;
    try {
      final session = await run();
      if (_disposed) return false;

      if (session.role == UserRole.child) {
        final childId = session.childId;
        final child = childId == null ? null : childById(childId);
        if (child == null) {
          _authError = strings.childProfileUnavailable;
          notifyListeners();
          return false;
        }
        _activeChildId = child.id;
      } else {
        _activeChildId = null;
      }

      _role = session.role;
      _signedInAs = session.identity;
      notifyListeners();
      return true;
    } on AuthException catch (error) {
      if (_disposed) return false;
      _authError = error.message;
      notifyListeners();
      return false;
    } catch (_) {
      if (_disposed) return false;
      _authError = strings.signInFailed;
      notifyListeners();
      return false;
    }
  }

  bool get notificationsEnabled => _notificationsEnabled;
  bool get includeParentUsage => _includeParentUsage;
  int get parentTodayMinutes => _parentTodayMinutes;
  int get parentWeekMinutes => _parentWeekMinutes;
  CheckInRecord? get lastCheckIn => _checkIns.isEmpty ? null : _checkIns.first;
  List<CheckInRecord> get checkInHistory => List.unmodifiable(_checkIns);

  /// Consecutive weeks with a completed check-in, counting back from this week
  /// or last week when this week is still open.
  int get checkInStreak {
    if (_checkIns.isEmpty) return 0;
    final weeks = _checkIns
        .map((record) => _weekStart(record.weekStart))
        .toSet();
    var cursor = _weekStart(AppClock.now());
    if (!weeks.contains(cursor)) {
      cursor = addDays(cursor, -7);
    }
    var streak = 0;
    while (weeks.contains(cursor)) {
      streak++;
      cursor = addDays(cursor, -7);
    }
    return streak;
  }

  Child? get activeChild {
    if (_activeChildId == null) return null;
    for (final child in children) {
      if (child.id == _activeChildId) return child;
    }
    return null;
  }

  Child? childById(String id) {
    for (final child in children) {
      if (child.id == id) return child;
    }
    return null;
  }

  void signOut() {
    _role = null;
    _activeChildId = null;
    _signedInAs = null;
    _authError = null;
    ai.setApiKey(null);
    notifyListeners();
  }

  /// Saves or clears the in-memory Gemini key.
  ///
  /// Returns a user-safe validation message, or null on success.
  String? saveApiKey(String? key, {AppStrings strings = AppStrings.english}) {
    if (!isParent) return strings.aiKeyParentOnly;
    final problem = AiAnalyzerService.validateApiKey(key, strings: strings);
    if (problem != null) return problem;
    ai.setApiKey(key);
    notifyListeners();
    return null;
  }

  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
    notifyListeners();
  }

  void setIncludeParentUsage(bool enabled) {
    _includeParentUsage = enabled;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Context notes
  // ---------------------------------------------------------------------------

  List<ContextNote> notesFor(String childId) {
    final notes = _notes.where((note) => note.childId == childId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notes;
  }

  List<ContextNote> dayNotesFor(String childId) =>
      notesFor(childId).where((note) => note.scope == NoteScope.day).toList();

  ContextNote? noteForSession(String childId, String sessionId) {
    for (final note in _notes) {
      if (note.childId == childId &&
          note.scope == NoteScope.session &&
          note.targetId == sessionId) {
        return note;
      }
    }
    return null;
  }

  List<ContextNote> notesForApp(String childId, String appId) => _notes
      .where(
        (note) =>
            note.childId == childId &&
            note.scope == NoteScope.app &&
            note.targetId == appId,
      )
      .toList();

  void addContextNote(ContextNote note) {
    if (isChild && note.childId != _activeChildId) return;
    _notes = [note, ..._notes];
    unawaited(
      socialRepo.addNote(note).catchError((Object error) {
        debugPrint('Failed to save context note: $error');
      }),
    );
    notifyListeners();
  }

  void deleteContextNote(String id) {
    final index = _notes.indexWhere((note) => note.id == id);
    if (index < 0) return;
    final note = _notes[index];
    if (isChild && note.childId != _activeChildId) return;
    _notes = [
      for (var i = 0; i < _notes.length; i++)
        if (i != index) _notes[i],
    ];
    unawaited(
      socialRepo.deleteNote(id).catchError((Object error) {
        debugPrint('Failed to delete context note: $error');
      }),
    );
    notifyListeners();
  }

  void recordAppLaunch(String childId, String appId) {
    _updateChildApp(childId, appId, (app) {
      return app.copyWith(launchesToday: app.launchesToday + 1);
    });
    unawaited(
      familyRepo.recordAppLaunch(childId, appId).catchError((Object error) {
        debugPrint('Failed to record app launch: $error');
      }),
    );
    notifyListeners();
  }

  void updateAppCategory(String childId, String appId, AppCategory category) {
    _updateChildApp(childId, appId, (app) {
      return app.copyWith(category: category);
    });
    unawaited(
      familyRepo.updateAppCategory(childId, appId, category).catchError((
        Object error,
      ) {
        debugPrint('Failed to update app category: $error');
      }),
    );
    notifyListeners();
  }

  void _updateChildApp(
    String childId,
    String appId,
    UsageApp Function(UsageApp) transform,
  ) {
    final updatedChildren = <Child>[];
    for (final child in _family.children) {
      if (child.id == childId) {
        final updatedApps = <UsageApp>[];
        for (final app in child.apps) {
          if (app.id == appId) {
            updatedApps.add(transform(app));
          } else {
            updatedApps.add(app);
          }
        }
        updatedChildren.add(child.copyWith(apps: updatedApps));
      } else {
        updatedChildren.add(child);
      }
    }
    _family = _family.copyWith(children: updatedChildren);
  }

  // ---------------------------------------------------------------------------
  // Agreements
  // ---------------------------------------------------------------------------

  List<Agreement> agreementsFor(String childId) {
    final agreements =
        _agreements.where((entry) => entry.childId == childId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return agreements;
  }

  List<Agreement> get pendingRequests {
    final pending = _agreements.where((entry) => entry.isPending).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return pending;
  }

  Agreement? pendingRequestFor(String childId) {
    for (final agreement in agreementsFor(childId)) {
      if (agreement.isPending) return agreement;
    }
    return null;
  }

  Agreement? activeAgreementFor(String childId) {
    for (final agreement in agreementsFor(childId)) {
      if (agreement.isActive) return agreement;
    }
    return null;
  }

  Agreement? latestDeclinedFor(String childId) {
    for (final agreement in agreementsFor(childId)) {
      if (agreement.isDeclined) return agreement;
    }
    return null;
  }

  /// A child asks for a change; only the child can submit a child request.
  bool proposeAgreement(Agreement agreement) {
    if (!agreement.isPending) return false;
    if (agreement.proposedBy == UserRole.child) {
      if (!isChild || agreement.childId != _activeChildId) return false;
    }
    if (agreement.proposedBy == UserRole.parent && !isParent) return false;
    _agreements = [agreement, ..._agreements];
    unawaited(
      socialRepo.saveAgreement(agreement).catchError((Object error) {
        debugPrint('Failed to save agreement: $error');
      }),
    );
    notifyListeners();
    return true;
  }

  /// Only a parent can answer, and only while the request is still open.
  bool respondToAgreement(String id, AgreementStatus status, {String? note}) {
    if (!isParent) return false;
    if (status != AgreementStatus.active &&
        status != AgreementStatus.declined) {
      return false;
    }
    final index = _agreements.indexWhere((entry) => entry.id == id);
    if (index < 0 || !_agreements[index].isPending) return false;
    _agreements = [..._agreements];
    final updated = _agreements[index].copyWith(
      status: status,
      responseNote: note,
    );
    _agreements[index] = updated;
    unawaited(
      socialRepo.saveAgreement(updated).catchError((Object error) {
        debugPrint('Failed to respond to agreement: $error');
      }),
    );
    notifyListeners();
    return true;
  }

  // ---------------------------------------------------------------------------
  // Visibility
  // ---------------------------------------------------------------------------

  VisibilityLevel visibilityFor(String childId) =>
      _visibility[childId] ?? VisibilityLevel.trends;

  /// Parent-only. The child always sees their full own data.
  bool setVisibility(String childId, VisibilityLevel level) {
    if (!isParent) return false;
    _visibility = {..._visibility, childId: level};
    unawaited(
      socialRepo.setVisibility(childId, level).catchError((Object error) {
        debugPrint('Failed to set visibility: $error');
      }),
    );
    notifyListeners();
    return true;
  }

  // ---------------------------------------------------------------------------
  // Weekly ritual
  // ---------------------------------------------------------------------------

  void completeCheckIn(CheckInRecord record) {
    final sameWeek = _checkIns.where(
      (entry) =>
          entry.childId != record.childId ||
          _weekStart(entry.weekStart) != _weekStart(record.weekStart),
    );
    _checkIns = [record, ...sameWeek]
      ..sort((a, b) => b.weekStart.compareTo(a.weekStart));
    unawaited(
      socialRepo.saveCheckIn(record).catchError((Object error) {
        debugPrint('Failed to save check in: $error');
      }),
    );
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Data Export & Sibling Management
  // ---------------------------------------------------------------------------

  /// Exports all family data (profiles, apps, usage, agreements, notes, and check-ins)
  /// as a structured JSON object.
  Map<String, dynamic> exportFamilyData() {
    return {
      'version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'family': {
        'name': familyName,
        'parentName': parentName,
        'parentEmail': parentEmail,
      },
      'children': [
        for (final child in children)
          {
            'id': child.id,
            'name': child.name,
            'age': child.age,
            'visibility': visibilityFor(child.id).name,
            'todayMinutes': child.todayMinutes,
            'unlocksToday': child.unlocksToday,
            'notificationsToday': child.notificationsToday,
            'apps': [for (final app in child.apps) app.toJson()],
            'notes': [for (final note in notesFor(child.id)) note.toJson()],
            'agreements': [
              for (final agr in agreementsFor(child.id)) agr.toJson(),
            ],
          },
      ],
      'checkIns': [for (final c in checkInHistory) c.toJson()],
    };
  }

  /// Saves a child profile to the in-memory family and persists it to SQLite/Repository.
  Future<void> saveChild(Child child, {String? pin}) async {
    final existingIndex = _family.children.indexWhere((c) => c.id == child.id);
    final updatedChildren = <Child>[..._family.children];
    if (existingIndex >= 0) {
      updatedChildren[existingIndex] = child;
    } else {
      updatedChildren.add(child);
    }
    _family = _family.copyWith(children: updatedChildren);
    notifyListeners();

    try {
      if (familyRepo is SqliteFamilyRepository) {
        final appDb = database ?? await AppDatabase.getInstance();
        await ChildDao(appDb.db).saveChild(child, pin: pin);
      } else {
        await familyRepo.saveChild(child);
      }
    } catch (error) {
      debugPrint('Failed to save child: $error');
    }
  }

  // ---------------------------------------------------------------------------
  // Demo lifecycle
  // ---------------------------------------------------------------------------

  Future<void> resetDemoData() async {
    _role = null;
    _activeChildId = null;
    _signedInAs = null;
    _authError = null;
    ai.setApiKey(null);
    _notificationsEnabled = true;
    _includeParentUsage = false;

    if (socialRepo is SqliteSocialRepository ||
        familyRepo is SqliteFamilyRepository) {
      _family = DemoData.buildSingleChild();
      _seedSocial(DemoSocial.buildSingleChild());
      notifyListeners();
      try {
        final appDb = database ?? await AppDatabase.getInstance();
        await DbSchema.resetForDemo(appDb.db);
        await DbSeedData.seed(appDb.db);
        final family = await familyRepo.getFamily();
        final socialSeed = await socialRepo.loadInitialData();
        _family = family;
        _seedSocial(socialSeed);
        notifyListeners();
      } catch (error) {
        debugPrint('Failed to reset SQLite demo data: $error');
      }
    } else {
      _family = DemoData.build();
      _seedSocial(DemoSocial.build());
      notifyListeners();
    }
  }

  void _seedSocial(SocialSeed seed) {
    _notes = List.unmodifiable(seed.notes);
    _agreements = List.unmodifiable(seed.agreements);
    _visibility = Map.unmodifiable(seed.visibility);
    _checkIns = seed.lastCheckIn == null
        ? const []
        : List.unmodifiable([seed.lastCheckIn!]);
    _parentTodayMinutes = seed.parentTodayMinutes;
    _parentWeekMinutes = seed.parentWeekMinutes;
  }

  static DateTime _weekStart(DateTime date) => startOfWeek(date);

  /// The child whose day changed the most since yesterday. Used for the
  /// "worth a look" card; positive changes are prioritised.
  Child? get childNeedingAttention {
    if (children.isEmpty) return null;
    final sorted = [...children]
      ..sort((a, b) => b.dayOverDay.ratio.compareTo(a.dayOverDay.ratio));
    return sorted.first;
  }

  int get familyTodayMinutes =>
      children.fold(0, (total, child) => total + child.todayMinutes);

  int get familyYesterdayMinutes =>
      children.fold(0, (total, child) => total + child.yesterdayMinutes);

  int get familyWeekMinutes =>
      children.fold(0, (total, child) => total + child.weekMinutes);

  /// Minutes per day for the last seven days across every child.
  ///
  /// A child with a partial sync has fewer than seven entries; missing days
  /// contribute zero instead of indexing past the end.
  List<int> get familyWeekByDay => [
    for (var day = 0; day < 7; day++)
      children.fold(
        0,
        (total, child) =>
            total +
            (day < child.last7Days.length ? child.last7Days[day].minutes : 0),
      ),
  ];

  int get familyWeeklyAverage => children.isEmpty
      ? 0
      : (familyWeekMinutes / (children.length * 7)).round();

  int get wholeFamilyToday =>
      familyTodayMinutes + (_includeParentUsage ? _parentTodayMinutes : 0);

  int get familyWeekTotal =>
      familyWeekByDay.fold(0, (total, minutes) => total + minutes);

  double get familyDayRatio => familyYesterdayMinutes == 0
      ? 0.0
      : (familyTodayMinutes - familyYesterdayMinutes) / familyYesterdayMinutes;

  int get previousFamilyWeekMinutes =>
      children.fold(0, (total, child) => total + child.previousWeekMinutes);

  double get familyWeekRatio {
    final prev = previousFamilyWeekMinutes;
    return prev == 0 ? 0.0 : (familyWeekTotal - prev) / prev;
  }

  /// Dispatches all pending local changes to the cloud sync service.
  Future<SyncResult?> syncPendingChanges() async {
    if (syncService == null) return null;
    final result = await syncService!.syncPending();
    notifyListeners();
    return result;
  }

  /// Whether sync is online.
  bool get isSyncOnline => syncService?.isOnline ?? true;

  /// Sets sync online/offline state.
  set isSyncOnline(bool value) {
    if (syncService != null && syncService!.isOnline != value) {
      syncService!.isOnline = value;
      notifyListeners();
    }
  }

  /// Number of sync operations currently pending in outbox.
  Future<int> get pendingSyncCount =>
      syncService?.getPendingCount() ?? Future.value(0);
}
