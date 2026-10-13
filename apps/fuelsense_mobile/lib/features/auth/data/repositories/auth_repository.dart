import '../services/auth_service.dart';

class AuthRepository {
  final AuthService _service = AuthService.instance;

  Future<Map<String, dynamic>> login(String email, String password) {
    return _service.login(email: email, password: password);
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) {
    return _service.register(
      name: name,
      email: email,
      password: password,
      phone: phone,
    );
  }

  Future<String?> getToken() {
    return _service.getToken();
  }

  Future<bool> isLoggedIn() {
    return _service.isLoggedIn();
  }

  Future<void> logout() {
    return _service.logout();
  }
}
