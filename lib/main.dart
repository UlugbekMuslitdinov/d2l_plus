import 'package:d2l_plus/constants/colors.dart';
import 'package:d2l_plus/models/course.dart';
import 'package:d2l_plus/screens/available_courses_screen.dart';
import 'package:d2l_plus/screens/login_screen.dart';
import 'package:d2l_plus/screens/register_screen.dart';
import 'package:d2l_plus/tools/backender.dart';
import 'package:d2l_plus/tools/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(MyApp());
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
  final storage = SecureStorage();
  final _backender = Backender();
  List<Course> _courses = [];
  bool _isLoading = true;
  String _error = '';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserCourses();
  }

  Future<void> _loadUserCourses() async {
    try {
      final userId = await storage.getUserId();
      if (userId == null || userId.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'User ID not found. Please log in again.';
        });
        return;
      }

      final courses = await _backender.getUserCourses(userId);
      setState(() {
        _courses = courses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load courses: ${e.toString()}';
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    await storage.logOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? DashboardContent(courses: _courses)
          : _selectedIndex == 1
              ? CoursesScreen(
                  courses: _courses,
                  isLoading: _isLoading,
                  error: _error,
                  onRefresh: _loadUserCourses,
                )
              : const Center(
                  child: Text('Other screens will be here'),
                ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: UAColors.red,
        unselectedItemColor: UAColors.azurite,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class CoursesScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
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
                      context
                          .findAncestorStateOfType<_HomePageState>()!
                          ._openAvailableCourses();
                    }
                  },
                  icon: const Icon(Icons.add),
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
            isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : error.isNotEmpty
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
                              error,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: onRefresh,
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      )
                    : courses.isEmpty
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
                            itemCount: courses.length,
                            itemBuilder: (context, index) {
                              return _buildDetailedCourseCard(courses[index]);
                            },
                          ),
          ],
        ),
      ),
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
                  'Лекции:',
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
                      onPressed: () {
                        // Действие для открытия материалов
                      },
                      icon: const Icon(Icons.menu_book),
                      label: const Text('Materials'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: UAColors.azurite,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Действие для перехода к курсу
                      },
                      icon: const Icon(Icons.login),
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
              _buildStatCard(
                  'New', '3', Icons.notifications_active, UAColors.azurite),
              _buildStatCard('Events', '2', Icons.event, UAColors.blue),
              _buildStatCard('Tasks', '7', Icons.assignment, UAColors.oasis),
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
