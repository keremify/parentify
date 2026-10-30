import 'package:sqflite/sqflite.dart';

import '../../models/user_role.dart';
import '../database/credential_hasher.dart';

class UserRecord {
  const UserRecord({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.passwordSalt,
    required this.name,
    required this.role,
    required this.familyName,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String passwordHash;
  final String passwordSalt;
  final String name;
  final UserRole role;
  final String familyName;
  final DateTime createdAt;

  factory UserRecord.fromRow(Map<String, dynamic> row) => UserRecord(
    id: row['id'] as String,
    email: row['email'] as String,
    passwordHash: row['password_hash'] as String,
    passwordSalt: row['password_salt'] as String,
    name: row['name'] as String,
    role: UserRole.values.firstWhere(
      (r) => r.name == row['role'],
      orElse: () => UserRole.parent,
    ),
    familyName: row['family_name'] as String,
    createdAt: DateTime.parse(row['created_at'] as String),
  );
}

class UserDao {
  const UserDao(this.db);

  final Database db;

  Future<UserRecord?> findUserByEmail(String email) async {
    final rows = await db.query(
      'users',
      where: 'LOWER(email) = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserRecord.fromRow(rows.first);
  }

  Future<UserRecord?> verifyParentCredentials({
    required String email,
    required String password,
  }) async {
    final user = await findUserByEmail(email);
    if (user == null) return null;
    final matches = CredentialHasher.verify(
      password,
      salt: user.passwordSalt,
      expected: user.passwordHash,
    );
    return matches ? user : null;
  }

  Future<bool> verifyChildPin({
    required String childId,
    required String pin,
  }) async {
    // Fetch by id only, then compare in Dart. Matching on the secret in SQL
    // would leak through query plans and logs.
    final rows = await db.query(
      'children',
      columns: ['pin_hash', 'pin_salt'],
      where: 'id = ?',
      whereArgs: [childId],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    final hash = rows.first['pin_hash'] as String?;
    final salt = rows.first['pin_salt'] as String?;
    if (hash == null || salt == null) return false;
    return CredentialHasher.verify(pin.trim(), salt: salt, expected: hash);
  }

  Future<Map<String, String>?> getFamilyMeta() async {
    final rows = await db.query('users', limit: 1);
    if (rows.isEmpty) return null;
    final row = rows.first;
    return {
      'parentName': row['name'] as String,
      'parentEmail': row['email'] as String,
      'familyName': row['family_name'] as String,
    };
  }
}
