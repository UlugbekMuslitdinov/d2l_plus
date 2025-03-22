import 'package:d2l_plus/constants/colors.dart';
import 'package:d2l_plus/screens/login_screen.dart';
import 'package:d2l_plus/screens/register_screen.dart';
import 'package:d2l_plus/tools/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Устанавливаем цвет статус-бара
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final storage = SecureStorage();

  // This widget is the root of your application.
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
  int _selectedIndex = 0;

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
      body: Center(
        child: _selectedIndex == 0
            ? const DashboardContent()
            : const Text('Other screens will be here'),
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

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

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
              _buildStatCard('Courses', '5', Icons.book, UAColors.red),
              _buildStatCard(
                  'New', '3', Icons.notifications_active, UAColors.azurite),
              _buildStatCard('Events', '2', Icons.event, UAColors.blue),
              _buildStatCard('Tasks', '7', Icons.assignment, UAColors.oasis),
            ],
          ),

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
