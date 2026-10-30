import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:flutter/material.dart' show Color, IconData;
import 'package:sqflite/sqflite.dart';

import '../../models/app_usage.dart';
import '../../models/child.dart';
import '../../models/visibility.dart';
import '../database/credential_hasher.dart';
import '../database/seed_data.dart';

class ChildDao {
  const ChildDao(this.db);

  final Database db;

  Future<List<Child>> getAllChildren() async {
    final childRows = await db.query('children', orderBy: 'name ASC');
    final children = <Child>[];

    for (final row in childRows) {
      final childId = row['id'] as String;

      // 1. Apps
      final appRows = await db.query(
        'child_apps',
        where: 'child_id = ?',
        whereArgs: [childId],
        orderBy: 'launches_today DESC',
      );
      final apps = [
        for (final app in appRows)
          UsageApp(
            id: app['id'] as String,
            name: app['name'] as String,
            category: AppCategory.values.firstWhere(
              (c) => c.name == app['category'],
              orElse: () => AppCategory.utilities,
            ),
            icon: IconData(
              // ignore: non_const_argument_for_const_parameter
              app['icon_code_point'] as int,
              fontFamily: 'MaterialIcons',
            ),
            color: Color(app['color_value'] as int),
            last7Days: (jsonDecode(app['last7_days_json'] as String) as List)
                .map((e) => (e as num).toInt())
                .toList(),
            launchesToday: app['launches_today'] as int,
          ),
      ];

      // 2. Daily history (oldest first)
      final dailyRows = await db.query(
        'daily_usages',
        where: 'child_id = ?',
        whereArgs: [childId],
        orderBy: 'date ASC',
      );
      final days = [
        for (final d in dailyRows)
          DailyUsage(
            date: DateTime.parse(d['date'] as String),
            minutes: d['minutes'] as int,
            unlocks: d['unlocks'] as int,
          ),
      ];

      // 3. Hourly today (0..23)
      final hourlyRows = await db.query(
        'hourly_usages',
        where: 'child_id = ?',
        whereArgs: [childId],
        orderBy: 'hour ASC',
      );
      final hourlyToday = List<int>.filled(24, 0);
      for (final h in hourlyRows) {
        final hour = h['hour'] as int;
        if (hour >= 0 && hour < 24) {
          hourlyToday[hour] = h['minutes'] as int;
        }
      }

      // 4. Usage Sessions
      final sessionRows = await db.query(
        'usage_sessions',
        where: 'child_id = ?',
        whereArgs: [childId],
        orderBy: 'start_time DESC',
      );
      final sessions = [
        for (final s in sessionRows)
          UsageSession(
            id: s['id'] as String,
            start: DateTime.parse(s['start_time'] as String),
            minutes: s['minutes'] as int,
            label: s['label'] as String,
            category: AppCategory.values.firstWhere(
              (c) => c.name == s['category'],
              orElse: () => AppCategory.utilities,
            ),
            apps: (jsonDecode(s['apps_json'] as String) as List).cast<String>(),
          ),
      ];

      final platformStr = row['platform'] as String;
      final platform = platformStr == 'android'
          ? DevicePlatform.android
          : DevicePlatform.ios;

      children.add(
        Child(
          id: childId,
          name: row['name'] as String,
          age: row['age'] as int,
          deviceName: row['device_name'] as String,
          platform: platform,
          accent: Color(row['accent_color'] as int),
          apps: apps,
          days: days,
          hourlyToday: hourlyToday,
          sessions: sessions,
          unlocksToday: row['unlocks_today'] as int,
          notificationsToday: row['notifications_today'] as int,
          lastSyncedAt: DateTime.parse(row['last_synced_at'] as String),
        ),
      );
    }

    return children;
  }

  Future<Child?> getChildById(String id) async {
    final all = await getAllChildren();
    for (final child in all) {
      if (child.id == id) return child;
    }
    return null;
  }

  Future<void> updateVisibility(String childId, VisibilityLevel level) async {
    await db.update(
      'children',
      {'visibility': level.name},
      where: 'id = ?',
      whereArgs: [childId],
    );
  }

  Future<Map<String, VisibilityLevel>> getVisibilityMap() async {
    final rows = await db.query('children', columns: ['id', 'visibility']);
    final map = <String, VisibilityLevel>{};
    for (final row in rows) {
      final id = row['id'] as String;
      final visStr = row['visibility'] as String;
      map[id] = VisibilityLevel.values.firstWhere(
        (v) => v.name == visStr,
        orElse: () => VisibilityLevel.guided,
      );
    }
    return map;
  }

  Future<void> recordAppLaunch(String childId, String appId) async {
    await db.rawUpdate(
      'UPDATE child_apps SET launches_today = launches_today + 1 WHERE child_id = ? AND id = ?',
      [childId, appId],
    );
  }

