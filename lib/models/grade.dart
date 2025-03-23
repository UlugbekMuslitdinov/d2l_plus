import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class Grade {
  final String id;
  final String assignmentId;
  final String userId;
  final String title;
  final int grade;
  final DateTime dateTime;

  Grade({
    required this.id,
    required this.assignmentId,
    required this.userId,
    required this.title,
    required this.grade,
    required this.dateTime,
  });

  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      id: json['id'] ?? '',
      assignmentId: json['assignmentId'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      grade: json['grade'] ?? 0,
      dateTime: json['dateTime'] != null
          ? DateTime.parse(json['dateTime'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assignmentId': assignmentId,
      'userId': userId,
      'title': title,
      'grade': grade,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  // Форматированная дата
  String get formattedDate {
    return DateFormat('dd MMMM yyyy').format(dateTime);
  }

  // Определение оценки по буквенной шкале
  String get letterGrade {
    if (grade >= 90) return 'A';
    if (grade >= 80) return 'B';
    if (grade >= 70) return 'C';
    if (grade >= 60) return 'D';
    return 'F';
  }

  // Цвет оценки в зависимости от её значения
  // Можно использовать для отображения в UI
  static getGradeColor(int grade) {
    if (grade >= 90) return const Color(0xFF4CAF50); // Зеленый для A
    if (grade >= 80) return const Color(0xFF8BC34A); // Светло-зелёный для B
    if (grade >= 70) return const Color(0xFFFFC107); // Желтый для C
    if (grade >= 60) return const Color(0xFFFF9800); // Оранжевый для D
    return const Color(0xFFF44336); // Красный для F
  }
}
