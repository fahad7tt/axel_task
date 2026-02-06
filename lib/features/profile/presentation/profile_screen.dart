import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'profile_bloc.dart';
import '../../auth/data/models/user_model.dart';
import '../../../../core/di/injection_container.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _fullNameController;
  DateTime? _selectedDate;
  File? _profileImage;
  bool _isChanged = false;
  User? _initialUser;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _fullNameController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
        _isChanged = true;
      });
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
        _isChanged = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ProfileBloc>()..add(LoadProfile()),
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoaded) {
            if (_initialUser == null) {
              _initialUser = state.user;
              _usernameController.text = state.user.username;
              _fullNameController.text = state.user.fullName;
              _selectedDate = DateTime.parse(state.user.dob);
              if (state.user.profilePicture != null) {
                _profileImage = File(state.user.profilePicture!);
              }
            } else if (!_isChanged) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.white),
                      SizedBox(width: 12),
                      Expanded(child: Text('Profile updated successfully!')),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
              Navigator.of(context).pop();
            }
          }
        },
        builder: (context, state) {
          return PopScope(
            canPop: !_isChanged,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              final shouldPop = await _showExitDialog();
              if (shouldPop && context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Edit Profile'),
                actions: [
                  if (_isChanged && state is ProfileLoaded)
                    TextButton(
                      onPressed: () => _saveProfile(state),
                      child: const Text(
                        'Save',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              body: state is ProfileLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state is ProfileLoaded
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Form(
                        key: _formKey,
                        onChanged: () {
                          if (!_isChanged) setState(() => _isChanged = true);
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCompletenessIndicator(state.completeness),
                            const SizedBox(height: 32),
                            Center(
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Stack(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.2),
                                          width: 2,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 60,
                                        backgroundColor: Colors.grey.shade100,
                                        backgroundImage: _profileImage != null
                                            ? FileImage(_profileImage!)
                                            : null,
                                        child: _profileImage == null
                                            ? const Icon(
                                                Icons.person,
                                                size: 60,
                                                color: Colors.grey,
                                              )
                                            : null,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            Card(
                              margin: EdgeInsets.zero,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Full Name'),
                                    TextFormField(
                                      controller: _fullNameController,
                                      decoration: const InputDecoration(
                                        hintText: 'Your display name',
                                        prefixIcon: Icon(Icons.badge_outlined),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    _buildLabel('Username'),
                                    TextFormField(
                                      controller: _usernameController,
                                      decoration: const InputDecoration(
                                        hintText:
                                            'Username (must start with _)',
                                        prefixIcon: Icon(Icons.alternate_email),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter username';
                                        }
                                        if (!value.startsWith('_')) {
                                          return 'Must start with underscore (_)';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    _buildLabel('Date of Birth'),
                                    InkWell(
                                      onTap: _pickDate,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).inputDecorationTheme.fillColor,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_today_outlined,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              _selectedDate == null
                                                  ? 'Select Date'
                                                  : 'DOB: ${_selectedDate.toString().split(' ')[0]}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton(
                              onPressed: () => _saveProfile(state),
                              child: const Text('Update Profile'),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state is ProfileError
                                ? state.message
                                : 'Error loading profile',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompletenessIndicator(double completeness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Profile Status',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${(completeness * 100).toInt()}%',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: completeness,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.black87
              : Colors.white70,
        ),
      ),
    );
  }

  void _saveProfile(ProfileLoaded state) {
    final updatedUser = User(
      id: state.user.id,
      username: _usernameController.text,
      fullName: _fullNameController.text,
      password: state.user.password, // Keep password
      dob: _selectedDate.toString().split(' ')[0],
      profilePicture: _profileImage?.path,
    );
    context.read<ProfileBloc>().add(UpdateProfile(updatedUser));
    setState(() => _isChanged = false);
  }

  Future<bool> _showExitDialog() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard Changes?'),
            content: const Text(
              'You have unsaved modifications. Are you sure you want to leave?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Discard'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
