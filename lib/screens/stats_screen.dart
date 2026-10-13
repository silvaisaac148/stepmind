import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/dates.dart';
import '../domain/habit_stats.dart';
import '../providers/providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);
    final data = ref.watch(habitsProvider).value ?? HabitData.empty;
    final today = ref.watch(todayProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas y Progresos')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => Center(
          child: Text('No se pudieron calcular las estadísticas: $e',
              style: const TextStyle(color: Colors.white)),
        ),
        data: (stats) => ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text(
              'Tu Progreso',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            _ProgressCard(
              title: 'Hábitos Completados',
              value: '${(stats.dailyProgress * 100).round()}%',
              description:
                  'Has completado ${stats.completedToday} de ${stats.activeHabits} hábitos hoy',
              icon: Icons.trending_up,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            _ProgressCard(
              title: 'Racha Actual',
              value: '${stats.currentStreak} días',
              description: stats.bestStreak > 0
                  ? 'Tu mejor racha es de ${stats.bestStreak} días'
                  : 'Completa todos tus hábitos para empezar una racha',
              icon: Icons.local_fire_department,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            _ProgressCard(
              title: 'Logros Desbloqueados',
              value: '${stats.unlockedAchievements}/${achievements.length}',
              description: stats.unlockedAchievements > 0
                  ? '¡Sigue así! Sigue desbloqueando más logros'
                  : 'Completa hábitos para desbloquear logros',
              icon: Icons.emoji_events,
              color: Colors.purple,
            ),
            const SizedBox(height: 16),
            _RecentActivity(data: data, today: today),
          ],
        ),
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  final HabitData data;
  final DateTime today;

  const _RecentActivity({required this.data, required this.today});

  static const _weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  @override
  Widget build(BuildContext context) {
    final days = [for (var i = 6; i >= 0; i--) addDays(today, -i)];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF3A3634),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Últimos 7 días',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          if (data.habits.isEmpty)
            Text(
              'Agrega tu primer hábito para comenzar',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final day in days)
                  Column(
                    children: [
                      Text(
                        _weekdays[day.weekday - 1],
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      _DayDot(ratio: completionRatio(data, day)),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  final double? ratio;

  const _DayDot({required this.ratio});

  @override
  Widget build(BuildContext context) {
    final r = ratio;
    final color = r == null
        ? const Color(0xFF4A4543)
        : Color.lerp(Colors.red[700], Colors.green[600], r)!;
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        r == null ? '–' : '${(r * 100).round()}',
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final String title;
  final String value;
  final String description;
  final IconData icon;
  final Color color;

  const _ProgressCard({
    required this.title,
    required this.value,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF3A3634),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
              ],
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
