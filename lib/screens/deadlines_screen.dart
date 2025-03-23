import 'package:d2l_plus/constants/colors.dart';
import 'package:d2l_plus/models/assignment.dart';
import 'package:d2l_plus/models/course.dart';
import 'package:d2l_plus/tools/backender.dart';
import 'package:d2l_plus/tools/storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DeadlinesScreen extends StatefulWidget {
  const DeadlinesScreen({Key? key}) : super(key: key);

  @override
  State<DeadlinesScreen> createState() => _DeadlinesScreenState();
}

class _DeadlinesScreenState extends State<DeadlinesScreen> {
  final _backender = Backender();
  final _storage = SecureStorage();
  List<Assignment> _deadlines = [];
  Map<String, Course> _coursesMap = {};
  bool _isLoading = true;
  String _error = '';

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

      // Получаем список дедлайнов
      final deadlines = await _backender.getUserDeadlines(userId);

      // Получаем список курсов пользователя
      final courses = await _backender.getUserCourses(userId);

      // Создаем Map для быстрого доступа к курсам по ID
      final coursesMap = {for (var course in courses) course.id: course};

      setState(() {
        _deadlines = deadlines;
        _coursesMap = coursesMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load deadlines: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upcoming Deadlines',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: UAColors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Keep track of your assignment due dates',
              style: TextStyle(
                fontSize: 16,
                color: UAColors.azurite,
              ),
            ),
            const SizedBox(height: 24),

            // Отображение дедлайнов или индикатора загрузки
            _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
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
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      )
                    : _deadlines.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.task_alt,
                                  color: Colors.grey,
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No deadlines found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'You are all caught up!',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: _deadlines.length,
                            itemBuilder: (context, index) {
                              return _buildDeadlineCard(_deadlines[index]);
                            },
                          ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineCard(Assignment assignment) {
    // Получаем информацию о курсе
    final course = _coursesMap[assignment.courseId];
    final courseName = course?.title ?? 'Unknown Course';

    // Форматируем дату дедлайна
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final deadlineDate = dateFormat.format(assignment.deadline);
    final deadlineTime = timeFormat.format(assignment.deadline);

    // Определяем цвет карточки в зависимости от срочности
    Color statusColor;
    String statusText;

    if (assignment.isOverdue) {
      statusColor = Colors.red;
      statusText = 'Overdue';
    } else if (assignment.isUrgent) {
      statusColor = Colors.orange;
      statusText = 'Due Soon';
    } else {
      statusColor = UAColors.azurite;
      statusText = 'Upcoming';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок задания
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: UAColors.blue,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        courseName,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Содержимое задания
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Дата и время дедлайна
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: UAColors.azurite,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Due: $deadlineDate at $deadlineTime',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Вес задания
                Row(
                  children: [
                    const Icon(
                      Icons.assessment,
                      color: UAColors.azurite,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Weight: ${assignment.weight}%',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Описание задания
                const Text(
                  'Description:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: UAColors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  assignment.body,
                  style: const TextStyle(
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 16),
                // Кнопки действий
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        // Действие для просмотра деталей
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('View Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: UAColors.azurite,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Действие для отправки задания
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Submit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: UAColors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
