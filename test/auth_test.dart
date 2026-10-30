import 'package:flutter_test/flutter_test.dart';

import 'package:parentify/data/demo_credentials.dart';
import 'package:parentify/data/demo_data.dart';
import 'package:parentify/l10n/app_strings.dart';
import 'package:parentify/services/auth_service.dart';
import 'package:parentify/state/app_state.dart';

final _credentials = DemoCredentials.instance;

AppState _state({AuthService? auth}) => AppState(
  family: DemoData.build(),
  auth: auth ?? DemoAuthService(latency: Duration.zero),
);

class _BrokenAuthService implements AuthService {
  const _BrokenAuthService();

  @override
  Future<AuthSession> signInParent({
    required String email,
    required String password,
    AppStrings strings = AppStrings.english,
  }) => throw StateError('backend exploded');

  @override
  Future<AuthSession> signInChild({
    required String childId,
    required String pin,
    AppStrings strings = AppStrings.english,
  }) => throw StateError('backend exploded');
}

void main() {
  group('Parent sign-in', () {
    test('accepts the demo credentials and sets the parent role', () async {
      final state = _state();
      addTearDown(state.dispose);

      final ok = await state.signInParent(
        email: _credentials.parentEmail,
        password: _credentials.parentPassword,
      );

      expect(ok, isTrue);
      expect(state.isSignedIn, isTrue);
      expect(state.isParent, isTrue);
      expect(state.activeChild, isNull);
      expect(state.authError, isNull);
      expect(state.signedInAs, _credentials.parentEmail);
    });

    test('normalizes case and surrounding whitespace in the email', () async {
      final state = _state();
      addTearDown(state.dispose);

      final ok = await state.signInParent(
        email: '  ${_credentials.parentEmail.toUpperCase()} ',
        password: _credentials.parentPassword,
      );

      expect(ok, isTrue);
      expect(state.isParent, isTrue);
    });

    test('rejects a wrong password without signing in', () async {
      final state = _state();
      addTearDown(state.dispose);

      final ok = await state.signInParent(
        email: _credentials.parentEmail,
        password: 'not-the-password',
      );

      expect(ok, isFalse);
      expect(state.isSignedIn, isFalse);
      expect(state.authError, contains('do not match'));
    });

    test('rejects a wrong email without signing in', () async {
      final state = _state();
      addTearDown(state.dispose);

      final ok = await state.signInParent(
        email: 'someone@example.com',
        password: _credentials.parentPassword,
      );

      expect(ok, isFalse);
      expect(state.isSignedIn, isFalse);
      expect(state.authError, isNotNull);
    });

    test('does not sign in an empty password', () async {
      final state = _state();
      addTearDown(state.dispose);

      final ok = await state.signInParent(
        email: _credentials.parentEmail,
        password: '',
      );

      expect(ok, isFalse);
      expect(state.isSignedIn, isFalse);
    });
  });

  group('Child sign-in', () {
    test('accepts the demo PIN for an existing profile', () async {
      final state = _state();
      addTearDown(state.dispose);

      final ok = await state.signInChild(
        childId: 'ada',
        pin: _credentials.childPin,
      );

      expect(ok, isTrue);
      expect(state.isChild, isTrue);
      expect(state.isParent, isFalse);
      expect(state.activeChild?.id, 'ada');
    });

    test('rejects a wrong PIN', () async {
      final state = _state();
      addTearDown(state.dispose);

      final ok = await state.signInChild(childId: 'ada', pin: '0000');

      expect(ok, isFalse);
      expect(state.isSignedIn, isFalse);
      expect(state.authError, contains('PIN'));
    });

    test('rejects a profile that is not in the family', () async {
      final state = _state();
      addTearDown(state.dispose);

      final ok = await state.signInChild(
        childId: 'not-a-child',
        pin: _credentials.childPin,
      );

      expect(ok, isFalse);
      expect(state.isSignedIn, isFalse);
      expect(state.authError, contains('no longer available'));
    });

    test('a child session cannot act as a parent', () async {
      final state = _state();
      addTearDown(state.dispose);

      await state.signInChild(childId: 'ada', pin: _credentials.childPin);

      expect(state.isChild, isTrue);
      expect(state.isParent, isFalse);
      // Parent-only mutations reject a child session.
      expect(state.setVisibility('mert', state.visibilityFor('mert')), isFalse);
    });
  });

  group('Demo entry points', () {
    test('are available with the demo service', () async {
      final state = _state();
      addTearDown(state.dispose);

      expect(state.demoAuthAvailable, isTrue);
      final ok = await state.signInDemoParent();

      expect(ok, isTrue);
      expect(state.isParent, isTrue);
    });

    test('are unavailable with a real (unconfigured) service', () async {
      final state = _state(auth: const UnconfiguredAuthService());
      addTearDown(state.dispose);

      expect(state.demoAuthAvailable, isFalse);
      final ok = await state.signInDemoParent();

      expect(ok, isFalse);
      expect(state.isSignedIn, isFalse);
    });
  });

  group('Unconfigured builds', () {
    test('refuse parent sign-in with a clear error', () async {
      final state = _state(auth: const UnconfiguredAuthService());
      addTearDown(state.dispose);

      final ok = await state.signInParent(
        email: _credentials.parentEmail,
        password: _credentials.parentPassword,
      );

      expect(ok, isFalse);
      expect(state.isSignedIn, isFalse);
      expect(state.authError, contains('not configured'));
    });

    test('refuse child sign-in with a clear error', () async {
      final state = _state(auth: const UnconfiguredAuthService());
      addTearDown(state.dispose);

      final ok = await state.signInChild(
        childId: 'ada',
        pin: _credentials.childPin,
      );

      expect(ok, isFalse);
      expect(state.isSignedIn, isFalse);
      expect(state.authError, contains('not configured'));
    });

    test('map unexpected backend errors to friendly copy', () async {
      final state = _state(auth: const _BrokenAuthService());
      addTearDown(state.dispose);

      final ok = await state.signInParent(
        email: _credentials.parentEmail,
        password: _credentials.parentPassword,
      );

      expect(ok, isFalse);
      expect(state.isSignedIn, isFalse);
      expect(state.authError, 'Sign-in failed. Please try again.');
    });
  });

  group('Session lifecycle', () {
    test('sign-out clears the role and any auth error', () async {
      final state = _state();
      addTearDown(state.dispose);

      await state.signInParent(
        email: _credentials.parentEmail,
        password: 'wrong',
      );
      expect(state.authError, isNotNull);

      await state.signInParent(
        email: _credentials.parentEmail,
        password: _credentials.parentPassword,
      );
      state.signOut();

      expect(state.isSignedIn, isFalse);
      expect(state.authError, isNull);
      expect(state.activeChild, isNull);
    });
  });
}
