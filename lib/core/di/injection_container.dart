import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/todo/domain/repositories/todo_repository.dart';
import '../../features/todo/data/repositories/todo_repository_impl.dart';
import '../../features/todo/presentation/bloc/todo_bloc.dart';
import '../../features/profile/presentation/profile_bloc.dart';
import '../utils/db_helper.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features
  // Auth
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sharedPreferences: sl(), dbHelper: sl()),
  );
  sl.registerFactory(() => AuthBloc(authRepository: sl()));

  // Todo
  sl.registerLazySingleton<TodoRepository>(
    () => TodoRepositoryImpl(client: sl(), dbHelper: sl(), connectivity: sl()),
  );
  sl.registerFactory(() => TodoBloc(todoRepository: sl()));

  // Profile
  sl.registerFactory(() => ProfileBloc(authRepository: sl()));

  //! Core
  sl.registerLazySingleton(() => DBHelper());

  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => Connectivity());
}
