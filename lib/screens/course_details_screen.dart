import 'package:d2l_plus/constants/colors.dart';
import 'package:d2l_plus/models/announcement.dart';
import 'package:d2l_plus/models/assignment.dart';
import 'package:d2l_plus/models/course.dart';
import 'package:d2l_plus/models/grade.dart';
import 'package:d2l_plus/tools/backender.dart';
import 'package:d2l_plus/tools/storage.dart';
import 'package:flutter/material.dart';

class CourseDetailsScreen extends StatefulWidget {
  final Course course;

  const CourseDetailsScreen({Key? key, required this.course}) : super(key: key);

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _backender = Backender();
  final _storage = SecureStorage();
  String? _userId;

  // Данные для вкладки "Объявления"
  bool _isLoadingAnnouncements = true;
  List<Announcement> _announcements = [];
  String _announcementsError = '';

  // Данные для вкладки "Задания"
  bool _isLoadingAssignments = true;
  List<Assignment> _assignments = [];
  String _assignmentsError = '';

  // Данные для вкладки "Оценки"
  bool _isLoadingGrades = true;
  List<Grade> _grades = [];
  String _gradesError = '';
  double _averageGrade = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserId().then((_) {
      _loadAnnouncements();
      _loadAssignments();
      if (_userId != null) {
        _loadGrades();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Загрузка ID пользователя
  Future<void> _loadUserId() async {
    try {
      final userId = await _storage.getUserId();
      if (userId != null && userId.isNotEmpty) {
        setState(() {
          _userId = userId;
        });
      }
    } catch (e) {
      print('Error loading user ID: $e');
    }
  }

  // Загрузка объявлений для курса
  Future<void> _loadAnnouncements() async {
    try {
      setState(() {
        _isLoadingAnnouncements = true;
        _announcementsError = '';
      });

      final announcements =
          await _backender.getCourseAnnouncements(widget.course.id);

      setState(() {
        _announcements = announcements;
        _isLoadingAnnouncements = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAnnouncements = false;
        _announcementsError = e.toString();
      });
    }
  }

  // Загрузка заданий для курса
  Future<void> _loadAssignments() async {
    try {
      setState(() {
        _isLoadingAssignments = true;
        _assignmentsError = '';
      });

      // Получаем все дедлайны пользователя
      final userId = await _storage.getUserId();
      if (userId == null || userId.isEmpty) {
        setState(() {
          _isLoadingAssignments = false;
          _assignmentsError = 'User not found';
        });
        return;
      }

      final allAssignments = await _backender.getUserDeadlines(userId);

      // Фильтруем дедлайны только для текущего курса
      final courseAssignments = allAssignments
          .where((assignment) => assignment.courseId == widget.course.id)
          .toList();

      // Сортируем по дате дедлайна (сначала ближайшие)
      courseAssignments.sort((a, b) => a.deadline.compareTo(b.deadline));

      setState(() {
        _assignments = courseAssignments;
        _isLoadingAssignments = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAssignments = false;
        _assignmentsError = e.toString();
      });
    }
  }

  // Загрузка оценок для курса
  Future<void> _loadGrades() async {
    if (_userId == null) return;

    try {
      setState(() {
        _isLoadingGrades = true;
        _gradesError = '';
      });

      final grades =
          await _backender.getCourseGrades(widget.course.id, _userId!);

      // Вычисляем среднюю оценку
      double total = 0;
      if (grades.isNotEmpty) {
        for (var grade in grades) {
          total += grade.grade;
        }
        _averageGrade = total / grades.length;
      }

      setState(() {
        _grades = grades;
        _isLoadingGrades = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingGrades = false;
        _gradesError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.title),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Announcements'),
            Tab(text: 'Assignments'),
            Tab(text: 'Grades'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Вкладка "Объявления"
          _buildAnnouncementsTab(),

          // Вкладка "Задания"
          _buildAssignmentsTab(),

          // Вкладка "Оценки"
          _buildGradesTab(),
        ],
      ),
    );
  }

  // Формирование вкладки "Объявления"
  Widget _buildAnnouncementsTab() {
    return RefreshIndicator(
      onRefresh: _loadAnnouncements,
      child: _isLoadingAnnouncements
          ? const Center(child: CircularProgressIndicator())
          : _announcementsError.isNotEmpty
              ? _buildErrorView(_announcementsError, _loadAnnouncements)
              : _announcements.isEmpty
                  ? _buildEmptyAnnouncementsView()
                  : _buildAnnouncementsList(),
    );
  }

  // Формирование вкладки "Задания"
  Widget _buildAssignmentsTab() {
    return RefreshIndicator(
      onRefresh: _loadAssignments,
      child: _isLoadingAssignments
          ? const Center(child: CircularProgressIndicator())
          : _assignmentsError.isNotEmpty
              ? _buildErrorView(_assignmentsError, _loadAssignments)
              : _assignments.isEmpty
                  ? _buildEmptyAssignmentsView()
                  : _buildAssignmentsList(),
    );
  }

  // Формирование вкладки "Оценки"
  Widget _buildGradesTab() {
    if (_userId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load grades: User ID not found',
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGrades,
      child: _isLoadingGrades
          ? const Center(child: CircularProgressIndicator())
          : _gradesError.isNotEmpty
              ? _buildErrorView(_gradesError, _loadGrades)
              : _grades.isEmpty
                  ? _buildEmptyGradesView()
                  : _buildGradesContent(),
    );
  }

  // Отображение сообщения об ошибке с кнопкой повторной загрузки
  Widget _buildErrorView(String errorMessage, VoidCallback onRetry) {
    return Center(
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
            'An error occurred: $errorMessage',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  // Отображение сообщения об отсутствии объявлений
  Widget _buildEmptyAnnouncementsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.campaign_outlined,
            color: Colors.grey,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'No announcements',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Announcements from the teacher will be displayed here',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Отображение сообщения об отсутствии заданий
  Widget _buildEmptyAssignmentsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.assignment_outlined,
            color: Colors.grey,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'No assignments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Assignments for this course will be displayed here',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Отображение сообщения об отсутствии оценок
  Widget _buildEmptyGradesView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.grading_outlined,
            color: Colors.grey,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'No grades',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your grades will be displayed here after being assigned',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Отображение списка объявлений
  Widget _buildAnnouncementsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _announcements.length,
      itemBuilder: (context, index) {
        final announcement = _announcements[index];
        return _buildAnnouncementCard(announcement);
      },
    );
  }

  // Отображение списка заданий
  Widget _buildAssignmentsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _assignments.length,
      itemBuilder: (context, index) {
        final assignment = _assignments[index];
        return _buildAssignmentCard(assignment);
      },
    );
  }

  // Отображение содержимого вкладки "Оценки"
  Widget _buildGradesContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Карточка со средней оценкой
          _buildAverageGradeCard(),

          const SizedBox(height: 24),

          // Заголовок списка оценок
          const Text(
            'My grades',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: UAColors.blue,
            ),
          ),
          const SizedBox(height: 16),

