import 'package:d2l_plus/constants/colors.dart';
import 'package:d2l_plus/models/course.dart';
import 'package:d2l_plus/models/assignment.dart';
import 'package:d2l_plus/screens/available_courses_screen.dart';
import 'package:d2l_plus/screens/calendar_screen.dart';
import 'package:d2l_plus/screens/chat_bot_screen.dart';
import 'package:d2l_plus/screens/deadlines_screen.dart';
import 'package:d2l_plus/screens/login_screen.dart';
import 'package:d2l_plus/screens/register_screen.dart';
import 'package:d2l_plus/screens/course_details_screen.dart';
import 'package:d2l_plus/tools/backender.dart';
import 'package:d2l_plus/tools/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:d2l_plus/services/push_notification_service.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Настраиваем стили системного UI
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Запускаем приложение независимо от инициализации Firebase
  runApp(MyApp());

  // Пробуем инициализировать Firebase для уведомлений, но продолжаем работу приложения даже при ошибке
  try {
    await _initializeFirebase();
  } catch (e) {
    debugPrint('Ошибка инициализации Firebase: $e');
  }
}

// Отдельный метод для инициализации Firebase и сервиса уведомлений
Future<void> _initializeFirebase() async {
  try {
    // Инициализируем Firebase
    await Firebase.initializeApp();
    debugPrint('Firebase успешно инициализирован');

    // Инициализируем сервис уведомлений
    final pushNotificationService = PushNotificationService();
    await pushNotificationService.initialize();
    debugPrint('Сервис уведомлений успешно инициализирован');
  } catch (e) {
    debugPrint('Ошибка при инициализации Firebase или сервиса уведомлений: $e');
    rethrow; // Передаем ошибку дальше для обработки в main()
  }
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final storage = SecureStorage();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'D2L Plus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: UAColors.red,
          primary: UAColors.red,
          secondary: UAColors.azurite,
          background: UAColors.coolGray,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: UAColors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: UAColors.red,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: UAColors.coolGray.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: UAColors.azurite, width: 2),
          ),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            color: UAColors.blue,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(
            color: UAColors.azurite,
          ),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const Scaffold(body: LoginScreen()),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final _backender = Backender();
  final _storage = SecureStorage();
  List<Course> _courses = [];
  bool _isLoadingCourses = true;
  String _coursesError = '';

  @override
  void initState() {
    super.initState();
    _loadUserCourses();
  }

  Future<void> _loadUserCourses() async {
    try {
      final userId = await _storage.getUserId();
      if (userId == null || userId.isEmpty) {
        setState(() {
          _isLoadingCourses = false;
          _coursesError = 'User ID not found';
        });
        return;
      }

      final courses = await _backender.getUserCourses(userId);
      setState(() {
        _courses = courses;
        _isLoadingCourses = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCourses = false;
        _coursesError = e.toString();
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    await _storage.logOut();
    Navigator.pushReplacementNamed(context, '/');
  }

  void _openAvailableCourses() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AvailableCoursesScreen(
          onCourseEnrolled: _loadUserCourses,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('D2L Plus'),
        backgroundColor: UAColors.blue,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? _isLoadingCourses
              ? const Center(child: CircularProgressIndicator())
              : _coursesError.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Could not load courses: $_coursesError',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isLoadingCourses = true;
                                _coursesError = '';
                              });
                              _loadUserCourses();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : DashboardContent(courses: _courses)
          : _selectedIndex == 1
              ? CoursesScreen(
                  courses: _courses,
                  isLoading: _isLoadingCourses,
                  error: _coursesError,
                  onRefresh: _loadUserCourses,
                )
              : _selectedIndex == 2
                  ? const DeadlinesScreen()
                  : _selectedIndex == 3
                      ? const CalendarScreen()
                      : const ChatBotScreen(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Deadlines',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Assistant',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: UAColors.blue,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class CoursesScreen extends StatefulWidget {
  final List<Course> courses;
  final bool isLoading;
  final String error;
  final VoidCallback onRefresh;

  const CoursesScreen({
    Key? key,
    required this.courses,
    required this.isLoading,
    required this.error,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final _backender = Backender();
  final _storage = SecureStorage();
  bool _isProcessing = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    try {
      final userId = await _storage.getUserId();
      if (userId == null || userId.isEmpty) {
        return;
      }

      if (mounted) {
        setState(() {
          _userId = userId;
        });
      }
    } catch (e) {
      print('Error loading user ID: $e');
    }
  }

  Future<void> _dropCourse(Course course) async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User ID not found. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Получаем ID регистрации для данного курса
    final enrollmentId = course.enrollmentId;
    if (enrollmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enrollment ID not found for this course.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Показываем диалог подтверждения
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Drop Class'),
            content: Text('Are you sure you want to drop "${course.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('DROP', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      setState(() {
        _isProcessing = true;
      });

      final success = await _backender.dropCourse(enrollmentId);

      if (success) {
        // Обновляем список курсов
        widget.onRefresh();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully dropped "${course.title}"'),
              backgroundColor: UAColors.blue,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to drop the course. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            widget.onRefresh();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Courses',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: UAColors.blue,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (context.findAncestorStateOfType<_HomePageState>() !=
                            null) {
                          print("Button pressed");
                          context
                              .findAncestorStateOfType<_HomePageState>()!
                              ._openAvailableCourses();
                        }
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Enroll'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: UAColors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Access all your enrolled courses',
                  style: TextStyle(
                    fontSize: 16,
                    color: UAColors.azurite,
                  ),
                ),
                const SizedBox(height: 24),

                // Отображение курсов или индикатора загрузки
                widget.isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : widget.error.isNotEmpty
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
                                  widget.error,
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: widget.onRefresh,
                                  child: const Text('Try Again'),
                                ),
                              ],
                            ),
                          )
                        : widget.courses.isEmpty
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
                                      'No courses found',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Enroll in courses to see them here',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: widget.courses.length,
                                itemBuilder: (context, index) {
                                  return _buildDetailedCourseCard(
                                      widget.courses[index]);
                                },
                              ),
              ],
            ),
          ),
        ),
        if (_isProcessing)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Widget _buildDetailedCourseCard(Course course) {
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
                // Кнопки действий
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _dropCourse(course),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Drop'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Действие для перехода к курсу
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CourseDetailsScreen(course: course),
                          ),
                        );
                      },
                      icon: const Icon(Icons.login, color: Colors.white),
                      label: const Text('Enter Course'),
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

