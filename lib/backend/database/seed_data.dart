import 'dart:convert' show jsonEncode;

import 'package:flutter/material.dart' show Color, Icons;
import 'package:sqflite/sqflite.dart';

import '../../models/agreement.dart';
import '../../models/app_usage.dart';
import '../../models/context_note.dart';
import '../../models/user_role.dart';
import '../../models/visibility.dart';
import '../../utils/clock.dart';
import '../../utils/dates.dart';
import 'credential_hasher.dart';

/// Seeded demo content.
///
/// DEMO ONLY: the constants below are the sandbox credentials printed on the
/// login screen. They are hashed before they reach SQLite, so the database file
/// never contains a readable password or PIN, but this is still a local demo
/// check and not a real authentication backend.
abstract final class DbSeedData {
  static const String testParentId = 'user-sarah';
  static const String testParentEmail = 'parent@parentify.dev';
  static const String testParentPassword = 'Parentify2026!';
  static const String testParentName = 'Sarah';
  static const String testFamilyName = 'Miller Family';

  static const String testChildId = 'leo';
  static const String testChildName = 'Leo';
  static const String testChildPin = '2026';
  static const int testChildAge = 11;

  static Future<void> seed(Database db) async {
    // Check if already seeded
    final existing = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [testParentEmail],
    );
    if (existing.isNotEmpty) return;

    final batch = db.batch();
    final now = AppClock.now();
    final today = dateOnly(now);
    final parentSalt = CredentialHasher.newSalt();
    final childSalt = CredentialHasher.newSalt();

    // 1. Insert 1 Parent test account
    batch.insert('users', {
      'id': testParentId,
      'email': testParentEmail,
      'password_hash': CredentialHasher.digest(
        testParentPassword,
        salt: parentSalt,
      ),
      'password_salt': parentSalt,
      'name': testParentName,
      'role': UserRole.parent.name,
      'family_name': testFamilyName,
      'created_at': now.toIso8601String(),
    });

    // 2. Insert 1 Child test account (Leo)
    batch.insert('children', {
      'id': testChildId,
      'parent_id': testParentId,
      'name': testChildName,
      'age': testChildAge,
      'device_name': "Leo's iPhone 13",
      'platform': 'ios',
      'accent_color': const Color(0xFF5B67CA).toARGB32(),
      'pin_hash': CredentialHasher.digest(testChildPin, salt: childSalt),
      'pin_salt': childSalt,
      'visibility': VisibilityLevel.guided.name,
      'unlocks_today': 32,
      'notifications_today': 18,
      'last_synced_at': now
          .subtract(const Duration(minutes: 6))
          .toIso8601String(),
    });

    // 3. Child Installed Apps & Usage History
    final apps = [
      {
        'id': 'duolingo',
        'name': 'Duolingo',
        'category': AppCategory.education.name,
        'color_value': const Color(0xFF58CC02).toARGB32(),
        'icon_code_point': Icons.school_rounded.codePoint,
        'last7_days_json': jsonEncode([30, 25, 35, 40, 20, 30, 35]),
        'launches_today': 3,
      },
      {
        'id': 'youtube_kids',
        'name': 'YouTube Kids',
        'category': AppCategory.video.name,
        'color_value': const Color(0xFFFF0000).toARGB32(),
        'icon_code_point': Icons.smart_display_rounded.codePoint,
        'last7_days_json': jsonEncode([45, 50, 40, 60, 55, 65, 45]),
        'launches_today': 5,
      },
      {
        'id': 'minecraft',
        'name': 'Minecraft',
        'category': AppCategory.gaming.name,
        'color_value': const Color(0xFF4C8C2B).toARGB32(),
        'icon_code_point': Icons.sports_esports_rounded.codePoint,
        'last7_days_json': jsonEncode([60, 45, 55, 70, 80, 90, 50]),
        'launches_today': 2,
      },
      {
        'id': 'messages',
        'name': 'Messages',
        'category': AppCategory.messaging.name,
        'color_value': const Color(0xFF34C759).toARGB32(),
        'icon_code_point': Icons.chat_bubble_rounded.codePoint,
        'last7_days_json': jsonEncode([15, 20, 18, 22, 25, 30, 20]),
        'launches_today': 12,
      },
      {
        'id': 'spotify',
        'name': 'Spotify',
        'category': AppCategory.creativity.name,
        'color_value': const Color(0xFF1DB954).toARGB32(),
        'icon_code_point': Icons.headphones_rounded.codePoint,
        'last7_days_json': jsonEncode([25, 30, 20, 35, 40, 45, 25]),
        'launches_today': 4,
      },
    ];

