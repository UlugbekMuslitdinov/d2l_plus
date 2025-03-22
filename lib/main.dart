import 'package:d2l_plus/constants/colors.dart';
import 'package:d2l_plus/screens/login_screen.dart';
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
      home: const Scaffold(
        body: LoginScreen(),
      ),
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => const Scaffold(
                  body: LoginScreen(),
                )),
      );
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
            tooltip: 'Выйти из аккаунта',
          ),
        ],
      ),
      body: Center(
        child: _selectedIndex == 0
            ? const DashboardContent()
            : const Text('Другие экраны будут здесь'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Курсы',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Календарь',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Уведомления',
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
            'Добро пожаловать в D2L Plus',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: UAColors.blue,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Система обучения Университета Аризоны',
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
              _buildStatCard('Курсы', '5', Icons.book, UAColors.red),
              _buildStatCard('Непрочитанные', '3', Icons.notifications_active,
                  UAColors.azurite),
              _buildStatCard('События', '2', Icons.event, UAColors.blue),
              _buildStatCard('Задания', '7', Icons.assignment, UAColors.oasis),
            ],
          ),

          const SizedBox(height: 24),
          const Text(
            'Недавняя активность',
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
              fontSize: 24,
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
        'title': 'Новое задание',
        'description': 'Математический анализ - Домашнее задание #5',
        'time': '2 часа назад',
        'icon': Icons.assignment,
        'color': UAColors.red,
      },
      {
        'title': 'Обновление курса',
        'description': 'Программирование на Python - Новые материалы',
        'time': '4 часа назад',
        'icon': Icons.book,
        'color': UAColors.azurite,
      },
      {
        'title': 'Комментарий преподавателя',
        'description': 'Физика - Обратная связь по лабораторной работе',
        'time': 'Вчера',
        'icon': Icons.chat,
        'color': UAColors.blue,
      },
      {
        'title': 'Новое объявление',
        'description': 'Химия - Изменение расписания занятий',
        'time': 'Вчера',
        'icon': Icons.announcement,
        'color': UAColors.oasis,
      },
      {
        'title': 'Оценка за задание',
        'description': 'История - Итоговая оценка за эссе',
        'time': '2 дня назад',
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
