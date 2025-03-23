class Course {
  final String id;
  final String title;
  final String semester;
  final String professorId;
  final List<String> lectures;

  Course({
    required this.id,
    required this.title,
    required this.semester,
    required this.professorId,
    required this.lectures,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      semester: json['semester'] ?? '',
      professorId: json['professorId'] ?? '',
      lectures: List<String>.from(json['lectures'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'semester': semester,
      'professorId': professorId,
      'lectures': lectures,
    };
  }
}
