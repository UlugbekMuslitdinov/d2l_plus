import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:d2l_plus/tools/backender.dart';
import 'package:d2l_plus/tools/storage.dart';

// Обработчик фоновых сообщений Firebase
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Инициализировать Firebase только если не инициализировано
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  print('Handling a background message: ${message.messageId}');
  print('Notification: ${message.notification?.title}');
  print('Data: ${message.data}');
}

class PushNotificationService {
  // Объявляем переменные без инициализации
  late FirebaseMessaging _messaging;
  final Backender _backender = Backender();
  final SecureStorage _storage = SecureStorage();

  // Инициализация сервиса уведомлений
  Future<void> initialize() async {
    try {
      // Проверяем, инициализирован ли Firebase уже
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      // Инициализируем FirebaseMessaging только после Firebase.initializeApp()
      _messaging = FirebaseMessaging.instance;

      // Устанавливаем обработчик для фоновых сообщений
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Запрашиваем разрешения для iOS и macOS
      if (Platform.isIOS || Platform.isMacOS) {
        NotificationSettings settings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
          criticalAlert: false,
          announcement: false,
        );

        print('Уведомления: ${settings.authorizationStatus}');

        // Активация обновления бейджа в фоне для iOS
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      // Получаем токен устройства
      String? token = await _messaging.getToken();
      if (token != null) {
        print('FCM токен: $token');
        _saveTokenToBackend(token);
      }

      // Слушаем обновления токена
      _messaging.onTokenRefresh.listen(_saveTokenToBackend);

      // Настройка обработчиков сообщений
      _setupMessageHandlers();
    } catch (e) {
      print('Ошибка инициализации сервиса уведомлений: $e');
    }
  }

  // Сохранение токена в бэкенде
  Future<void> _saveTokenToBackend(String token) async {
    try {
      String? userId = await _storage.getUserId();
      if (userId != null && userId.isNotEmpty) {
        // Регистрируем токен в бэкенде
        await _backender.registerDeviceToken(token);
        print('Токен устройства успешно зарегистрирован');
      } else {
        print('User ID не найден, токен будет зарегистрирован при входе');
      }
    } catch (e) {
      print('Ошибка при сохранении токена: $e');
    }
  }

  // Настройка обработчиков сообщений
  void _setupMessageHandlers() {
    // Обработка сообщений, когда приложение открыто и находится на переднем плане
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Получено сообщение в активном состоянии!');
      print('Заголовок уведомления: ${message.notification?.title}');
      print('Тело уведомления: ${message.notification?.body}');
      print('Данные: ${message.data}');

      // Здесь можно показать локальное уведомление, используя плагин flutter_local_notifications
      // или показать диалог/снэкбар в приложении
    });

    // Обработка события, когда уведомление открывается
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Уведомление открыто пользователем!');
      print('Данные: ${message.data}');

      // Здесь можно выполнить навигацию на определенный экран,
      // в зависимости от данных уведомления
      _handleNotificationNavigation(message.data);
    });

    // Проверяем, было ли приложение открыто через уведомление
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('Приложение открыто через уведомление!');
        print('Данные: ${message.data}');

        // Задержка для инициализации маршрутов
        Future.delayed(const Duration(seconds: 1), () {
          _handleNotificationNavigation(message.data);
        });
      }
    });
  }

  // Обработка навигации по уведомлению
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    // Пример навигации в зависимости от типа уведомления
    // Например, если есть courseId, можно открыть экран курса
    if (data.containsKey('courseId')) {
      String courseId = data['courseId'];
      print('Перенаправление на курс: $courseId');

      // Логика навигации должна быть реализована в контексте вашего приложения
      // Например, через GlobalKey<NavigatorState> или другой механизм
    }

    // Если это объявление
    if (data.containsKey('announcementId')) {
      String announcementId = data['announcementId'];
      print('Перенаправление на объявление: $announcementId');
    }

    // Если это задание
    if (data.containsKey('assignmentId')) {
      String assignmentId = data['assignmentId'];
      print('Перенаправление на задание: $assignmentId');
    }
  }

  // Подписка на тему (например, на определенный курс)
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    print('Подписка на тему: $topic');
  }

  // Отписка от темы
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    print('Отписка от темы: $topic');
  }

  // Отправка тестового уведомления (только для разработки)
  Future<void> sendTestNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _backender.sendNotification(
          title: title,
          body: body,
          token: token,
        );
        print('Тестовое уведомление отправлено');
      } else {
        print('Токен устройства не найден');
      }
    } catch (e) {
      print('Ошибка при отправке тестового уведомления: $e');
    }
  }
}
