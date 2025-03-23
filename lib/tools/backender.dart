import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:d2l_plus/models/course.dart';
import 'package:d2l_plus/models/assignment.dart';
import 'package:d2l_plus/models/announcement.dart';
import 'package:d2l_plus/models/grade.dart';
import 'package:d2l_plus/models/course_ranking.dart';
import 'dart:io';

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

  // Получение объявлений для курса
  Future<List<Announcement>> getCourseAnnouncements(String courseId) async {
    try {
      final response = await http.get(
        Uri.parse('$url/announcements/course/$courseId'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
      );

      // Проверяем статус ответа
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Успешный запрос
        print('Announcements retrieved successfully: ${response.body}');

        // Парсим ответ в список объявлений
        final List<dynamic> announcementsJson = jsonDecode(response.body);
        List<Announcement> announcements = announcementsJson
            .map((announceJson) => Announcement.fromJson(announceJson))
            .toList();

        // Сортируем объявления по времени (новые сначала)
        announcements.sort((a, b) => b.dateTime.compareTo(a.dateTime));

        return announcements;
      } else {
        // Ошибка при получении объявлений
        print(
            'Failed to retrieve announcements: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      // Обрабатываем ошибки сети или другие исключения
      print('Error retrieving course announcements: $e');
      throw Exception('Failed to retrieve course announcements: $e');
    }
  }

  // Получение оценок пользователя по конкретному курсу
  Future<List<Grade>> getCourseGrades(String courseId, String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$url/grades/course?courseId=$courseId&userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
      );

      // Проверяем статус ответа
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Успешный запрос
        print('Grades retrieved successfully: ${response.body}');

        // Парсим ответ в список оценок
        final List<dynamic> gradesJson = jsonDecode(response.body);
        List<Grade> grades =
            gradesJson.map((gradeJson) => Grade.fromJson(gradeJson)).toList();

        // Сортируем оценки по дате (новые сначала)
        grades.sort((a, b) => b.dateTime.compareTo(a.dateTime));

        return grades;
      } else {
        // Ошибка при получении оценок
        print(
            'Failed to retrieve grades: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      // Обрабатываем ошибки сети или другие исключения
      print('Error retrieving course grades: $e');
      throw Exception('Failed to retrieve course grades: $e');
    }
  }

  // Загрузка рейтингов курсов
  Future<List<CourseRanking>> getCourseRankings() async {
    try {
      final response = await http.get(
        Uri.parse('$url/rankings/courses'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
      );

      // Проверяем статус ответа
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Успешный запрос
        print('Rankings retrieved successfully: ${response.body}');

        // Парсим ответ в список рейтингов
        final List<dynamic> rankingsJson = jsonDecode(response.body);
        List<CourseRanking> rankings = rankingsJson
            .map((rankingJson) => CourseRanking.fromJson(rankingJson))
            .toList();

        return rankings;
      } else {
        // Ошибка при получении рейтингов
        print(
            'Failed to retrieve rankings: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      // Обрабатываем ошибки сети или другие исключения
      print('Error retrieving rankings: $e');
      throw Exception('Failed to retrieve course rankings: $e');
    }
  }

  // Метод для регистрации токена устройства на сервере
  Future<bool> registerDeviceToken(String token) async {
    try {
      // Для упрощения примера отправляем только токен
      // В реальном приложении нужно добавить userId
      final response = await http.post(
        Uri.parse('$url/notifications/register'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
        body: jsonEncode({
          'token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Токен устройства успешно зарегистрирован');
        return true;
      } else {
        print(
            'Ошибка при регистрации токена: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('Исключение при регистрации токена: $e');
      return false;
    }
  }

  // Метод для отправки тестового уведомления (только для разработки)
  Future<bool> sendNotification({
    required String title,
    required String body,
    required String token,
    Map<String, dynamic>? data,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'title': title,
        'body': body,
        'token': token,
      };

      if (data != null) {
        payload['data'] = data;
      }

      final response = await http.post(
        Uri.parse('$url/notifications/send'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print('Тестовое уведомление отправлено');
        return true;
      } else {
        print(
            'Ошибка при отправке уведомления: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('Исключение при отправке уведомления: $e');
      return false;
    }
  }

  // Отправка сообщения к ИИ-ассистенту
  Future<Map<String, dynamic>> sendAssistantMessage({
    required String userId,
    required String prompt,
    List<Map<String, String>>? messages,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'userId': userId,
        'prompt': prompt,
      };

      // Если есть история сообщений, добавляем её
      if (messages != null && messages.isNotEmpty) {
        requestBody['messages'] = messages;
      }

      final response = await http.post(
        Uri.parse('$url/assistant/chat'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
        body: jsonEncode(requestBody),
      );

      // Проверяем статус ответа
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Успешный запрос
        print('Ответ ассистента получен: ${response.body}');
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData;
      } else {
        // Ошибка при получении ответа
        print(
            'Ошибка при запросе к ассистенту: ${response.statusCode} - ${response.body}');
        return {
          'message':
              'Произошла ошибка при получении ответа. Пожалуйста, попробуйте позже.'
        };
      }
    } catch (e) {
      // Обрабатываем ошибки сети или другие исключения
      print('Ошибка при обращении к ассистенту: $e');
      throw Exception('Не удалось получить ответ от ассистента: $e');
    }
  }
}
