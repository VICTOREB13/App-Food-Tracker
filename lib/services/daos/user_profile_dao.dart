import 'package:sqflite/sqflite.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/result.dart';
import '../../core/interfaces/daos_interfaces.dart';
import '../../models/user_profile.dart';

/// Data Access Object for user biometrics, target macros, and profile configuration.
class UserProfileDao implements IUserProfileDao {
  final Future<Database> Function() _getDatabase;

  UserProfileDao(this._getDatabase);

  @override
  Future<int> saveUserProfile(UserProfile profile) async {
    final db = await _getDatabase();
    return await db.insert(
      'user_profile',
      profile.toSqliteMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<UserProfile?> getUserProfile() async {
    final db = await _getDatabase();
    try {
      final results = await db.query(
        'user_profile',
        limit: 1,
      );
      if (results.isEmpty) return null;
      return UserProfile.fromSqliteMap(results.first);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int> deleteUserProfile({String id = 'primary'}) async {
    final db = await _getDatabase();
    return await db.delete(
      'user_profile',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================
  // FUNCTIONAL RESULT APIS
  // ==========================================

  @override
  Future<Result<int, DatabaseFailure>> saveUserProfileResult(UserProfile profile) async {
    try {
      final id = await saveUserProfile(profile);
      return Result.ok(id);
    } catch (e, stack) {
      return Result.err(
        DatabaseFailure(
          message: 'Error al persistir perfil de usuario: $e',
          cause: e,
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<UserProfile?, DatabaseFailure>> getUserProfileResult() async {
    try {
      final profile = await getUserProfile();
      return Result.ok(profile);
    } catch (e, stack) {
      return Result.err(
        DatabaseFailure(
          message: 'Error al consultar perfil de usuario: $e',
          cause: e,
          stackTrace: stack,
        ),
      );
    }
  }
}
