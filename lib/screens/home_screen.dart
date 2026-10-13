import 'package:flutter/material.dart';
import 'stats_screen.dart';
import 'habits_screen.dart';
import 'addictions_screen.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';
import '../services/stats_service.dart';
import '../services/habit_service.dart';
import '../services/user_profile_service.dart';
import '../models/user_profile.dart';

class HomeScreen extends StatefulWidget {
  final String email;
  
  const HomeScreen({super.key, required this.email});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final StatsService _statsService = StatsService();
  final HabitService _habitService = HabitService();
  final UserProfileService _userProfileService = UserProfileService();
  UserProfile? _userProfile;
  Map<String, dynamic> _stats = {
    'habits': 0, 
    'days': 0, 
    'achievements': 0,
    'dailyProgress': 0.0,
    'currentStreak': 0,
  };

  @override
  void initState() {
    super.initState();
    _statsService.initializeFirstLaunch();
    _loadStats();
    _loadUserProfile();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      await _habitService.initializeNotifications();
    } catch (e) {
      debugPrint('Error inicializando notificaciones: $e');
    }
  }

  Future<void> _loadStats() async {
    final stats = await _statsService.getStats();
    setState(() {
      _stats = stats;
    });
  }

  Future<void> _loadUserProfile() async {
    final profile = await _userProfileService.getProfile();
    setState(() {
      _userProfile = profile;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recargar estadísticas siempre que volvemos a esta pantalla
    _loadStats();
  }

  List<Widget> _getScreens() {
    return [
      _buildHomeContent(),
      const StatsScreen(),
      const HabitsScreen(),
      const AddictionsScreen(),
    ];
  }

  Widget _buildHomeContent() {
    return Scaffold(
      appBar: AppBar(
        title: Text(_userProfile?.fullName.isNotEmpty == true 
            ? 'Bienvenido, ${_userProfile!.firstName}'
            : 'Bienvenido, ${widget.email.split('@')[0]}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF3A3634),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.psychology,
                    size: 100,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'StepMind',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tu compañero para desarrollar hábitos positivos',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[300],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CalendarScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Ver Calendario'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF3A3634),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard('Hábitos', '${_stats['habits']}', Icons.trending_up),
                  _buildProgressCard('Progreso', '${_stats['dailyProgress'].toStringAsFixed(0)}%'),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Recargar estadísticas cuando volvemos al inicio
          if (index == 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadStats();
            });
          }
        },
        backgroundColor: const Color(0xFF3A3634),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey[400],
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Estadísticas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt),
            label: 'Hábitos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology),
            label: 'Adicciones',
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4A4543),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.pie_chart,
            color: Colors.white,
            size: 30,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4A4543),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = _getScreens();
    
    if (_currentIndex == 0) {
      return _buildHomeContent();
    }

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: const Color(0xFF3A3634),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey[400],
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Estadísticas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt),
            label: 'Hábitos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology),
            label: 'Adicciones',
          ),
        ],
      ),
    );
  }
}
