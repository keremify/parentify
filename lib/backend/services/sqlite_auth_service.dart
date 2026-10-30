import '../../l10n/app_strings.dart';
import '../../models/user_role.dart';
import '../../services/auth_service.dart';
import '../daos/user_dao.dart';
import '../database/seed_data.dart';

/// SQLite-backed authentication service.
///
/// Authenticates directly against the local SQLite `users` and `children` tables.
class SqliteAuthService implements AuthService {
  const SqliteAuthService(this.userDao);

  final UserDao userDao;

  @override
  Future<AuthSession> signInParent({
    required String email,
    required String password,
    AppStrings strings = AppStrings.english,
  }) async {
    final user = await userDao.verifyParentCredentials(
      email: email,
      password: password,
    );

    if (user == null) {
      throw AuthException(strings.signInWrongDemoParent);
    }

    return AuthSession(role: UserRole.parent, identity: user.email);
  }

  @override
  Future<AuthSession> signInChild({
    required String childId,
    required String pin,
    AppStrings strings = AppStrings.english,
  }) async {
    final valid = await userDao.verifyChildPin(childId: childId, pin: pin);

    if (!valid) {
      throw AuthException(strings.signInWrongChildPin);
    }

    return AuthSession(
      role: UserRole.child,
      identity: childId,
      childId: childId,
    );
  }

  /// One-tap sign in helper for the seeded SQLite parent test account.
  Future<AuthSession> signInTestParent() => signInParent(
    email: DbSeedData.testParentEmail,
    password: DbSeedData.testParentPassword,
  );

  /// One-tap sign in helper for the seeded SQLite child test account.
  Future<AuthSession> signInTestChild({
    String childId = DbSeedData.testChildId,
  }) => signInChild(childId: childId, pin: DbSeedData.testChildPin);
}
