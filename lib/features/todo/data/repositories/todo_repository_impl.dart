import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    bool isOnline = !connectivityResult.contains(ConnectivityResult.none);

    if (isOnline) {
      try {
        final String url = (query != null && query.isNotEmpty)
            ? 'https://jsonplaceholder.typicode.com/todos?q=$query&_page=$page&_limit=$limit'
            : 'https://jsonplaceholder.typicode.com/todos?_page=$page&_limit=$limit';

        debugPrint('Fetching todos from: $url');
        final response = await client
            .get(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'User-Agent': 'FlutterApp/1.0',
              },
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          final List<Todo> remoteTodos = data
              .map((item) => Todo.fromJson(item))
              .toList();

          debugPrint('Successfully fetched ${remoteTodos.length} todos');

          // Cache remote todos using a transaction for performance and atomicity
          await db.transaction((txn) async {
            for (var todo in remoteTodos) {
              final List<Map<String, dynamic>> existing = await txn.query(
                'todos',
                where: 'id = ?',
                whereArgs: [todo.id],
              );

              if (existing.isNotEmpty) {
                final currentTodo = Todo.fromMap(existing.first);
                // Preserve local favorite status
                final updatedTodo = todo.copyWith(
                  isFavorite: currentTodo.isFavorite,
                );
                await txn.update(
                  'todos',
                  updatedTodo.toMap(),
                  where: 'id = ?',
                  whereArgs: [todo.id],
                );
              } else {
                await txn.insert('todos', todo.toMap());
              }
            }
          });

          if (query != null && query.isNotEmpty) {
            final List<Todo> combined = [];
            for (var rt in remoteTodos) {
              final List<Map<String, dynamic>> local = await db.query(
                'todos',
                where: 'id = ?',
                whereArgs: [rt.id],
              );
              if (local.isNotEmpty) {
                combined.add(Todo.fromMap(local.first));
              } else {
                combined.add(rt);
              }
            }
            return combined;
          }
        } else {
          debugPrint('API Error: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Exception during API fetch: $e');
      }
    }

    // Load from local database (offline fallback or default view)
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
      orderBy: 'id ASC',
    );

    final List<Todo> localTodos = maps.map((map) => Todo.fromMap(map)).toList();

    // If online search was done, remoteTodos were already returned.
    // This part is for the initial load or scrolling load where isOnline branch
    // handled the caching but might have fallen through if not a search.
    return localTodos;
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
