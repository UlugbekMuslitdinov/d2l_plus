import 'package:d2l_plus/constants/colors.dart';
import 'package:d2l_plus/models/course.dart';
import 'package:d2l_plus/models/course_ranking.dart';
import 'package:d2l_plus/tools/backender.dart';
import 'package:d2l_plus/tools/storage.dart';
import 'package:flutter/material.dart';

class AvailableCoursesScreen extends StatefulWidget {
  final VoidCallback onCourseEnrolled;

  const AvailableCoursesScreen({
    Key? key,
    required this.onCourseEnrolled,
  }) : super(key: key);

  @override
  State<AvailableCoursesScreen> createState() => _AvailableCoursesScreenState();
}

class _AvailableCoursesScreenState extends State<AvailableCoursesScreen> {
  final _backender = Backender();
  final _storage = SecureStorage();
  List<Course> _availableCourses = [];
  List<Course> _userCourses = [];
  Map<String, CourseRanking> _courseRankings = {};
  bool _isLoading = true;
  String _error = '';
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      // Получаем ID пользователя
      final userId = await _storage.getUserId();
      if (userId == null || userId.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'User ID not found. Please log in again.';
        });
        return;
      }
      _userId = userId;

      // Получаем список всех курсов
      final allCourses = await _backender.getAllCourses();

      // Получаем список курсов пользователя
      final userCourses = await _backender.getUserCourses(userId);

      // Получаем рейтинги курсов
      final rankings = await _backender.getCourseRankings();

      // Создаем Map для быстрого доступа к рейтингам по ID курса
      final rankingsMap = {
        for (var ranking in rankings) ranking.courseId: ranking
      };

      // Фильтруем курсы, на которые пользователь еще не записан
      final availableCourses = allCourses.where((course) {
        return !userCourses.any((userCourse) => userCourse.id == course.id);
      }).toList();

      setState(() {
        _availableCourses = availableCourses;
        _userCourses = userCourses;
        _courseRankings = rankingsMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Unable to load courses: ${e.toString()}';
      });
    }
  }

  Future<void> _enrollCourse(Course course) async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User ID not found. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final success = await _backender.enrollCourse(
        userId: _userId!,
        courseId: course.id,
      );

      if (success) {
        // Обновляем список доступных курсов
        await _loadData();

        // Вызываем callback для обновления списка курсов на главном экране
        widget.onCourseEnrolled();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'You have successfully enrolled in the course "${course.title}"'),
              backgroundColor: UAColors.azurite,
            ),
          );
        }
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to enroll in the course. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available courses'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  )
                : _availableCourses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.school_outlined,
                              color: Colors.grey,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No available courses',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'You are already enrolled in all available courses',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _availableCourses.length,
                        itemBuilder: (context, index) {
                          return _buildCourseCard(_availableCourses[index]);
                        },
                      ),
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    // Получаем рейтинг курса, если есть
    final ranking = _courseRankings[course.id];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок курса
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: UAColors.blue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        course.semester,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (ranking != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: _getRatingColor(ranking.rank),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${ranking.rank}/5',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Содержимое курса
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Список лекций
                const Text(
                  'Lectures:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: UAColors.blue,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ...course.lectures
                    .map((lecture) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: UAColors.red,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  lecture,
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),

                const SizedBox(height: 16),

                // Информация о рейтинге
                if (ranking != null) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'Course rating: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: UAColors.blue,
                        ),
                      ),
                      _buildRatingStars(ranking.rank),
                      const Spacer(),
                      Text(
                        '${ranking.numberOfVotes} ${_getVotesText(ranking.numberOfVotes)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Кнопка "Записаться"
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _enrollCourse(course),
                    icon: const Icon(Icons.add_circle),
                    label: const Text('Enroll in the course'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: UAColors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Создает виджет с отображением звезд рейтинга
  Widget _buildRatingStars(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: _getRatingColor(rating),
          size: 18,
        );
      }),
    );
  }

  // Возвращает цвет в зависимости от рейтинга
  Color _getRatingColor(int rating) {
    if (rating >= 4) return Colors.green;
    if (rating >= 3) return Colors.orange;
    return Colors.red;
  }

  // Возвращает правильное склонение слова "голос"
  String _getVotesText(int votes) {
    if (votes % 10 == 1 && votes % 100 != 11) {
      return 'vote';
    } else if ((votes % 10 >= 2 && votes % 10 <= 4) &&
        (votes % 100 < 10 || votes % 100 >= 20)) {
      return 'votes';
    } else {
      return 'votes';
    }
  }
}