    for (final app in apps) {
      batch.insert('child_apps', {
        'id': app['id'],
        'child_id': testChildId,
        'name': app['name'],
        'category': app['category'],
        'color_value': app['color_value'],
        'icon_code_point': app['icon_code_point'],
        'last7_days_json': app['last7_days_json'],
        'launches_today': app['launches_today'],
      });
    }

    // 4. Daily Usage History (last 14 days)
    final dailyMinutes = [
      135,
      140,
      155,
      150,
      165,
      180,
      175,
      175,
      170,
      168,
      227,
      220,
      260,
      175,
    ];
    for (var i = 0; i < 14; i++) {
      final date = addDays(today, i - 13);
      batch.insert('daily_usages', {
        'child_id': testChildId,
        'date': date.toIso8601String(),
        'minutes': dailyMinutes[i],
        'unlocks': 25 + (i * 2 % 15),
      });
    }

    // 5. Hourly Usage for Today (24 hours)
    final hourlyDistribution = [
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      10,
      15,
      5,
      0,
      0,
      15,
      20,
      10,
      15,
      25,
      35,
      20,
      10,
      0,
      0,
      0,
      0,
    ];
    for (var h = 0; h < 24; h++) {
      batch.insert('hourly_usages', {
        'child_id': testChildId,
        'hour': h,
        'minutes': hourlyDistribution[h],
      });
    }

    // 6. Usage Sessions (longest stretches)
    batch.insert('usage_sessions', {
      'id': 'sess-leo-1',
      'child_id': testChildId,
      'start_time': today
          .add(const Duration(hours: 16, minutes: 15))
          .toIso8601String(),
      'minutes': 48,
      'label': 'Minecraft & Creative building',
      'category': AppCategory.gaming.name,
      'apps_json': jsonEncode(['Minecraft', 'Spotify']),
    });

    batch.insert('usage_sessions', {
      'id': 'sess-leo-2',
      'child_id': testChildId,
      'start_time': today
          .add(const Duration(hours: 13, minutes: 30))
          .toIso8601String(),
      'minutes': 35,
      'label': 'Spanish practice & Science video',
      'category': AppCategory.education.name,
      'apps_json': jsonEncode(['Duolingo', 'YouTube Kids']),
    });

    // 7. Agreements
    batch.insert('agreements', {
      'id': 'agr-leo-1',
      'child_id': testChildId,
      'kind': AgreementKind.bedtime.name,
      'title': 'Screens away by 8:30 PM',
      'detail': 'Device stays on the hallway charger before lights out.',
      'status': AgreementStatus.active.name,
      'proposed_by': UserRole.parent.name,
      'created_at': now.subtract(const Duration(days: 5)).toIso8601String(),
      'response_note': 'Agreed together on Sunday.',
    });

    batch.insert('agreements', {
      'id': 'agr-leo-2',
      'child_id': testChildId,
      'kind': AgreementKind.flexDay.name,
      'title': 'Saturday extra Minecraft with friends',
      'detail': 'Add 45 minutes on Saturday after finishing science homework.',
      'status': AgreementStatus.proposed.name,
      'proposed_by': UserRole.child.name,
      'created_at': now.subtract(const Duration(hours: 4)).toIso8601String(),
      'response_note': null,
    });

    // 8. Context Notes
    batch.insert('context_notes', {
      'id': 'note-leo-1',
      'child_id': testChildId,
      'created_at': now.subtract(const Duration(hours: 3)).toIso8601String(),
      'author': UserRole.child.name,
      'tag': NoteTag.school.name,
      'text': 'Watched Spanish tutorial videos for homework project.',
      'scope': NoteScope.day.name,
      'target_id': null,
    });

    batch.insert('context_notes', {
      'id': 'note-leo-2',
      'child_id': testChildId,
      'created_at': now.subtract(const Duration(days: 1)).toIso8601String(),
      'author': UserRole.parent.name,
      'tag': NoteTag.family.name,
      'text': 'Family movie night; put screens away early.',
      'scope': NoteScope.day.name,
      'target_id': null,
    });

    // 9. Check-In Record
    batch.insert('check_in_records', {
      'id': 'checkin-leo-1',
      'child_id': testChildId,
      'week_start': addDays(today, -6).toIso8601String(),
      'topic': 'Digital balance & sleep quality',
      'question': 'How refreshed did you feel in the mornings this week?',
      'completed_at': now.subtract(const Duration(days: 6)).toIso8601String(),
    });

    await batch.commit(noResult: true);
  }
}
