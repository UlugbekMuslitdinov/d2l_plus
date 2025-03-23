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
  Map<String, Course> _coursesMap = {};
  bool _isLoading = true;
  String _error = '';

  // Переменные для календаря
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Для хранения заданий по датам
  Map<DateTime, List<Assignment>> _eventsByDate = {};

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

      setState(() {
        _deadlines = deadlines;
        _coursesMap = coursesMap;
        _eventsByDate = eventsByDate;
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

  // Получение списка заданий для выбранного дня
  List<Assignment> _getEventsForDay(DateTime day) {
    // Нормализуем дату (убираем время)
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _eventsByDate[normalizedDay] ?? [];
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
              'Календарь дедлайнов',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: UAColors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Просмотр предстоящих дедлайнов в календаре',
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
                                  markersMaxCount: 3,
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

                          // Заголовок для списка заданий
                          _selectedDay != null
                              ? Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    'Задания на ${DateFormat('dd MMMM yyyy').format(_selectedDay!)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: UAColors.blue,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),

                          // Список заданий на выбранный день
                          _selectedDay != null
                              ? _getEventsForDay(_selectedDay!).isNotEmpty
                                  ? ListView.builder(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      itemCount: _getEventsForDay(_selectedDay!)
                                          .length,
                                      itemBuilder: (context, index) {
                                        return _buildDeadlineCard(
                                            _getEventsForDay(
                                                _selectedDay!)[index]);
                                      },
                                    )
                                  : const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Text(
                                          'Нет заданий на этот день',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    )
                              : const SizedBox.shrink(),
                        ],
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineCard(Assignment assignment) {
    // Получаем информацию о курсе
    final course = _coursesMap[assignment.courseId];
    final courseName = course?.title ?? 'Неизвестный курс';

    // Форматируем время дедлайна
    final timeFormat = DateFormat('HH:mm');
    final deadlineTime = timeFormat.format(assignment.deadline);

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
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
            const SizedBox(width: 12),
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
                  const SizedBox(height: 4),
                  Text(
                    'Время: $deadlineTime',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Вес: ${assignment.weight}%',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: UAColors.azurite,
              ),
              onPressed: () {
                // Действие при нажатии на задание
              },
            )
          ],
        ),
      ),
    );
  }
}