          // Список оценок
          ...List.generate(_grades.length, (index) {
            return _buildGradeCard(_grades[index]);
          }),
        ],
      ),
    );
  }

  // Карточка задания
  Widget _buildAssignmentCard(Assignment assignment) {
    // Определяем статус и цвет
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (assignment.isOverdue ?? false) {
      statusColor = Colors.red;
      statusIcon = Icons.error_outline;
      statusText = 'Overdue';
    } else if (assignment.isUrgent ?? false) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning_amber_outlined;
      statusText = 'Urgent';
    } else {
      statusColor = UAColors.azurite;
      statusIcon = Icons.access_time;
      statusText = 'In progress';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: UAColors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            assignment.formattedDate,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (assignment.body.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                assignment.body,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weight: ${assignment.weight}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: UAColors.blue,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    // Действие просмотра деталей
                  },
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('Details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: UAColors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    // Действие отправки работы
                  },
                  icon: const Icon(Icons.upload_file, size: 18, color: Colors.white),
                  label: const Text('Send'),
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
    );
  }

  // Карточка со средней оценкой
  Widget _buildAverageGradeCard() {
    // Определяем цвет в зависимости от средней оценки
    final Color gradeColor = Grade.getGradeColor(_averageGrade.round());

    // Определяем буквенную оценку
    String letterGrade = 'F';
    if (_averageGrade >= 90)
      letterGrade = 'A';
    else if (_averageGrade >= 80)
      letterGrade = 'B';
    else if (_averageGrade >= 70)
      letterGrade = 'C';
    else if (_averageGrade >= 60) letterGrade = 'D';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: gradeColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  letterGrade,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: gradeColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Average grade',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_averageGrade.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total grades: ${_grades.length}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Карточка с оценкой
  Widget _buildGradeCard(Grade grade) {
    final Color gradeColor = Grade.getGradeColor(grade.grade);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: gradeColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  grade.letterGrade,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: gradeColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grade.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    grade.formattedDate,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${grade.grade}%',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: gradeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Карточка объявления
  Widget _buildAnnouncementCard(Announcement announcement) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: UAColors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.campaign,
                    color: UAColors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        announcement.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: UAColors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        announcement.relativeTime,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              announcement.body,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
