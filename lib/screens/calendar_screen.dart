import 'package:d2l_plus/constants/colors.dart';
import 'package:d2l_plus/models/assignment.dart';
import 'package:d2l_plus/models/course.dart';
import 'package:d2l_plus/tools/backender.dart';
import 'package:d2l_plus/tools/storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _backender = Backender();
  final _storage = SecureStorage();
  List<Assignment> _deadlines = [];
  List<Course> _courses = [];
  Map<String, Course> _coursesMap = {};
  bool _isLoading = true;
  String _error = '';

  // Переменные для календаря
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Для хранения заданий по датам
  Map<DateTime, List<Assignment>> _eventsByDate = {};

  // Для хранения дней занятий
  Map<DateTime, List<Course>> _classesByDate = {};

  // Для хранения всех событий (занятия + дедлайны)
  Map<DateTime, List<dynamic>> _allEventsByDate = {};

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
          _error = 'ID пользователя не найден. Пожалуйста, войдите снова.';
        });
        return;
      }

      // Получаем список дедлайнов
      final deadlines = await _backender.getUserDeadlines(userId);

      // Получаем список курсов пользователя
      final courses = await _backender.getUserCourses(userId);

      // Создаем Map для быстрого доступа к курсам по ID
      final coursesMap = {for (var course in courses) course.id: course};

      // Организуем задания по датам для календаря
      final eventsByDate = <DateTime, List<Assignment>>{};

      for (var assignment in deadlines) {
        // Получаем дату без времени для группировки
        final date = DateTime(
          assignment.deadline.year,
          assignment.deadline.month,
          assignment.deadline.day,
        );

        if (eventsByDate[date] == null) {
          eventsByDate[date] = [];
        }

        eventsByDate[date]!.add(assignment);
      }

      // Организуем занятия по датам для календаря
      final classesByDate = _generateClassDates(courses);

      // Объединяем все события
      final allEventsByDate = <DateTime, List<dynamic>>{};

      // Добавляем дедлайны
      eventsByDate.forEach((date, assignments) {
        if (allEventsByDate[date] == null) {
          allEventsByDate[date] = [];
        }
        allEventsByDate[date]!.addAll(assignments);
      });

      // Добавляем занятия
      classesByDate.forEach((date, courses) {
        if (allEventsByDate[date] == null) {
          allEventsByDate[date] = [];
        }
        allEventsByDate[date]!.addAll(courses);
      });

      setState(() {
        _deadlines = deadlines;
        _courses = courses;
        _coursesMap = coursesMap;
        _eventsByDate = eventsByDate;
        _classesByDate = classesByDate;
        _allEventsByDate = allEventsByDate;
        _isLoading = false;

        // Устанавливаем выбранный день как сегодня
        _selectedDay = _focusedDay;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Не удалось загрузить данные: ${e.toString()}';
      });
    }
  }

  // Генерирует даты занятий на текущий месяц
  Map<DateTime, List<Course>> _generateClassDates(List<Course> courses) {
    final classesByDate = <DateTime, List<Course>>{};

    // Получаем начало и конец месяца для генерации дат
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate =
        DateTime(now.year, now.month + 3, 0); // Генерируем на 3 месяца вперед

    // Мапа для перевода дней недели из строки в число (1 = понедельник, 7 = воскресенье)
    final weekdayMap = {
      'Monday': 1,
      'Tuesday': 2,
      'Wednesday': 3,
      'Thursday': 4,
      'Friday': 5,
      'Saturday': 6,
      'Sunday': 7,
    };

    // Для каждого курса создаем даты занятий на выбранный период
    for (var course in courses) {
      // Для каждого дня недели
      for (var weekday in course.weekdays) {
        // Получаем номер дня недели
        final weekdayNum = weekdayMap[weekday] ?? 1;

        // Находим первое занятие в месяце для этого дня недели
        var classDate = startDate;
        while (classDate.weekday != weekdayNum) {
          classDate = classDate.add(const Duration(days: 1));
        }

        // Генерируем все даты занятий до конца периода
        while (classDate.isBefore(endDate)) {
          final normalizedDate =
              DateTime(classDate.year, classDate.month, classDate.day);

          if (classesByDate[normalizedDate] == null) {
            classesByDate[normalizedDate] = [];
          }

          classesByDate[normalizedDate]!.add(course);

          // Следующее занятие через неделю
          classDate = classDate.add(const Duration(days: 7));
        }
      }
    }

    return classesByDate;
  }

  // Получение списка событий для выбранного дня
  List<dynamic> _getEventsForDay(DateTime day) {
    // Нормализуем дату (убираем время)
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _allEventsByDate[normalizedDay] ?? [];
  }

  // Получение списка дедлайнов для выбранного дня
  List<Assignment> _getDeadlinesForDay(DateTime day) {
    // Нормализуем дату (убираем время)
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _eventsByDate[normalizedDay] ?? [];
  }

  // Получение списка занятий для выбранного дня
  List<Course> _getClassesForDay(DateTime day) {
    // Нормализуем дату (убираем время)
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _classesByDate[normalizedDay] ?? [];
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
              'Календарь',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: UAColors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Просмотр расписания занятий и дедлайнов',
              style: TextStyle(
                fontSize: 16,
                color: UAColors.azurite,
              ),
            ),
            const SizedBox(height: 24),

            // Отображение календаря или индикатора загрузки
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
                              child: const Text('Попробовать снова'),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          // Календарь
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TableCalendar(
                                firstDay: DateTime.utc(2023, 1, 1),
                                lastDay: DateTime.utc(2030, 12, 31),
                                focusedDay: _focusedDay,
                                calendarFormat: _calendarFormat,
                                eventLoader: _getEventsForDay,
                                selectedDayPredicate: (day) {
                                  return isSameDay(_selectedDay, day);
                                },
                                onDaySelected: (selectedDay, focusedDay) {
                                  setState(() {
                                    _selectedDay = selectedDay;
                                    _focusedDay = focusedDay;
                                  });
                                },
                                onFormatChanged: (format) {
                                  setState(() {
                                    _calendarFormat = format;
                                  });
                                },
                                onPageChanged: (focusedDay) {
                                  _focusedDay = focusedDay;
                                },
                                calendarStyle: const CalendarStyle(
                                  markersMaxCount: 4,
                                  markerDecoration: BoxDecoration(
                                    color: UAColors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  todayDecoration: BoxDecoration(
                                    color: UAColors.azurite,
                                    shape: BoxShape.circle,
                                  ),
                                  selectedDecoration: BoxDecoration(
                                    color: UAColors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                headerStyle: const HeaderStyle(
                                  formatButtonDecoration: BoxDecoration(
                                    color: UAColors.azurite,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(12.0),
                                    ),
                                  ),
                                  formatButtonTextStyle: TextStyle(
                                    color: Colors.white,
                                  ),
                                  titleCentered: true,
                                  formatButtonShowsNext: false,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Заголовок для выбранного дня
                          _selectedDay != null
                              ? Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    'События на ${DateFormat('dd MMMM yyyy').format(_selectedDay!)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: UAColors.blue,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),

                          // Занятия на выбранный день
                          if (_selectedDay != null)
                            ..._buildClassesForSelectedDay(),

                          // Дедлайны на выбранный день
                          if (_selectedDay != null)
                            ..._buildDeadlinesForSelectedDay(),
                        ],
                      ),
          ],
        ),
      ),
    );
  }

  // Отображение занятий на выбранный день
  List<Widget> _buildClassesForSelectedDay() {
    final classes = _getClassesForDay(_selectedDay!);

    if (classes.isEmpty) {
      return [];
    }

    return [
      const Padding(
        padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
        child: Text(
          'Занятия:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: UAColors.azurite,
          ),
        ),
      ),
      ...classes.map((course) => _buildClassCard(course)).toList(),
      const SizedBox(height: 8),
    ];
  }

  // Отображение дедлайнов на выбранный день
  List<Widget> _buildDeadlinesForSelectedDay() {
    final deadlines = _getDeadlinesForDay(_selectedDay!);

    if (deadlines.isEmpty) {
      return [];
    }

    return [
      const Padding(
        padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
        child: Text(
          'Дедлайны:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: UAColors.azurite,
          ),
        ),
      ),
      ...deadlines.map((assignment) => _buildDeadlineCard(assignment)).toList(),
    ];
  }

  // Карточка для отображения занятия
  Widget _buildClassCard(Course course) {
    // Получаем время занятия из строки формата "14:00-15:30"
    String startTime = '';
    String endTime = '';

    if (course.lectureTime.contains('-')) {
      final times = course.lectureTime.split('-');
      startTime = times[0];
      endTime = times[1];
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showCourseDetails(course),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: UAColors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.school,
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
                      course.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: UAColors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${startTime} - ${endTime}',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // Показывает диалог с подробной информацией о курсе
  void _showCourseDetails(Course course) {
    // Получаем время занятия
    String startTime = '';
    String endTime = '';
    if (course.lectureTime.contains('-')) {
      final times = course.lectureTime.split('-');
      startTime = times[0];
      endTime = times[1];
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(course.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Semester', course.semester),
              _buildInfoRow('Days', course.weekdays.join(', ')),
              _buildInfoRow('Time', '${startTime} - ${endTime}'),
              const SizedBox(height: 16),
              const Text(
                'Lectures:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: UAColors.blue,
                ),
              ),
              const SizedBox(height: 8),
              ...course.lectures
                  .map((lecture) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.circle,
                              size: 10,
                              color: UAColors.red,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(lecture)),
                          ],
                        ),
                      ))
                  .toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Вспомогательный метод для создания строки информации
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: UAColors.azurite,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Карточка для отображения дедлайна
  Widget _buildDeadlineCard(Assignment assignment) {
    // Получаем информацию о курсе
    final course = _coursesMap[assignment.courseId];
    final courseName = course?.title ?? 'Unknown Course';

    // Определяем цвет карточки в зависимости от срочности
    Color statusColor;
    IconData statusIcon;

    if (assignment.isOverdue ?? false) {
      statusColor = Colors.red;
      statusIcon = Icons.error_outline;
    } else if (assignment.isUrgent ?? false) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning_amber_outlined;
    } else {
      statusColor = UAColors.azurite;
      statusIcon = Icons.access_time;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showDeadlineDetails(assignment, courseName),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: UAColors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      courseName,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (assignment.dateTime != null)
                      Text(
                        DateFormat('HH:mm').format(assignment.dateTime!),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // Показывает диалог с подробной информацией о дедлайне
  void _showDeadlineDetails(Assignment assignment, String courseName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(assignment.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Course', courseName),
              _buildInfoRow('Weight', '${assignment.weight}%'),
              _buildInfoRow(
                  'Deadline',
                  DateFormat('dd MMMM yyyy, HH:mm')
                      .format(assignment.deadline)),
              if (assignment.daysLeft != null)
                _buildInfoRow(
                  'Days Left',
                  assignment.isOverdue ?? false
                      ? 'Overdue'
                      : '${assignment.daysLeft} ${assignment.daysLeft == 1 ? 'day' : 'days'}',
                ),
              const SizedBox(height: 16),
              const Text(
                'Description:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: UAColors.blue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                assignment.body,
                style: const TextStyle(
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // В будущем здесь можно добавить функционал отправки задания
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This feature will be available soon!'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: UAColors.red,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
