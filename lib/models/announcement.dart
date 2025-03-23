import 'package:intl/intl.dart';

class Announcement {
  final String id;
  final String courseId;
  final String title;
  final String body;
  final DateTime dateTime;

  Announcement({
    required this.id,
    required this.courseId,
    required this.title,
    required this.body,
    required this.dateTime,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] ?? '',
      courseId: json['courseId'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      dateTime: json['dateTime'] != null
          ? DateTime.parse(json['dateTime'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'body': body,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  // Возвращает форматированную дату и время
  String get formattedDateTime {
    return DateFormat('dd MMMM yyyy, HH:mm').format(dateTime);
  }

  // Возвращает относительное время (например, "2 часа назад")
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return formattedDateTime;
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${_pluralize(difference.inDays, 'день', 'дня', 'дней')} назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${_pluralize(difference.inHours, 'час', 'часа', 'часов')} назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${_pluralize(difference.inMinutes, 'минуту', 'минуты', 'минут')} назад';
    } else {
      return 'Только что';
    }
  }

  // Вспомогательная функция для правильного склонения слов
  String _pluralize(int number, String one, String few, String many) {
    if (number % 10 == 1 && number % 100 != 11) {
      return one;
    } else if ([2, 3, 4].contains(number % 10) &&
        ![12, 13, 14].contains(number % 100)) {
      return few;
    } else {
      return many;
    }
  }
}
