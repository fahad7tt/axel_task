import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int? id;
  final String username;
  final String fullName;
  final String password;
  final String? profilePicture;
  final String dob;

  const User({
    this.id,
    required this.username,
    required this.fullName,
    required this.password,
    this.profilePicture,
    required this.dob,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'password': password,
      'profilePicture': profilePicture,
      'dob': dob,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      fullName: map['fullName'],
      password: map['password'],
      profilePicture: map['profilePicture'],
      dob: map['dob'],
    );
  }

  @override
  List<Object?> get props => [id, username, fullName, profilePicture, dob];
}
