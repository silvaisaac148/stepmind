import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/habit_stats.dart';
import '../models/habit.dart';
import '../providers/providers.dart';
import '../services/notification_service.dart';
import '../core/theme.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  Future<void> _run(BuildContext context, Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Algo salió mal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addHabit(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<_HabitFormResult>(
      context: context,
      builder: (context) => const _HabitFormDialog(),
    );
    if (result == null || !context.mounted) return;
    await _run(context, () => ref.read(habitsProvider.notifier).addHabit(result.name, result.time));
    if (context.mounted) await _ensureNotificationPermission(context);
  }

  /// Pide el permiso de notificaciones al crear un hábito (momento en que el
  /// usuario entiende para qué sirve), solo si tiene los recordatorios activos.
  Future<void> _ensureNotificationPermission(BuildContext context) async {
    final notifications = NotificationService();
    if (!await notifications.areNotificationsEnabled()) return;
    if (await notifications.requestPermission()) {
      if (context.mounted) await _offerExactReminders(context, notifications);
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Sin permiso de notificaciones no recibirás recordatorios. '
          'Puedes activarlo en los ajustes del sistema.',
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _offerExactReminders(
    BuildContext context,
    NotificationService notifications,
  ) async {
    if (!await notifications.takeExactRemindersOffer() || !context.mounted) return;
    final accept = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Recordatorios a la hora exacta',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Sin este permiso Android puede retrasar los recordatorios hasta una hora. '
          'En la siguiente pantalla activa "Permitir alarmas y recordatorios" para StepMind.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ahora no'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Activar'),
          ),
        ],
      ),
    );
    if (accept ?? false) await notifications.requestExactReminders();
  }

    Future<void> _editHabit(BuildContext context, WidgetRef ref, Habit habit) async {
    final result = await showDialog<_HabitFormResult>(
      context: context,
      builder: (context) => _HabitFormDialog(initial: habit),
    );
    if (result == null || !context.mounted) return;
    await _run(
      context,
      () => ref
          .read(habitsProvider.notifier)
          .updateHabit(habit.copyWith(name: result.name, time: result.time)),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Habit habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Hábito', style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${habit.name}"? '
          'Tu historial anterior se conservará en las estadísticas.',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _run(context, () => ref.read(habitsProvider.notifier).archiveHabit(habit.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);
    final today = ref.watch(todayProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hábitos y Tareas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nuevo hábito',
            onPressed: () => _addHabit(context, ref),
          ),
        ],
      ),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, _) => Center(
          child: Text('No se pudieron cargar los hábitos: $e',
              style: const TextStyle(color: Colors.white)),
        ),
        data: (data) {
          final habits = data.activeHabits;
          final completed = habits.where((h) => data.isDone(h.id, today)).length;
          final bestStreak = habits.isEmpty
              ? 0
              : habits
                  .map((h) => habitBestStreak(data.daysFor(h.id)))
                  .reduce((a, b) => a > b ? a : b);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _SummaryCard(title: 'Total', value: '${habits.length}'),
                      _SummaryCard(title: 'Completados', value: '$completed'),
                      _SummaryCard(title: 'Mejor Racha', value: '$bestStreak días'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Mis Hábitos',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: habits.isEmpty
                      ? const _EmptyHabits()
                      : ListView.builder(
                          itemCount: habits.length,
                          itemBuilder: (context, index) {
                            final habit = habits[index];
                            return _HabitTile(
                              habit: habit,
                              done: data.isDone(habit.id, today),
                              streak: habitStreak(data.daysFor(habit.id), today),
                              onToggle: () => _run(
                                context,
                                () => ref.read(habitsProvider.notifier).toggleToday(habit.id),
                              ),
                              onEdit: () => _editHabit(context, ref, habit),
                              onDelete: () => _confirmDelete(context, ref, habit),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HabitTile extends StatelessWidget {
  final Habit habit;
  final bool done;
  final int streak;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HabitTile({
    required this.habit,
    required this.done,
    required this.streak,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: done ? Colors.green : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: done,
            onChanged: (_) => onToggle(),
            activeColor: Colors.green,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.blue, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      habit.formattedTime,
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Racha: $streak ${streak == 1 ? 'día' : 'días'}',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.textMuted),
            onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Editar')),
              PopupMenuItem(value: 'delete', child: Text('Eliminar')),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyHabits extends StatelessWidget {
  const _EmptyHabits();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            'No tienes hábitos registrados',
            style: TextStyle(color: AppColors.textMuted, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Presiona el botón + para agregar tu primer hábito',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;

  const _SummaryCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(title, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ],
    );
  }
}

class _HabitFormResult {
  final String name;
  final TimeOfDay time;

  const _HabitFormResult(this.name, this.time);
}

/// Diálogo para crear o editar un hábito.
class _HabitFormDialog extends StatefulWidget {
  final Habit? initial;

  const _HabitFormDialog({this.initial});

  @override
  State<_HabitFormDialog> createState() => _HabitFormDialogState();
}

class _HabitFormDialogState extends State<_HabitFormDialog> {
  late final TextEditingController _nameController;
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _time = widget.initial?.time ?? TimeOfDay.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, _HabitFormResult(name, _time));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;
    return AlertDialog(
      title: Text(
        isEditing ? 'Editar Hábito' : 'Nuevo Hábito',
        style: const TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: !isEditing,
            maxLength: 60,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nombre del hábito',
              filled: true,
              fillColor: AppColors.surfaceHigh,
            ),
            style: const TextStyle(color: Colors.white),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Hora del recordatorio', style: TextStyle(color: Colors.white)),
            subtitle: Text(
              '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(color: AppColors.textMuted),
            ),
            trailing: const Icon(Icons.access_time, color: Colors.white),
            onTap: () async {
              final time = await showTimePicker(context: context, initialTime: _time);
              if (time != null) setState(() => _time = time);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Guardar' : 'Agregar'),
        ),
      ],
    );
  }
}
