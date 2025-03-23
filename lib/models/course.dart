class Course {
  final String id;
  final String title;
  final String semester;
  final String professorId;
  final List<String> lectures;
  final List<String> weekdays;
  final String lectureTime;
  final String? enrollmentId;

  Course({
    required this.id,
    required this.title,
    required this.semester,
    required this.professorId,
    required this.lectures,
    this.weekdays = const [],
    this.lectureTime = "",
    this.enrollmentId,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      semester: json['semester'] ?? '',
      professorId: json['professorId'] ?? '',
      lectures: List<String>.from(json['lectures'] ?? []),
      weekdays: List<String>.from(json['weekdays'] ?? []),
      lectureTime: json['lectureTime'] ?? '',
      enrollmentId: json['enrollmentId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'semester': semester,
      'professorId': professorId,
      'lectures': lectures,
      'weekdays': weekdays,
      'lectureTime': lectureTime,
      'enrollmentId': enrollmentId,
    };
  }
}
