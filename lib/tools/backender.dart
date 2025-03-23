import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:d2l_plus/models/course.dart';
import 'package:d2l_plus/models/assignment.dart';

class Backender {
  final String url =
      "https://0ksmm3j35f.execute-api.us-east-1.amazonaws.com/dev";
  final String apiKey = "M85t0SfMm97NrJohjhP0RAxFoz6kKNf1wzvdooO7";

  // Получение всех доступных курсов
  Future<List<Course>> getAllCourses() async {
    try {
      final response = await http.get(
        Uri.parse('$url/courses'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
      );

      // Проверяем статус ответа
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Успешный запрос
        print('Courses retrieved successfully: ${response.body}');

        // Парсим ответ в список курсов
        final List<dynamic> coursesJson = jsonDecode(response.body);
        List<Course> courses = coursesJson
            .map((courseJson) => Course.fromJson(courseJson))
            .toList();
        return courses;
      } else {
        // Ошибка при получении курсов
        print(
            'Failed to retrieve courses: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      // Обрабатываем ошибки сети или другие исключения
      print('Error retrieving all courses: $e');
      throw Exception('Failed to retrieve all courses: $e');
    }
  }

  // Регистрация пользователя на курс
  Future<bool> enrollCourse(
      {required String userId, required String courseId}) async {
    try {
      final response = await http.post(
        Uri.parse('$url/enrollments'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
        body: jsonEncode({
          'userId': userId,
          'courseId': courseId,
        }),
      );

      // Проверяем статус ответа
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Успешная регистрация на курс
        print('Course enrollment successful: ${response.body}');
        return true;
      } else {
        // Ошибка регистрации на курс
        print(
            'Course enrollment failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      // Обрабатываем ошибки сети или другие исключения
      print('Error during course enrollment: $e');
      throw Exception('Failed to enroll in course: $e');
    }
  }

  // Получение курсов пользователя
  Future<List<Course>> getUserCourses(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$url/enrollments/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
      );

      // Проверяем статус ответа
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Успешный запрос
        print('Courses retrieved successfully: ${response.body}');

        // Парсим ответ в список курсов
        final List<dynamic> coursesJson = jsonDecode(response.body);
        List<Course> courses = coursesJson
            .map((courseJson) => Course.fromJson(courseJson))
            .toList();
        return courses;
      } else {
        // Ошибка при получении курсов
        print(
            'Failed to retrieve courses: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      // Обрабатываем ошибки сети или другие исключения
      print('Error retrieving courses: $e');
      throw Exception('Failed to retrieve courses: $e');
    }
  }

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

  // Получение дедлайнов заданий пользователя
  Future<List<Assignment>> getUserDeadlines(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$url/assignments/deadlines/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
      );

      // Проверяем статус ответа
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Успешный запрос
        print('Deadlines retrieved successfully: ${response.body}');

        // Парсим ответ в список заданий
        final List<dynamic> deadlinesJson = jsonDecode(response.body);
        List<Assignment> deadlines = deadlinesJson
            .map((deadlineJson) => Assignment.fromJson(deadlineJson))
            .toList();

        // Сортируем задания по дедлайну (ближайшие сначала)
        deadlines.sort((a, b) => a.deadline.compareTo(b.deadline));

        return deadlines;
      } else {
        // Ошибка при получении дедлайнов
        print(
            'Failed to retrieve deadlines: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      // Обрабатываем ошибки сети или другие исключения
      print('Error retrieving deadlines: $e');
      throw Exception('Failed to retrieve deadlines: $e');
    }
  }

  // Отписка от курса (удаление регистрации)
  Future<bool> dropCourse(String enrollId) async {
    try {
      final response = await http.delete(
        Uri.parse('$url/enrollments/$enrollId'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
      );

      // Проверяем статус ответа
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Успешное удаление курса
        print('Course dropped successfully: ${response.body}');
        return true;
      } else {
        // Ошибка при удалении курса
        print(
            'Failed to drop course: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      // Обрабатываем ошибки сети или другие исключения
      print('Error dropping course: $e');
      throw Exception('Failed to drop course: $e');
    }
  }

  // Получение списка регистраций пользователя на курсы с ID регистрации
  Future<List<Map<String, dynamic>>> getUserEnrollments(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$url/enrollments/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
      );



      // Проверяем статус ответа
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Успешный запрос
        print('Enrollments retrieved successfully: ${response.body}');

        // Парсим ответ в список регистраций
        final List<dynamic> enrollmentsJson = jsonDecode(response.body);
        return enrollmentsJson.cast<Map<String, dynamic>>();
      } else {
        // Ошибка при получении регистраций
        print(
            'Failed to retrieve enrollments: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      // Обрабатываем ошибки сети или другие исключения
      print('Error retrieving enrollments: $e');
      throw Exception('Failed to retrieve enrollments: $e');
    }
  }
}
