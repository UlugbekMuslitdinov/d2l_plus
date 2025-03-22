import 'dart:convert';
import 'package:http/http.dart' as http;

class Backender {
  final String url =
      "https://owk3h0rnlk.execute-api.us-east-1.amazonaws.com/dev";

  // Регистрация пользователя с отправкой POST запроса на сервер
  Future<bool> register({
    required String email,
    required String password,
    required String netId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$url/auth/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          // 'netid': netId,
        }),
      );

      // Проверяем статус ответа
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Успешная регистрация
        print('Registration successful: ${response.body}');
        return true;
      } else {
        // Ошибка регистрации
        print('Registration failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      // Обрабатываем ошибки сети или другие исключения
      print('Error during registration: $e');
      throw Exception('Failed to register: $e');
    }
  }

  // Авторизация пользователя
  Future<bool> login({required String id, required String password}) async {
    try {
      final response = await http.post(
        Uri.parse('$url/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'netid': id,
          'password': password,
        }),
      );

      // Проверяем статус ответа
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Успешная авторизация
        print('Login successful: ${response.body}');
        return true;
      } else {
        // Ошибка авторизации
        print('Login failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      // Обрабатываем ошибки сети или другие исключения
      print('Error during login: $e');
      throw Exception('Failed to login: $e');
    }
  }

  // Сброс пароля
  Future<bool> resetPassword({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse('$url/auth/reset-password/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      // Проверяем статус ответа
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Успешный запрос на сброс пароля
        print('Password reset request successful: ${response.body}');
        return true;
      } else {
        // Ошибка запроса на сброс пароля
        print(
            'Password reset request failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      // Обрабатываем ошибки сети или другие исключения
      print('Error during password reset request: $e');
      throw Exception('Failed to request password reset: $e');
    }
  }
}