  Future<void> updateAppCategory(
    String childId,
    String appId,
    AppCategory category,
  ) async {
    await db.update(
      'child_apps',
      {'category': category.name},
      where: 'child_id = ? AND id = ?',
      whereArgs: [childId, appId],
    );
  }

  Future<void> recordDailyUsage(String childId, DailyUsage usage) async {
    final dateStr = usage.date.toIso8601String().substring(0, 10);
    await db.insert('daily_usages', {
      'child_id': childId,
      'date': dateStr,
      'minutes': usage.minutes,
      'unlocks': usage.unlocks,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> recordHourlyUsage(String childId, int hour, int minutes) async {
    await db.insert('hourly_usages', {
      'child_id': childId,
      'hour': hour,
      'minutes': minutes,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> recordUsageSession(String childId, UsageSession session) async {
    await db.insert('usage_sessions', {
      'id': session.id,
      'child_id': childId,
      'start_time': session.start.toIso8601String(),
      'minutes': session.minutes,
      'label': session.label,
      'category': session.category.name,
      'apps_json': jsonEncode(session.apps),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateChildMetrics(
    String childId, {
    int? unlocksToday,
    int? notificationsToday,
    DateTime? lastSyncedAt,
  }) async {
    final values = <String, Object?>{};
    if (unlocksToday != null) values['unlocks_today'] = unlocksToday;
    if (notificationsToday != null) {
      values['notifications_today'] = notificationsToday;
    }
    if (lastSyncedAt != null) {
      values['last_synced_at'] = lastSyncedAt.toIso8601String();
    }
    if (values.isNotEmpty) {
      await db.update(
        'children',
        values,
        where: 'id = ?',
        whereArgs: [childId],
      );
    }
  }

  Future<void> saveChild(
    Child child, {
    String parentId = DbSeedData.testParentId,
    String? pin,
  }) async {
    // Preserve values the child model does not carry: the PIN hash/salt, the chosen
    // visibility level and the owning parent. Replacing the row would reset
    // them (and cascade-delete child-owned data on a real foreign-key setup).
    final existing = await db.query(
      'children',
      columns: ['parent_id', 'pin_hash', 'pin_salt', 'visibility'],
      where: 'id = ?',
      whereArgs: [child.id],
      limit: 1,
    );
    final prior = existing.isEmpty ? null : existing.first;

    final String pinSalt;
    final String pinHash;
    if (prior != null &&
        prior['pin_hash'] != null &&
        prior['pin_salt'] != null) {
      pinHash = prior['pin_hash']! as String;
      pinSalt = prior['pin_salt']! as String;
    } else {
      pinSalt = CredentialHasher.newSalt();
      pinHash = CredentialHasher.digest(
        pin ?? DbSeedData.testChildPin,
        salt: pinSalt,
      );
    }

    final batch = db.batch();
    final values = <String, Object?>{
      'id': child.id,
      'parent_id': prior?['parent_id'] as String? ?? parentId,
      'name': child.name,
      'age': child.age,
      'device_name': child.deviceName,
      'platform': child.platform.name,
      'accent_color': child.accent.toARGB32(),
      'pin_hash': pinHash,
      'pin_salt': pinSalt,
      'visibility':
          prior?['visibility'] as String? ?? VisibilityLevel.guided.name,
      'unlocks_today': child.unlocksToday,
      'notifications_today': child.notificationsToday,
      'last_synced_at': child.lastSyncedAt.toIso8601String(),
    };
    if (prior == null) {
      batch.insert('children', values);
    } else {
      batch.update('children', values, where: 'id = ?', whereArgs: [child.id]);
    }

    // 2. Apps
    for (final app in child.apps) {
      batch.insert('child_apps', {
        'id': app.id,
        'child_id': child.id,
        'name': app.name,
        'category': app.category.name,
        'color_value': app.color.toARGB32(),
        'icon_code_point': app.icon.codePoint,
        'last7_days_json': jsonEncode(app.last7Days),
        'launches_today': app.launchesToday,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // 3. Daily usages
    for (final day in child.days) {
      batch.insert('daily_usages', {
        'child_id': child.id,
        'date': day.date.toIso8601String().substring(0, 10),
        'minutes': day.minutes,
        'unlocks': day.unlocks,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // 4. Hourly usages
    for (var h = 0; h < child.hourlyToday.length; h++) {
      batch.insert('hourly_usages', {
        'child_id': child.id,
        'hour': h,
        'minutes': child.hourlyToday[h],
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // 5. Usage sessions
    for (final s in child.sessions) {
      batch.insert('usage_sessions', {
        'id': s.id,
        'child_id': child.id,
        'start_time': s.start.toIso8601String(),
        'minutes': s.minutes,
        'label': s.label,
        'category': s.category.name,
        'apps_json': jsonEncode(s.apps),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }
}
