import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/repositories/todo_repository.dart';
import '../../data/models/todo_model.dart';
import 'package:rxdart/rxdart.dart';

// Events
abstract class TodoEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchTodos extends TodoEvent {
  final bool isRefresh;
  final Completer<void>? completer;
  FetchTodos({this.isRefresh = false, this.completer});
}

class SearchTodos extends TodoEvent {
  final String query;
  SearchTodos(this.query);
}

class ToggleFavorite extends TodoEvent {
  final int todoId;
  ToggleFavorite(this.todoId);
}

class ClearTodoCache extends TodoEvent {}

// States
abstract class TodoState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TodoInitial extends TodoState {}

class TodoLoading extends TodoState {}

class TodoLoaded extends TodoState {
  final List<Todo> todos;
  final bool hasReachedMax;
  final int page;
  final String query;

  TodoLoaded({
    required this.todos,
    required this.hasReachedMax,
    required this.page,
    this.query = '',
  });

  TodoLoaded copyWith({
    List<Todo>? todos,
    bool? hasReachedMax,
    int? page,
    String? query,
  }) {
    return TodoLoaded(
      todos: todos ?? this.todos,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      page: page ?? this.page,
      query: query ?? this.query,
    );
  }

  @override
  List<Object?> get props => [todos, hasReachedMax, page, query];
}

class TodoError extends TodoState {
  final String message;
  TodoError(this.message);
}

// BLoC
class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final TodoRepository todoRepository;

  TodoBloc({required this.todoRepository}) : super(TodoInitial()) {
    on<FetchTodos>(_onFetchTodos);
    on<SearchTodos>(
      _onSearchTodos,
      transformer: (events, mapper) => events
          .debounceTime(const Duration(milliseconds: 500))
          .switchMap(mapper),
    );
    on<ToggleFavorite>(_onToggleFavorite);
    on<ClearTodoCache>(_onClearTodoCache);
  }

  Future<void> _onFetchTodos(FetchTodos event, Emitter<TodoState> emit) async {
    final currentState = state;
    int page = 1;
    List<Todo> oldTodos = [];
    String query = '';

    if (currentState is TodoLoaded && !event.isRefresh) {
      if (currentState.hasReachedMax) return;
      page = currentState.page + 1;
      oldTodos = currentState.todos;
      query = currentState.query;
    }

    // Only emit TodoLoading on initial fetch or when the list is currently empty
    if (currentState is TodoInitial ||
        (event.isRefresh && currentState is! TodoLoaded)) {
      emit(TodoLoading());
    }

    try {
      final newTodos = await todoRepository.getTodos(page: page, query: query);
      if (newTodos.isEmpty) {
        if (currentState is TodoLoaded && !event.isRefresh) {
          emit(currentState.copyWith(hasReachedMax: true));
        } else {
          emit(
            TodoLoaded(
              todos: [],
              hasReachedMax: true,
              page: page,
              query: query,
            ),
          );
        }
      } else {
        emit(
          TodoLoaded(
            todos: event.isRefresh ? newTodos : oldTodos + newTodos,
            hasReachedMax: false,
            page: page,
            query: query,
          ),
        );
      }
    } catch (e) {
      emit(TodoError(e.toString()));
    } finally {
      event.completer?.complete();
    }
  }

  Future<void> _onSearchTodos(
    SearchTodos event,
    Emitter<TodoState> emit,
  ) async {
    emit(TodoLoading());
    try {
      final todos = await todoRepository.getTodos(page: 1, query: event.query);
      emit(
        TodoLoaded(
          todos: todos,
          hasReachedMax: todos.length < 20,
          page: 1,
          query: event.query,
        ),
      );
    } catch (e) {
      emit(TodoError(e.toString()));
    }
  }

  Future<void> _onToggleFavorite(
    ToggleFavorite event,
    Emitter<TodoState> emit,
  ) async {
    final currentState = state;
    if (currentState is TodoLoaded) {
      await todoRepository.toggleFavorite(event.todoId);
      final updatedTodos = currentState.todos.map((todo) {
        return todo.id == event.todoId
            ? todo.copyWith(isFavorite: !todo.isFavorite)
            : todo;
      }).toList();
      emit(currentState.copyWith(todos: updatedTodos));
    }
  }

  void _onClearTodoCache(ClearTodoCache event, Emitter<TodoState> emit) {
    emit(TodoLoaded(todos: [], hasReachedMax: true, page: 1, query: ''));
  }
}
