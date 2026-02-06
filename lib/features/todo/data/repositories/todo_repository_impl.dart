import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../core/utils/db_helper.dart';
import '../../domain/repositories/todo_repository.dart';
import '../models/todo_model.dart';

class TodoRepositoryImpl implements TodoRepository {
  final http.Client client;
  final DBHelper dbHelper;
  final Connectivity connectivity;

  TodoRepositoryImpl({
    required this.client,
    required this.dbHelper,
    required this.connectivity,
  });

  @override
  Future<List<Todo>> getTodos({
    int page = 1,
    int limit = 20,
    String? query,
  }) async {
    final db = await dbHelper.database;
    final connectivityResult = await connectivity.checkConnectivity();

    if (!connectivityResult.contains(ConnectivityResult.none)) {
      try {
        final response = await client.get(
          Uri.parse(
            'https://jsonplaceholder.typicode.com/todos?_page=$page&_limit=$limit',
          ),
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(
            response.statusCode == 200 ? response.body : '[]',
          );
          final List<Todo> remoteTodos = data
              .map((item) => Todo.fromJson(item))
              .toList();

          // Cache remote todos
          for (var todo in remoteTodos) {
            // Check if already in DB to preserve isFavorite
            final List<Map<String, dynamic>> existing = await db.query(
              'todos',
              where: 'id = ?',
              whereArgs: [todo.id],
            );

            if (existing.isNotEmpty) {
              final currentTodo = Todo.fromMap(existing.first);
              final updatedTodo = todo.copyWith(
                isFavorite: currentTodo.isFavorite,
              );
              await db.update(
                'todos',
                updatedTodo.toMap(),
                where: 'id = ?',
                whereArgs: [todo.id],
              );
            } else {
              await db.insert('todos', todo.toMap());
            }
          }
        }
      } catch (e) {
        // Fallback to local if API fails
      }
    }

    // Always fetch from local to ensure search and pagination work consistently
    String whereClause = '';
    List<dynamic> whereArgs = [];
    if (query != null && query.isNotEmpty) {
      whereClause = 'title LIKE ?';
      whereArgs = ['%$query%'];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'todos',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      limit: limit,
      offset: (page - 1) * limit,
    );

    return maps.map((map) => Todo.fromMap(map)).toList();
  }

  @override
  Future<void> toggleFavorite(int todoId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'todos',
      where: 'id = ?',
      whereArgs: [todoId],
    );

    if (maps.isNotEmpty) {
      final todo = Todo.fromMap(maps.first);
      final updatedTodo = todo.copyWith(isFavorite: !todo.isFavorite);
      await db.update(
        'todos',
        updatedTodo.toMap(),
        where: 'id = ?',
        whereArgs: [todoId],
      );
    }
  }

  @override
  Future<void> clearCache() async {
    await dbHelper.clearCache();
  }
}
