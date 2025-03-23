import 'dart:convert';
import 'package:http/http.dart' as http;

class Backender {
  final String url =
      "https://0ksmm3j35f.execute-api.us-east-1.amazonaws.com/dev";

  // Регистрация пользователя с отправкой POST запроса на сервер
  Future<Map<String, dynamic>> register({
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

        // Парсим ответ, чтобы получить userId
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String userId = responseData['userId'] ?? '';

        return {
          'success': true,
          'userId': userId,
        };
      } else {
        // Ошибка регистрации
        print('Registration failed: ${response.statusCode} - ${response.body}');
        return {'success': false};
      }
    } catch (e) {
      // Обрабатываем ошибки сети или другие исключения
      print('Error during registration: $e');
      throw Exception('Failed to register: $e');
    }
  }

  // Проверка кода подтверждения, отправленного на email
  Future<bool> verifyCode({
    required String email,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$url/auth/verify'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'code': code,
        }),
      );

      // Проверяем статус ответа
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Успешная верификация
        print('Verification successful: ${response.body}');
        return true;
      } else {
        // Ошибка верификации
        print('Verification failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      // Обрабатываем ошибки сети или другие исключения
      print('Error during verification: $e');
      throw Exception('Failed to verify code: $e');
    }
  }

  // Авторизация пользователя
  Future<Map<String, dynamic>> login(
      {required String email, required String password}) async {
    try {
      final response = await http.post(
        Uri.parse('$url/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      // Проверяем статус ответа
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Успешная авторизация
        print('Login successful: ${response.body}');

        // Парсим ответ для получения userId, если он есть
        Map<String, dynamic> responseData = {};
        try {
          responseData = jsonDecode(response.body);
        } catch (e) {
          print('Error parsing response: $e');
        }

        final String userId = responseData['userId'] ?? '';

        return {
          'success': true,
          'userId': userId,
        };
      } else {
        // Ошибка авторизации
        print('Login failed: ${response.statusCode} - ${response.body}');
        return {'success': false};
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
