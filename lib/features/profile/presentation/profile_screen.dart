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
              appBar: AppBar(title: const Text('Edit Profile')),
              body: state is ProfileLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state is ProfileLoaded
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        onChanged: () => setState(() => _isChanged = true),
                        child: Column(
                          children: [
                            LinearProgressIndicator(value: state.completeness),
                            const SizedBox(height: 8),
                            Text(
                              'Profile Completeness: ${(state.completeness * 100).toInt()}%',
                            ),
                            const SizedBox(height: 20),
                            GestureDetector(
                              onTap: _pickImage,
                              child: CircleAvatar(
                                radius: 50,
                                backgroundImage: _profileImage != null
                                    ? FileImage(_profileImage!)
                                    : null,
                                child: _profileImage == null
                                    ? const Icon(Icons.camera_alt, size: 50)
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _fullNameController,
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              title: Text(
                                _selectedDate == null
                                    ? 'Select DOB'
                                    : 'DOB: ${_selectedDate.toString().split(' ')[0]}',
                              ),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: _pickDate,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                final updatedUser = User(
                                  id: state.user.id,
                                  username: _usernameController.text,
                                  fullName: _fullNameController.text,
                                  password:
                                      state.user.password, // Keep password
                                  dob: _selectedDate.toString().split(' ')[0],
                                  profilePicture: _profileImage?.path,
                                );
                                context.read<ProfileBloc>().add(
                                  UpdateProfile(updatedUser),
                                );
                                setState(() => _isChanged = false);
                              },
                              child: const Text('Save Changes'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        state is ProfileError
                            ? state.message
                            : 'Error loading profile',
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  Future<bool> _showExitDialog() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Unsaved Changes'),
            content: const Text(
              'You have unsaved changes. Do you want to leave without saving?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
