import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/api_client.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _client;

  AuthRepository(this._client);

  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await _client.post(ApiConstants.login, data: {
        'email': email,
        'password': password,
      });

      final user = User.fromJson(response.data['user']);
      final token = response.data['token'];
      await _client.setToken(token);
      return AuthResult(user: user, token: token);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<AuthResult> register(String name, String email, String password) async {
    try {
      final response = await _client.post(ApiConstants.register, data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      });

      final user = User.fromJson(response.data['user']);
      final token = response.data['token'];
      await _client.setToken(token);
      return AuthResult(user: user, token: token);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _client.post(ApiConstants.logout);
    } finally {
      await _client.clearToken();
    }
  }

  Future<User> getCurrentUser() async {
    try {
      final response = await _client.get(ApiConstants.user);
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _client.getToken();
    return token != null;
  }

  String _handleError(DioException e) {
    if (e.response?.data != null && e.response?.data['message'] != null) {
      return e.response!.data['message'];
    }
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout. Please check your internet.';
    }
    if (e.type == DioExceptionType.receiveTimeout) {
      return 'Server took too long to respond.';
    }
    return 'Something went wrong. Please try again.';
  }
}

class AuthResult {
  final User user;
  final String token;

  AuthResult({required this.user, required this.token});
}
