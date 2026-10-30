import 'package:flutter/foundation.dart';

import '../data/demo_credentials.dart';
import '../l10n/app_strings.dart';
import '../models/user_role.dart';

/// A verified sign-in. The role comes from the authentication result, never
/// from a widget parameter.
///
/// There is deliberately no token here: the demo has no session server, and a
/// locally invented token would only invite code to trust it.
class AuthSession {
  const AuthSession({required this.role, required this.identity, this.childId});

  final UserRole role;
  final String identity;
  final String? childId;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    role: UserRole.values.firstWhere(
      (r) => r.name == json['role'],
      orElse: () => UserRole.parent,
    ),
    identity: json['identity'] as String,
    childId: json['childId'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'role': role.name,
    'identity': identity,
    'childId': childId,
  };
}

/// A failure that is safe to show to a person.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class AuthService {
  Future<AuthSession> signInParent({
    required String email,
    required String password,
    AppStrings strings = AppStrings.english,
  });

  Future<AuthSession> signInChild({
    required String childId,
    required String pin,
    AppStrings strings = AppStrings.english,
  });
}

/// When `false`, this build has no authentication backend and refuses every
/// sign-in instead of silently granting access.
///
/// Demo access defaults on for debug/profile runs and is always off in release
/// builds, even if `DEMO_MODE=true` is passed at compile time, so a distributed
/// binary can never accept the public demo password. Pass
/// `--dart-define=DEMO_MODE=false` to disable it in debug as well.
const bool demoAuthEnabled =
    !kReleaseMode &&
    (bool.hasEnvironment('DEMO_MODE')
        ? bool.fromEnvironment('DEMO_MODE')
        : true);

AuthService defaultAuthService() =>
    demoAuthEnabled ? DemoAuthService() : const UnconfiguredAuthService();

/// Local credential check for the sandboxed demo.
///
/// The explicit `signInDemo…` methods back the "Use demo account" affordance on
/// the login screen. They intentionally skip the credential check, so the UI
/// labels them as demo entry points rather than pretending to authenticate.
class DemoAuthService implements AuthService {
  DemoAuthService({
    DemoCredentials? credentials,
    this.latency = const Duration(milliseconds: 700),
  }) : credentials = credentials ?? DemoCredentials.instance;

  final DemoCredentials credentials;
  final Duration latency;

  @override
  Future<AuthSession> signInParent({
    required String email,
    required String password,
    AppStrings strings = AppStrings.english,
  }) async {
    await _wait();
    final matchesEmail =
        email.trim().toLowerCase() == credentials.parentEmail.toLowerCase();
    if (!matchesEmail || password != credentials.parentPassword) {
      throw AuthException(strings.signInWrongDemoParent);
    }
    return _parentSession();
  }

  @override
  Future<AuthSession> signInChild({
    required String childId,
    required String pin,
    AppStrings strings = AppStrings.english,
  }) async {
    await _wait();
    if (pin.trim() != credentials.childPin) {
      throw AuthException(strings.signInWrongChildPin);
    }
    return AuthSession(
      role: UserRole.child,
      identity: childId,
      childId: childId,
    );
  }

  Future<AuthSession> signInDemoParent() async {
    await _wait();
    return _parentSession();
  }

  Future<AuthSession> signInDemoChild({required String childId}) async {
    await _wait();
    return AuthSession(
      role: UserRole.child,
      identity: childId,
      childId: childId,
    );
  }

  AuthSession _parentSession() =>
      AuthSession(role: UserRole.parent, identity: credentials.parentEmail);

  Future<void> _wait() async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
  }
}

/// Used when `DEMO_MODE=false` and no real backend has been wired up yet.
class UnconfiguredAuthService implements AuthService {
  const UnconfiguredAuthService();

  @override
  Future<AuthSession> signInParent({
    required String email,
    required String password,
    AppStrings strings = AppStrings.english,
  }) => throw AuthException(strings.signInMissingConfig);

  @override
  Future<AuthSession> signInChild({
    required String childId,
    required String pin,
    AppStrings strings = AppStrings.english,
  }) => throw AuthException(strings.signInMissingConfig);
}
