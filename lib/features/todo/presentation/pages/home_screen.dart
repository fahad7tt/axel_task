import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../bloc/todo_bloc.dart';
import '../widgets/todo_list_item.dart';
import '../../../../core/di/injection_container.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) context.read<TodoBloc>().add(FetchTodos());
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<TodoBloc>()..add(FetchTodos()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('To-Do List'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => Navigator.of(context).pushNamed('/settings'),
            ),
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => Navigator.of(context).pushNamed('/profile'),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Builder(
                builder: (context) => TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search todos...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (value) {
                    context.read<TodoBloc>().add(SearchTodos(value));
                  },
                ),
              ),
            ),
          ),
        ),
        body: BlocBuilder<TodoBloc, TodoState>(
          builder: (context, state) {
            if (state is TodoInitial ||
                (state is TodoLoading && (state as dynamic).todos == null)) {
              return _buildShimmer();
            } else if (state is TodoError) {
              return Center(child: Text(state.message));
            } else if (state is TodoLoaded) {
              if (state.todos.isEmpty) {
                return const Center(child: Text('No todos found.'));
              }
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<TodoBloc>().add(FetchTodos(isRefresh: true));
                },
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: state.hasReachedMax
                      ? state.todos.length
                      : state.todos.length + 1,
                  itemBuilder: (context, index) {
                    if (index >= state.todos.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return TodoListItem(todo: state.todos[index]);
                  },
                ),
              );
            }
            return _buildShimmer();
          },
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListTile(
          leading: const CircleAvatar(backgroundColor: Colors.white),
          title: Container(height: 10, color: Colors.white),
          subtitle: Container(height: 8, color: Colors.white, width: 100),
        ),
      ),
    );
  }
}
