class Assignment {
  final String id;
  final String title;
  final String body;
  final DateTime deadline;
  final DateTime dateTime;
  final String courseId;
  final int weight;

  Assignment({
    required this.id,
    required this.title,
    required this.body,
    required this.deadline,
    required this.dateTime,
    required this.courseId,
    required this.weight,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'])
          : DateTime.now(),
      dateTime: json['dateTime'] != null
          ? DateTime.parse(json['dateTime'])
          : DateTime.now(),
      courseId: json['courseId'] ?? '',
      weight: json['weight'] ?? 0,
    );
  }

  // Рассчитывает, сколько дней осталось до дедлайна
  int get daysLeft {
    final now = DateTime.now();
    return deadline.difference(now).inDays;
  }

  // Возвращает true, если дедлайн просрочен
  bool get isOverdue {
    final now = DateTime.now();
    return now.isAfter(deadline);
  }

  // Возвращает true, если дедлайн наступает в течение 3 дней
  bool get isUrgent {
    final now = DateTime.now();
    final diff = deadline.difference(now).inDays;
    return diff >= 0 && diff <= 3 && !isOverdue;
  }
}
