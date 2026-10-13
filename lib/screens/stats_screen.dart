import 'package:flutter/material.dart';
import '../services/stats_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final StatsService _statsService = StatsService();
  Map<String, dynamic> _stats = {
    'habits': 0, 
    'days': 0, 
    'achievements': 0,
    'dailyProgress': 0.0,
    'currentStreak': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _statsService.getStats();
    setState(() {
      _stats = stats;
      _isLoading = false;
    });
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
        title: const Text('Estadísticas y Progresos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu Progreso',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildProgressCard(
                    context,
                    'Hábitos Completados',
                    '${_stats['dailyProgress'].toStringAsFixed(0)}%',
                    'Has completado ${_stats['habits'] > 0 ? ((_stats['dailyProgress'] / 100 * _stats['habits']).round()).toString() : '0'} de ${_stats['habits'].toString()} hábitos hoy',
                    Icons.trending_up,
                    Colors.green,
                  ),
                  const SizedBox(height: 16),
                  _buildProgressCard(
                    context,
                    'Racha Actual',
                    '${_stats['currentStreak']} días',
                    _stats['currentStreak'] > 0 
                        ? '¡Sigue así! Tu mejor racha es de ${_stats['currentStreak']} días' 
                        : 'Completa todos tus hábitos para empezar una racha',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  _buildProgressCard(
                    context,
                    'Logros Desbloqueados',
                    '${_stats['achievements']}',
                    _stats['achievements'] > 0 
                        ? '¡Sigue así! Sigue desbloqueando más logros' 
                        : 'Completa hábitos para desbloquear logros',
                    Icons.emoji_events,
                    Colors.purple,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3634),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Actividad Reciente',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_stats['habits'] == 0) ...[
                          _buildEmptyActivityItem('No hay actividad reciente'),
                          _buildEmptyActivityItem('Agrega tu primer hábito para comenzar'),
                        ] else ...[
                          _buildEmptyActivityItem('Completa tus hábitos para ver actividad'),
                          _buildEmptyActivityItem('Tu actividad aparecerá aquí'),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyActivityItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.grey[400],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(
    BuildContext context,
    String title,
    String value,
    String description,
    IconData icon,
    Color color,
  ) {
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
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
