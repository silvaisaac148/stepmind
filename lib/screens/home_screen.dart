import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/dates.dart';
import '../domain/habit_stats.dart';
import '../providers/providers.dart';
import '../services/notification_service.dart';
import 'calendar_screen.dart';
import 'habits_screen.dart';
import 'recovery/recovery_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import '../core/theme.dart';
import '../widgets/brand.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

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
        ref.read(syncProvider.notifier).schedule();
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
          _HomeTab(onOpenHabits: () => setState(() => _currentIndex = _habitsTab)),
          const StatsScreen(),
          const HabitsScreen(),
          const RecoveryScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Progreso',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_task_outlined),
            selectedIcon: Icon(Icons.add_task),
            label: 'Hábitos',
          ),
          NavigationDestination(
            icon: Icon(Icons.self_improvement_outlined),
            selectedIcon: Icon(Icons.self_improvement),
            label: 'Adicciones',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends ConsumerWidget {
  final VoidCallback onOpenHabits;

  const _HomeTab({required this.onOpenHabits});

  static const _messages = [
    ('Cada paso hacia adelante', 'es uno menos para el éxito anhelado.\n¡Empieza hoy a luchar por tus metas!'),
    ('No tienes que ser perfecto', 'solo constante. Un mal día no borra tu progreso.'),
    ('La disciplina es elegir', 'entre lo que quieres ahora y lo que más quieres.'),
    ('Los hábitos tardan unos 66 días', 'en volverse automáticos. Sigue sumando días.'),
    ('Una urgencia es como una ola', 'sube, llega a su punto más alto y baja. Puedes surfearla.'),
    ('Hoy cuenta', 'aunque sea un paso pequeño.'),
    ('Recuerda tu porqué', 'es más fuerte que cualquier impulso del momento.'),
  ];

  void _openCalendar(BuildContext context, [DateTime? day]) => Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => CalendarScreen(initialDay: day)),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    final stats = ref.watch(statsProvider).value;
    final data = ref.watch(habitsProvider).value ?? HabitData.empty;
    final today = ref.watch(todayProvider);
    final firstName = profile?.firstName ?? '';
    final email = ref.watch(authUserProvider).value?.email;
    final name = firstName.isNotEmpty ? firstName : email?.split('@').first;
    final message = _messages[today.difference(DateTime(2026)).inDays.abs() % _messages.length];
    final streak = stats?.currentStreak ?? 0;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.calendar_month_rounded, size: 30),
                tooltip: 'Calendario',
                onPressed: () => _openCalendar(context),
              ),
              _StreakChip(streak: streak),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.settings_rounded, size: 28),
                tooltip: 'Ajustes',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            name == null ? '¡Hola!' : '¡Hola, $name!',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openCalendar(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '${monthNames[today.month - 1]} ${today.year}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _WeekStrip(
            today: today,
            statusOf: (day) => dayStatus(data, day, today),
            onTap: (day) => _openCalendar(context, day),
          ),
          const SizedBox(height: 24),
          _TodayCard(stats: stats, onOpenHabits: onOpenHabits),
          const SizedBox(height: 32),
          Text(
            message.$1,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            message.$2,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  final int streak;

  const _StreakChip({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Racha de $streak días',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.orange.withValues(alpha: streak > 0 ? 0.18 : 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              color: streak > 0 ? AppColors.orange : AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(width: 2),
            Text(
              '$streak',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: streak > 0 ? AppColors.orange : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tira de 7 días con hoy en el centro (diseño de Figma).
class _WeekStrip extends StatelessWidget {
  final DateTime today;
  final DayStatus Function(DateTime day) statusOf;
  final ValueChanged<DateTime> onTap;

  const _WeekStrip({required this.today, required this.statusOf, required this.onTap});

  static const _names = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];

  static Color _circleColor(DayStatus status) => switch (status) {
        DayStatus.perfect => AppColors.orange,
        DayStatus.partial => AppColors.orangeDeep,
        DayStatus.missed => AppColors.surfaceHigh,
        DayStatus.pending => AppColors.petrol700,
        DayStatus.empty || DayStatus.future => AppColors.surface,
      };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var offset = -3; offset <= 3; offset++)
          Builder(builder: (context) {
            final day = addDays(today, offset);
            final isToday = offset == 0;
            final status = statusOf(day);
            return Semantics(
              button: true,
              label: '${_names[day.weekday - 1]} ${day.day}${isToday ? ', hoy' : ''}',
              child: GestureDetector(
                onTap: () => onTap(day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 44,
                  padding: const EdgeInsets.only(top: 6, bottom: 4),
                  decoration: BoxDecoration(
                    gradient: isToday ? AppColors.orangeGradient : null,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _names[day.weekday - 1],
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: isToday ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isToday ? Colors.white : _circleColor(status),
                        ),
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: isToday ? AppColors.orange : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _TodayCard extends StatelessWidget {
  final OverallStats? stats;
  final VoidCallback onOpenHabits;

  const _TodayCard({required this.stats, required this.onOpenHabits});

  @override
  Widget build(BuildContext context) {
    final total = stats?.activeHabits ?? 0;
    final done = stats?.completedToday ?? 0;
    final progress = stats?.dailyProgress ?? 0;
    final allDone = total > 0 && done == total;

    return GradientCard(
      onTap: onOpenHabits,
      child: Row(
        children: [
          ProgressRing(
            value: progress,
            semanticsLabel: 'Hábitos completados hoy',
            color: allDone ? AppColors.yellow : AppColors.orange,
            center: Text(
              '$done/$total',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  total == 0
                      ? 'Crea tu primer hábito'
                      : allDone
                          ? '¡Día completo! 🎉'
                          : 'Hábitos de hoy',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  total == 0
                      ? 'Empieza con uno pequeño y fácil de cumplir.'
                      : allDone
                          ? 'Mejor racha: ${stats?.bestStreak ?? 0} días'
                          : 'Te faltan ${total - done}. ¡Tú puedes!',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Text(
                      'Ver hábitos',
                      style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w800),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppColors.orange),
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
