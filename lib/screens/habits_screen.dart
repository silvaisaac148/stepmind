import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/habit_service.dart';
import '../services/stats_service.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final HabitService _habitService = HabitService();
  final StatsService _statsService = StatsService();
  List<Habit> _habits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final habits = await _habitService.getHabits();
    setState(() {
      _habits = habits;
      _isLoading = false;
    });
  }

  Future<void> _toggleHabitCompletion(Habit habit) async {
    await _habitService.toggleHabitCompletion(habit.id);
    
    // Cargar hábitos actualizados ANTES de verificar
    final updatedHabits = await _habitService.getHabits();
    
    // Verificar si todos están completados con los datos actualizados
    final allCompleted = updatedHabits.isNotEmpty && 
        updatedHabits.every((h) => h.isCompletedToday);
    
    if (allCompleted) {
      await _statsService.updateDailyStats();
    }
    
    // Actualizar UI
    setState(() {
      _habits = updatedHabits;
    });
  }

  Future<void> _deleteHabit(String habitId) async {
    await _habitService.deleteHabit(habitId);
    await _loadHabits();
  }

  void _addHabit() {
    final nameController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF3A3634),
          title: const Text(
            'Nuevo Hábito',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del hábito',
                  filled: true,
                  fillColor: Color(0xFF4A4543),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text(
                  'Hora del recordatorio',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: const Icon(Icons.access_time, color: Colors.white),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (time != null) {
                    setState(() {
                      selectedTime = time;
                    });
                  }
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
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final newHabit = Habit(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    time: selectedTime,
                    createdAt: DateTime.now(),
                    completedDates: [],
                  );
                  await _habitService.addHabit(newHabit);
                  await _loadHabits(); // Recargar hábitos después de agregar
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hábitos y Tareas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addHabit,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3A3634),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryCard('Total', '${_habits.length}'),
                  _buildSummaryCard('Completados', '${_habits.where((h) => h.isCompletedToday).length}'),
                  _buildSummaryCard('Mejor Racha', '${_getBestStreak()} días'),
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
              child: _habits.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_alt,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tienes hábitos registrados',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Presiona el botón + para agregar tu primer hábito',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _habits.length,
                      itemBuilder: (context, index) {
                        final habit = _habits[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3A3634),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: habit.isCompletedToday ? Colors.green : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: habit.isCompletedToday,
                                onChanged: (value) => _toggleHabitCompletion(habit),
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
                                        decoration: habit.isCompletedToday
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          color: Colors.blue,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          habit.formattedTime,
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(
                                          Icons.local_fire_department,
                                          color: Colors.orange,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Racha: ${habit.currentStreak} días',
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: Colors.grey[400],
                                ),
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    _showDeleteConfirmation(habit);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Eliminar'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  int _getBestStreak() {
    if (_habits.isEmpty) return 0;
    return _habits.map((habit) => habit.currentStreak).reduce((a, b) => a > b ? a : b);
  }

  void _showDeleteConfirmation(Habit habit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3A3634),
        title: const Text(
          'Eliminar Hábito',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${habit.name}"?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteHabit(habit.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value) {
    return Column(
      children: [
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
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
