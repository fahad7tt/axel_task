import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../auth/domain/repositories/auth_repository.dart';
import '../../auth/data/models/user_model.dart';

// Events
abstract class ProfileEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {}

class UpdateProfile extends ProfileEvent {
  final User user;
  UpdateProfile(this.user);
}

// States
abstract class ProfileState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final User user;
  final double completeness;
  ProfileLoaded(this.user, this.completeness);

  @override
  List<Object?> get props => [user, completeness];
}

class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}

// BLoC
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final AuthRepository authRepository;
  final AuthBloc authBloc;

  ProfileBloc({required this.authRepository, required this.authBloc})
    : super(ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<UpdateProfile>(_onUpdateProfile);
  }

  Future<void> _onLoadProfile(
    LoadProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      final user = await authRepository.getLoggedInUser();
      if (user != null) {
        emit(ProfileLoaded(user, _calculateCompleteness(user)));
      } else {
        emit(ProfileError('User not found'));
      }
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      // For simplicity, we reuse register to update if ID is same (upsert logic in real app)
      // But here we'll just update the user in DB directly or add a new method to repository
      // Let's assume register handles upsert or we update AuthRepository
      // I'll update AuthRepositoryImpl to support update
      await authRepository.updateUser(event.user);
      authBloc.add(UserUpdated(event.user));
      emit(ProfileLoaded(event.user, _calculateCompleteness(event.user)));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  double _calculateCompleteness(User user) {
    int totalFields = 4; // username, fullName, profilePicture, dob
    int filledFields = 0;
    if (user.username.isNotEmpty) filledFields++;
    if (user.fullName.isNotEmpty) filledFields++;
    if (user.profilePicture != null && user.profilePicture!.isNotEmpty) {
      filledFields++;
    }
    if (user.dob.isNotEmpty) filledFields++;
    return filledFields / totalFields;
  }
}
