import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import '../../../../core/utils/db_helper.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SharedPreferences sharedPreferences;
  final DBHelper dbHelper;

  AuthRepositoryImpl({required this.sharedPreferences, required this.dbHelper});

  @override
  Future<bool> register(User user) async {
    final db = await dbHelper.database;
    try {
      await db.insert('users', user.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<User?> login(String username, String password) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<void> logout() async {
    await sharedPreferences.remove('logged_in_user_id');
    await sharedPreferences.setBool('is_logged_in', false);
  }

  @override
  Future<bool> isUserLoggedIn() async {
    return sharedPreferences.getBool('is_logged_in') ?? false;
  }

  @override
  Future<User?> getLoggedInUser() async {
    final userId = sharedPreferences.getInt('logged_in_user_id');
    if (userId == null) return null;

    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<void> setLoggedIn(bool isLoggedIn) async {
    await sharedPreferences.setBool('is_logged_in', isLoggedIn);
  }

  @override
  Future<void> saveUser(User user) async {
    // This could also set the logged in user ID
    if (user.id != null) {
      await sharedPreferences.setInt('logged_in_user_id', user.id!);
    }
  }

  @override
  Future<void> updateUser(User user) async {
    final db = await dbHelper.database;
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  @override
  Future<bool> checkUsernameExists(String username) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    return maps.isNotEmpty;
  }
}
