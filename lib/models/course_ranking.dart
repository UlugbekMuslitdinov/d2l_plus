class CourseRanking {
  final String courseId;
  final int numberOfVotes;
  final int rank;

  CourseRanking({
    required this.courseId,
    required this.numberOfVotes,
    required this.rank,
  });

  factory CourseRanking.fromJson(Map<String, dynamic> json) {
    return CourseRanking(
      courseId: json['courseId'] ?? '',
      numberOfVotes: json['numberOfVotes'] ?? 0,
      rank: json['rank'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'numberOfVotes': numberOfVotes,
      'rank': rank,
    };
  }
}
