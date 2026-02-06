import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/todo_model.dart';
import '../bloc/todo_bloc.dart';

class TodoListItem extends StatelessWidget {
  final Todo todo;
  const TodoListItem({super.key, required this.todo});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(todo.title),
      subtitle: Text(todo.completed ? 'Completed' : 'Pending'),
      leading: CircleAvatar(child: Text(todo.id.toString())),
      trailing: IconButton(
        icon: Icon(
          todo.isFavorite ? Icons.favorite : Icons.favorite_border,
          color: todo.isFavorite ? Colors.red : null,
        ),
        onPressed: () {
          context.read<TodoBloc>().add(ToggleFavorite(todo.id));
        },
      ),
    );
  }
}
