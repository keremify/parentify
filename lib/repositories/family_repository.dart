import '../data/demo_data.dart';
import '../models/app_usage.dart';
import '../models/child.dart';

/// Abstract repository defining access to family members and usage data.
///
/// Can be backed by [DemoFamilyRepository] for offline use, or an
/// HTTP/GraphQL/Supabase implementation when connected to a backend.
abstract interface class FamilyRepository {
  Future<DemoFamily> getFamily();
  Future<Child?> getChildById(String id);
  Future<void> recordAppLaunch(String childId, String appId);
  Future<void> updateAppCategory(
    String childId,
    String appId,
    AppCategory category,
  );
  Future<void> recordDailyUsage(String childId, DailyUsage usage);
  Future<void> recordUsageSession(String childId, UsageSession session);
  Future<void> updateChildMetrics(
    String childId, {
    int? unlocksToday,
    int? notificationsToday,
    DateTime? lastSyncedAt,
  });
  Future<void> saveChild(Child child);
}

/// In-memory demo implementation of [FamilyRepository].
class DemoFamilyRepository implements FamilyRepository {
  DemoFamilyRepository({DemoFamily? family})
    : _family = family ?? DemoData.build();

  final DemoFamily _family;

  @override
  Future<DemoFamily> getFamily() async => _family;

  @override
  Future<Child?> getChildById(String id) async {
    for (final child in _family.children) {
      if (child.id == id) return child;
    }
    return null;
  }

  @override
  Future<void> recordAppLaunch(String childId, String appId) async {}

  @override
  Future<void> updateAppCategory(
    String childId,
    String appId,
    AppCategory category,
  ) async {}

  @override
  Future<void> recordDailyUsage(String childId, DailyUsage usage) async {}

  @override
  Future<void> recordUsageSession(String childId, UsageSession session) async {}

  @override
  Future<void> updateChildMetrics(
    String childId, {
    int? unlocksToday,
    int? notificationsToday,
    DateTime? lastSyncedAt,
  }) async {}

  @override
  Future<void> saveChild(Child child) async {}
}
