import '../../data/models/todo_model.dart';

abstract class TodoRepository {
  Future<List<Todo>> getTodos({int page = 1, int limit = 20, String? query});
  Future<void> toggleFavorite(int todoId);
  Future<void> clearCache();
}