class DashboardContent extends StatefulWidget {
  final List<Course> courses;

  const DashboardContent({super.key, required this.courses});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  final _backender = Backender();
  final _storage = SecureStorage();
  List<Assignment> _deadlines = [];
  Map<String, Course> _coursesMap = {};
  bool _isLoadingDeadlines = true;
  String _deadlinesError = '';

  @override
  void initState() {
    super.initState();
    _loadDeadlines();
  }

  Future<void> _loadDeadlines() async {
    try {
      final userId = await _storage.getUserId();
      if (userId == null || userId.isEmpty) {
        setState(() {
          _isLoadingDeadlines = false;
          _deadlinesError = 'User ID not found';
        });
        return;
      }

      final deadlines = await _backender.getUserDeadlines(userId);

      // Создаем Map для быстрого доступа к курсам по ID
      final coursesMap = {for (var course in widget.courses) course.id: course};

      setState(() {
        _deadlines = deadlines;
        _coursesMap = coursesMap;
        _isLoadingDeadlines = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingDeadlines = false;
        _deadlinesError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome to D2L Plus',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: UAColors.blue,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'University of Arizona Learning System',
            style: TextStyle(
              fontSize: 16,
              color: UAColors.azurite,
            ),
          ),
          const SizedBox(height: 24),

          // Статистика
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard('Courses', widget.courses.length.toString(),
                  Icons.book, UAColors.red),
              _buildStatCard('Deadlines', _deadlines.length.toString(),
                  Icons.alarm, UAColors.azurite),
              _buildStatCard(
                  'Urgent',
                  _deadlines
                      .where((d) => d.isUrgent ?? false)
                      .length
                      .toString(),
                  Icons.priority_high,
                  Colors.orange),
              _buildStatCard(
                  'Overdue',
                  _deadlines
                      .where((d) => d.isOverdue ?? false)
                      .length
                      .toString(),
                  Icons.assignment_late,
                  Colors.red),
            ],
          ),

          const SizedBox(height: 24),

          // Секция курсов
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Courses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: UAColors.blue,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Переключаемся на вкладку Courses
                  if (context.findAncestorStateOfType<_HomePageState>() !=
                      null) {
                    context
                        .findAncestorStateOfType<_HomePageState>()!
                        ._onItemTapped(1);
                  }
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Отображение курсов
          widget.courses.isEmpty
              ? const Center(
                  child: Text(
                    'No courses found. Enroll in courses to see them here.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: widget.courses.length > 2
                      ? 2
                      : widget.courses.length, // Показываем только до 2 курсов
                  itemBuilder: (context, index) {
                    return _buildCourseCard(widget.courses[index]);
                  },
                ),

          // Кнопка "Show More" отображается, если есть больше 2 курсов
          if (widget.courses.length > 2) ...[
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton(
                onPressed: () {
                  // Переключаемся на вкладку Courses
                  if (context.findAncestorStateOfType<_HomePageState>() !=
                      null) {
                    context
                        .findAncestorStateOfType<_HomePageState>()!
                        ._onItemTapped(1);
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: UAColors.azurite,
                ),
                child: const Text('Show More Courses'),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Секция ближайших дедлайнов
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: UAColors.blue,
                ),
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      // Переключаемся на вкладку Calendar
                      if (context.findAncestorStateOfType<_HomePageState>() !=
                          null) {
                        context
                            .findAncestorStateOfType<_HomePageState>()!
                            ._onItemTapped(3);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: const Text('Calendar'),
                    style: TextButton.styleFrom(
                      foregroundColor: UAColors.azurite,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Переключаемся на вкладку Deadlines
                      if (context.findAncestorStateOfType<_HomePageState>() !=
                          null) {
                        context
                            .findAncestorStateOfType<_HomePageState>()!
                            ._onItemTapped(2);
                      }
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Отображение ближайших дедлайнов
          _isLoadingDeadlines
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _deadlinesError.isNotEmpty
                  ? Center(
                      child: Text(
                        'Could not load deadlines: $_deadlinesError',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : _deadlines.isEmpty
                      ? const Center(
                          child: Text(
                            'No upcoming deadlines. You are all caught up!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: _deadlines.length > 2
                              ? 2
                              : _deadlines
                                  .length, // Показываем только до 2 дедлайнов
                          itemBuilder: (context, index) {
                            return _buildDeadlineCard(_deadlines[index]);
                          },
                        ),

          // Кнопка "Show More" отображается, если есть больше 2 дедлайнов
          if (_deadlines.length > 2) ...[
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton(
                onPressed: () {
                  // Переключаемся на вкладку Deadlines
                  if (context.findAncestorStateOfType<_HomePageState>() !=
                      null) {
                    context
                        .findAncestorStateOfType<_HomePageState>()!
                        ._onItemTapped(2);
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: UAColors.azurite,
                ),
                child: const Text('Show More Deadlines'),
              ),
            ),
          ],

          const SizedBox(height: 24),
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: UAColors.blue,
            ),
          ),
          const SizedBox(height: 16),

          // Список последних действий
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: 5,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              return _buildActivityItem(index);
            },
          ),
        ],
      ),
    );
  }

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
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Переход на вкладку дедлайнов
          if (context.findAncestorStateOfType<_HomePageState>() != null) {
            context.findAncestorStateOfType<_HomePageState>()!._onItemTapped(2);
          }
        },
        borderRadius: BorderRadius.circular(12),
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
                    const SizedBox(height: 8),
                    Text(
                      'Due in ${assignment.daysLeft ?? 0} days',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
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
                    color: UAColors.azurite.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.book,
                    color: UAColors.azurite,
                    size: 30,
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
                          color: UAColors.blue,
                        ),
                      ),
                      Text(
                        course.semester,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Lectures:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: UAColors.azurite,
              ),
            ),
            const SizedBox(height: 8),
            ...course.lectures
                .map((lecture) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.circle,
                            size: 10,
                            color: UAColors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(lecture),
                        ],
                      ),
                    ))
                .toList(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // Действие при нажатии "View Details"
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CourseDetailsScreen(course: course),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility, color: UAColors.azurite),
                  label: const Text(
                    'View Details',
                    style: TextStyle(color: UAColors.azurite),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(int index) {
    final List<Map<String, dynamic>> activities = [
      {
        'title': 'New Task',
        'description': 'Mathematical Analysis - Homework #5',
        'time': '2 hours ago',
        'icon': Icons.assignment,
        'color': UAColors.red,
      },
      {
        'title': 'Course Update',
        'description': 'Python Programming - New Materials',
        'time': '4 hours ago',
        'icon': Icons.book,
        'color': UAColors.azurite,
      },
      {
        'title': 'Teacher Comment',
        'description': 'Physics - Feedback on Lab Work',
        'time': 'Yesterday',
        'icon': Icons.chat,
        'color': UAColors.blue,
      },
      {
        'title': 'Announcement',
        'description': 'Chemistry - Changes to Schedule',
        'time': 'Yesterday',
        'icon': Icons.announcement,
        'color': UAColors.oasis,
      },
      {
        'title': 'Grading',
        'description': 'History - Final Essay Grade',
        'time': '2 days ago',
        'icon': Icons.grading,
        'color': UAColors.leaf,
      },
    ];

    final activity = activities[index];

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: activity['color'].withOpacity(0.2),
        child: Icon(activity['icon'], color: activity['color']),
      ),
      title: Text(activity['title']),
      subtitle: Text(activity['description']),
      trailing: Text(
        activity['time'],
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
  }
}
