import '../../data/models/user_model.dart';

abstract class AuthRepository {
  Future<bool> register(User user);
  Future<User?> login(String username, String password);
  Future<void> logout();
  Future<bool> isUserLoggedIn();
  Future<User?> getLoggedInUser();
  Future<void> setLoggedIn(bool isLoggedIn);
  Future<void> saveUser(User user);
  Future<bool> checkUsernameExists(String username);
}
