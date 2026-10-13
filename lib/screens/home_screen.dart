import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../services/notification_service.dart';
import 'addictions_screen.dart';
import 'calendar_screen.dart';
import 'habits_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final String email;

  const HomeScreen({super.key, required this.email});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _habitsTab = 2;

  final _notifications = NotificationService();
  int _currentIndex = 0;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Al volver a la app puede haber cambiado el día: los recordatorios de
    // hoy deben volver a sonar para los hábitos aún pendientes.
    _lifecycle = AppLifecycleListener(
      onResume: () {
        ref.read(todayProvider.notifier).refresh();
        ref.read(habitsProvider.notifier).syncReminders();
      },
    );
    ref.read(habitsProvider.notifier).syncReminders();

    _notifications.openHabitsRequested.addListener(_openHabitsFromNotification);
    // Si la app se abrió tocando un recordatorio.
    WidgetsBinding.instance.addPostFrameCallback((_) => _openHabitsFromNotification());
  }

  void _openHabitsFromNotification() {
    if (!mounted || !_notifications.openHabitsRequested.value) return;
    _notifications.openHabitsRequested.value = false;
    Navigator.of(context).popUntil((route) => route.isFirst);
    setState(() => _currentIndex = _habitsTab);
  }

  @override
  void dispose() {
    _notifications.openHabitsRequested.removeListener(_openHabitsFromNotification);
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTab(email: widget.email),
          const StatsScreen(),
          const HabitsScreen(),
          const AddictionsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF3A3634),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey[400],
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Estadísticas'),
          BottomNavigationBarItem(icon: Icon(Icons.task_alt), label: 'Hábitos'),
          BottomNavigationBarItem(icon: Icon(Icons.psychology), label: 'Adicciones'),
        ],
      ),
    );
  }
}

class _HomeTab extends ConsumerWidget {
  final String email;

  const _HomeTab({required this.email});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    final stats = ref.watch(statsProvider).value;
    final firstName = profile?.firstName ?? '';
    final greetingName = firstName.isNotEmpty ? firstName : email.split('@').first;

    return Scaffold(
      appBar: AppBar(
        title: Text('Bienvenido, $greetingName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Ajustes',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
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
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const CalendarScreen()),
                    ),
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Ver Calendario'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
                  _StatCard(
                    title: 'Hábitos',
                    value: '${stats?.activeHabits ?? 0}',
                    icon: Icons.trending_up,
                  ),
                  _StatCard(
                    title: 'Progreso hoy',
                    value: '${((stats?.dailyProgress ?? 0) * 100).round()}%',
                    icon: Icons.pie_chart,
                  ),
                  _StatCard(
                    title: 'Racha',
                    value: '${stats?.currentStreak ?? 0}',
                    icon: Icons.local_fire_department,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
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
            style: TextStyle(fontSize: 14, color: Colors.grey[300]),
          ),
        ],
      ),
    );
  }
}
