import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'app_database.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // User table
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY,
        username TEXT UNIQUE,
        fullName TEXT,
        password TEXT,
        profilePicture TEXT,
        dob TEXT,
        isLoggedIn INTEGER DEFAULT 0
      )
    ''');

    // Todo table
    await db.execute('''
      CREATE TABLE todos(
        id INTEGER PRIMARY KEY,
        userId INTEGER,
        title TEXT,
        completed INTEGER,
        isFavorite INTEGER DEFAULT 0,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> clearCache() async {
    final db = await database;
    await db.delete('todos');
  }
}
