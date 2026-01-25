import 'package:flutter/material.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();

  final Map<DateTime, List<String>> _events = {
    DateTime(2026, 1, 11): ['Ejercicio matutino', 'Meditación'],
    DateTime(2026, 1, 10): ['Leer 30 min', 'Beber agua'],
    DateTime(2026, 1, 9): ['Ejercicio', 'Tarea completada'],
    DateTime(2026, 1, 8): ['Meditación', 'Caminar'],
    DateTime(2026, 1, 7): ['Hábito nuevo iniciado'],
  };

  List<String> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _addEvent() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3A3634),
        title: Text(
          'Agregar Evento - ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Descripción del evento',
            filled: true,
            fillColor: Color(0xFF4A4543),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  final dateKey = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
                  if (_events[dateKey] == null) {
                    _events[dateKey] = [];
                  }
                  _events[dateKey]!.add(controller.text);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendario - ${_focusedDate.month}/${_focusedDate.year}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addEvent,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCalendarHeader(),
          _buildCalendarDays(),
          _buildCalendarGrid(),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3A3634),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Eventos del ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _getEventsForDay(_selectedDate).isEmpty
                        ? Center(
                            child: Text(
                              'No hay eventos para este día',
                              style: TextStyle(
                                color: Colors.grey[400],
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _getEventsForDay(_selectedDate).length,
                            itemBuilder: (context, index) {
                              final event = _getEventsForDay(_selectedDate)[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4A4543),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.event,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        event,
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: () {
                                        setState(() {
                                          final dateKey = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
                                          _events[dateKey]?.remove(event);
                                        });
                                      },
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
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
              });
            },
          ),
          Text(
            '${_getMonthName(_focusedDate.month)} ${_focusedDate.year}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDays() {
    const days = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days.map((day) {
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(_focusedDate.year, _focusedDate.month + 1, 0).day;
    final firstDayOfWeek = DateTime(_focusedDate.year, _focusedDate.month, 1).weekday % 7;

    return Container(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1,
        ),
        itemCount: daysInMonth + firstDayOfWeek,
        itemBuilder: (context, index) {
          if (index < firstDayOfWeek) {
            return const SizedBox();
          }

          final day = index - firstDayOfWeek + 1;
          final currentDate = DateTime(_focusedDate.year, _focusedDate.month, day);
          final isSelected = _selectedDate.year == currentDate.year &&
                           _selectedDate.month == currentDate.month &&
                           _selectedDate.day == currentDate.day;
          final hasEvents = _getEventsForDay(currentDate).isNotEmpty;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = currentDate;
              });
            },
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF4A4543)
                    : hasEvents
                        ? const Color(0xFF3A3634)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : hasEvents
                                ? Colors.blue
                                : Colors.grey[300],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (hasEvents)
                    Positioned(
                      bottom: 2,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month - 1];
  }
}
