import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';
import 'dart:async';

// Events
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String username;
  final String password;
  final bool rememberMe;
  LoginRequested(this.username, this.password, this.rememberMe);
}

class RegisterRequested extends AuthEvent {
  final User user;
  RegisterRequested(this.user);
}

class LogoutRequested extends AuthEvent {}

class UserUpdated extends AuthEvent {
  final User user;
  UserUpdated(this.user);

  @override
  List<Object?> get props => [user];
}

// States
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;
  Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class AuthLockout extends AuthState {
  final DateTime until;
  AuthLockout(this.until);
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<UserUpdated>(_onUserUpdated);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    final isLoggedIn = await authRepository.isUserLoggedIn();
    if (isLoggedIn) {
      final user = await authRepository.getLoggedInUser();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (_lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!)) {
      emit(AuthLockout(_lockoutUntil!));
      return;
    }

    emit(AuthLoading());
    final user = await authRepository.login(event.username, event.password);
    if (user != null) {
      _failedAttempts = 0;
      if (event.rememberMe) {
        await authRepository.setLoggedIn(true);
        await authRepository.saveUser(user);
      }
      emit(Authenticated(user));
    } else {
      _failedAttempts++;
      if (_failedAttempts >= 3) {
        _lockoutUntil = DateTime.now().add(const Duration(minutes: 1));
        emit(AuthLockout(_lockoutUntil!));
      } else {
        emit(AuthError('Invalid credentials. Attempt $_failedAttempts of 3'));
      }
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final exists = await authRepository.checkUsernameExists(
      event.user.username,
    );
    if (exists) {
      emit(AuthError('Username already exists'));
      return;
    }

    final success = await authRepository.register(event.user);
    if (success) {
      emit(Unauthenticated()); // Redirect to login after registration
    } else {
      emit(AuthError('Registration failed'));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await authRepository.logout();
    emit(Unauthenticated());
  }

  void _onUserUpdated(UserUpdated event, Emitter<AuthState> emit) {
    emit(Authenticated(event.user));
  }
}
