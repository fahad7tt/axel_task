import 'package:equatable/equatable.dart';

class Todo extends Equatable {
  final int id;
  final int userId;
  final String title;
  final bool completed;
  final bool isFavorite;

  const Todo({
    required this.id,
    required this.userId,
    required this.title,
    required this.completed,
    this.isFavorite = false,
  });

  Todo copyWith({
    int? id,
    int? userId,
    String? title,
    bool? completed,
    bool? isFavorite,
  }) {
    return Todo(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'completed': completed ? 1 : 0,
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      completed: map['completed'] == 1,
      isFavorite: map['isFavorite'] == 1,
    );
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      completed: json['completed'],
      isFavorite: false,
    );
  }

  @override
  List<Object?> get props => [id, userId, title, completed, isFavorite];
}
