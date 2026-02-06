// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../todo/domain/repositories/todo_repository.dart';
import '../../../todo/presentation/bloc/todo_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/theme_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Appearance'),
          _buildSettingsCard(
            context,
            children: [
              BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, themeMode) {
                  return ListTile(
                    leading: _buildIconContainer(
                      context,
                      themeMode == ThemeMode.dark
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                      Colors.blue,
                    ),
                    title: const Text('Dark Mode'),
                    subtitle: Text(
                      themeMode == ThemeMode.system
                          ? 'Following system'
                          : themeMode == ThemeMode.dark
                          ? 'Enabled'
                          : 'Disabled',
                    ),
                    trailing: Switch(
                      value: themeMode == ThemeMode.dark,
                      onChanged: (value) {
                        context.read<ThemeCubit>().toggleTheme();
                      },
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: _buildIconContainer(
                  context,
                  Icons.settings_brightness_outlined,
                  Colors.purple,
                ),
                title: const Text('Use System Theme'),
                onTap: () {
                  context.read<ThemeCubit>().setTheme(ThemeMode.system);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Data Management'),
          _buildSettingsCard(
            context,
            children: [
              ListTile(
                leading: _buildIconContainer(
                  context,
                  Icons.delete_sweep_outlined,
                  Colors.orange,
                ),
                title: const Text('Clear Local Cache'),
                subtitle: const Text('Wipe all offline tasks and favorites'),
                onTap: () async {
                  final confirm = await _showConfirmDialog(
                    context,
                    title: 'Clear Cache?',
                    message:
                        'This will remove all locally stored todos. You will need internet to fetch them again.',
                  );
                  if (confirm == true) {
                    await sl<TodoRepository>().clearCache();
                    context.read<TodoBloc>().add(ClearTodoCache());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cache cleared successfully!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Account'),
          _buildSettingsCard(
            context,
            children: [
              ListTile(
                leading: _buildIconContainer(context, Icons.logout, Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                subtitle: const Text('Exit your current session'),
                onTap: () async {
                  final confirm = await _showConfirmDialog(
                    context,
                    title: 'Logout?',
                    message: 'Are you sure you want to sign out?',
                  );
                  if (confirm == true) {
                    context.read<AuthBloc>().add(LogoutRequested());
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 48),
          const Center(
            child: Column(
              children: [
                Text(
                  'To-Do App',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Card(child: Column(children: children));
  }

  Widget _buildIconContainer(BuildContext context, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Future<bool?> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
