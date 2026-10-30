import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Salted SHA-256 digests for the demo's local SQLite credentials.
///
/// This keeps a readable password or PIN out of the database file, which is
/// otherwise recoverable from a device backup. It is deliberately *not* a
/// production password KDF: a real backend must use Argon2id, scrypt, or
/// PBKDF2 with a per-user salt and a work factor, and must never ship the
/// credential check inside the client.
abstract final class CredentialHasher {
  /// Creates a fresh 128-bit salt, hex encoded.
  static String newSalt([Random? random]) {
    final source = random ?? Random.secure();
    final bytes = List<int>.generate(16, (_) => source.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static String digest(String value, {required String salt}) =>
      sha256.convert(utf8.encode('$salt:$value')).toString();

  /// Compares a candidate against a stored digest in constant time, so a
  /// near-miss cannot be distinguished by how long the check takes.
  static bool verify(
    String value, {
    required String salt,
    required String expected,
  }) => _constantTimeEquals(digest(value, salt: salt), expected);

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var difference = 0;
    for (var i = 0; i < a.length; i++) {
      difference |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return difference == 0;
  }
}
