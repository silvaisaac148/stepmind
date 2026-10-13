import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/dates.dart';
import '../domain/habit_stats.dart';
import '../models/calendar_event.dart';
import '../providers/providers.dart';
import '../widgets/month_calendar.dart';
import '../core/theme.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  /// Día que se muestra seleccionado al abrir (por defecto, hoy).
  final DateTime? initialDay;

  const CalendarScreen({super.key, this.initialDay});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _selectedDate;
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDay ?? ref.read(todayProvider);
    _focusedMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  Future<void> _addEvent() async {
    final title = await showDialog<String>(
      context: context,
      builder: (context) => _AddEventDialog(date: _selectedDate),
    );
    if (title == null || title.trim().isEmpty) return;
    await ref.read(eventsProvider.notifier).add(_selectedDate, title);
  }

  /// Selector emergente con el fondo oscurecido (efecto del Figma).
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      cancelText: 'CANCELAR',
      confirmText: 'ACEPTAR',
      helpText: 'Ir a una fecha',
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
      _focusedMonth = DateTime(picked.year, picked.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayProvider);
    final data = ref.watch(habitsProvider).value ?? HabitData.empty;
    final events = ref.watch(eventsProvider).value ?? const <CalendarEvent>[];
    final eventDays = events.map((e) => e.day).toSet();
    final selectedKey = dayKey(_selectedDate);
    final dayEvents = events.where((e) => e.day == selectedKey).toList();
    final dayHabits = data.habits.where((h) => h.isActiveOn(_selectedDate)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Agregar evento',
            onPressed: _addEvent,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() {
                  _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                }),
              ),
              TextButton.icon(
                onPressed: _pickDate,
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.expand_more_rounded),
                label: Text(
                  '${monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() {
                  _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                }),
              ),
            ],
          ),
          MonthCalendar(
            month: _focusedMonth,
            today: today,
            selected: _selectedDate,
            statusOf: (day) => dayStatus(data, day, today),
            hasEvents: (day) => eventDays.contains(dayKey(day)),
            onSelect: (day) => setState(() => _selectedDate = day),
          ),
          const SizedBox(height: 8),
          const _Legend(),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatDate(_selectedDate),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 12),
                if (dayHabits.isNotEmpty && !_selectedDate.isAfter(today)) ...[
                  const Text('Hábitos', style: TextStyle(color: AppColors.textMuted)),
                  for (final habit in dayHabits)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        data.isDone(habit.id, _selectedDate)
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: data.isDone(habit.id, _selectedDate)
                            ? AppColors.orange
                            : AppColors.textMuted,
                      ),
                      title: Text(habit.name, style: const TextStyle(color: Colors.white)),
                    ),
                  const SizedBox(height: 8),
                ],
                const Text('Eventos', style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 8),
                if (dayEvents.isEmpty)
                  Text('No hay eventos para este día', style: TextStyle(color: AppColors.textMuted))
                else
                  for (final event in dayEvents)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event, color: AppColors.teal, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(event.title, style: const TextStyle(color: Colors.white)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.coral, size: 20),
                            tooltip: 'Eliminar evento',
                            onPressed: () => ref.read(eventsProvider.notifier).delete(event.id),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(DayStatus status, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: MonthCalendar.statusColor(status),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        );

    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        item(DayStatus.perfect, 'Todos'),
        item(DayStatus.partial, 'Algunos'),
        item(DayStatus.missed, 'Ninguno'),
      ],
    );
  }
}

class _AddEventDialog extends StatefulWidget {
  final DateTime date;

  const _AddEventDialog({required this.date});

  @override
  State<_AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<_AddEventDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Agregar Evento - ${formatDate(widget.date)}',
        style: const TextStyle(color: Colors.white),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 100,
        decoration: const InputDecoration(
          labelText: 'Descripción del evento',
          filled: true,
          fillColor: AppColors.surfaceHigh,
        ),
        style: const TextStyle(color: Colors.white),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}
