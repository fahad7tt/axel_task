import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/todo_model.dart';
import '../bloc/todo_bloc.dart';

class TodoListItem extends StatelessWidget {
  final Todo todo;
  const TodoListItem({super.key, required this.todo});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6,
                color: todo.completed
                    ? Colors.green.shade400
                    : Theme.of(context).colorScheme.primary,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todo.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: todo.completed
                              ? TextDecoration.lineThrough
                              : null,
                          color: todo.completed
                              ? Colors.grey
                              : Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            todo.completed
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 16,
                            color: todo.completed
                                ? Colors.green
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            todo.completed ? 'Completed' : 'Pending',
                            style: TextStyle(
                              fontSize: 12,
                              color: todo.completed
                                  ? Colors.green
                                  : Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                icon: Icon(
                  todo.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: todo.isFavorite ? Colors.red : Colors.grey.shade400,
                ),
                onPressed: () {
                  context.read<TodoBloc>().add(ToggleFavorite(todo.id));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
