// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../bloc/auth_bloc.dart';
import '../../data/models/user_model.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  DateTime? _selectedDate;
  File? _profileImage;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
        _photoError = null;
      });
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  String? _photoError;
  String? _dobError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Unauthenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registration successful! Please login.'),
              ),
            );
            Navigator.of(context).pop();
          } else if (state is AuthError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _showImageSourceActionSheet(context),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: _photoError != null
                              ? Theme.of(
                                  context,
                                ).colorScheme.errorContainer.withOpacity(0.5)
                              : null,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : null,
                          child: _profileImage == null
                              ? Icon(
                                  Icons.camera_alt,
                                  size: 50,
                                  color: _photoError != null
                                      ? Theme.of(context).colorScheme.error
                                      : null,
                                )
                              : null,
                        ),
                        if (_photoError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _photoError!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (value) =>
                        value!.isEmpty ? 'Enter unique username' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: (value) =>
                        value!.isEmpty ? 'Enter full name' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (value) =>
                        (value?.length ?? 0) < 6 ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: _dobError != null
                                ? Theme.of(context).colorScheme.error
                                : Colors.grey.shade400,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        title: Text(
                          _selectedDate == null
                              ? 'Select Date of Birth'
                              : 'DOB: ${_selectedDate.toString().split(' ')[0]}',
                          style: TextStyle(
                            color: _dobError != null
                                ? Theme.of(context).colorScheme.error
                                : null,
                          ),
                        ),
                        trailing: Icon(
                          Icons.calendar_today,
                          color: _dobError != null
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
                        onTap: () {
                          setState(() => _dobError = null);
                          _pickDate();
                        },
                      ),
                      if (_dobError != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 12, top: 4.0),
                          child: Text(
                            _dobError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (state is AuthLoading)
                    const CircularProgressIndicator()
                  else
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _photoError = _profileImage == null
                              ? 'Profile photo is required'
                              : null;
                          _dobError = _selectedDate == null
                              ? 'Date of Birth is required'
                              : null;
                        });

                        if (_formKey.currentState!.validate() &&
                            _profileImage != null &&
                            _selectedDate != null) {
                          final user = User(
                            username: _usernameController.text,
                            fullName: _fullNameController.text,
                            password: _passwordController.text,
                            dob: _selectedDate.toString().split(' ')[0],
                            profilePicture: _profileImage?.path,
                          );
                          context.read<AuthBloc>().add(RegisterRequested(user));
                        }
                      },
                      child: const Text('Register'),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                _pickImage(ImageSource.gallery);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () {
                _pickImage(ImageSource.camera);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
