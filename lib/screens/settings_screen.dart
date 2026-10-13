import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/habit_service.dart';
import '../services/notification_service.dart';
import '../services/stats_service.dart';
import '../services/user_profile_service.dart';
import '../screens/profile_setup_screen.dart';
import 'dart:io';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final HabitService _habitService = HabitService();
  final NotificationService _notificationService = NotificationService();
  final StatsService _statsService = StatsService();
  final UserProfileService _userProfileService = UserProfileService();
  
  bool _notificationsEnabled = true;
  List<String> _notificationTimes = [];
  Map<String, dynamic> _stats = {};
  double _monthlyProgress = 0.0;
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
    _loadStats();
    _loadUserProfile();
  }

  Future<void> _loadNotificationSettings() async {
    final enabled = await _notificationService.areNotificationsEnabled();
    final habits = await _habitService.getHabits();
    final times = habits.map((habit) => habit.formattedTime).toList();
    
    setState(() {
      _notificationsEnabled = enabled;
      _notificationTimes = times;
    });
  }

  Future<void> _loadStats() async {
    final stats = await _statsService.getStats();
    final monthlyProgress = await _statsService.getMonthlyProgress();
    
    setState(() {
      _stats = stats;
      _monthlyProgress = monthlyProgress;
    });
  }

  Future<void> _loadUserProfile() async {
    final profile = await _userProfileService.getProfile();
    setState(() {
      _userProfile = profile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        backgroundColor: const Color(0xFF282524),
      ),
      backgroundColor: const Color(0xFF282524),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileSection(),
          const SizedBox(height: 20),
          _buildSection(
            'Apariencia',
            [
              ListTile(
                leading: const Icon(Icons.palette, color: Colors.blue),
                title: const Text(
                  'Tema',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Personaliza la apariencia',
                  style: TextStyle(color: Colors.grey),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                onTap: () {
                  // Implementar selector de tema
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            'Progresos y Estadísticas',
            [
              ListTile(
                leading: const Icon(Icons.trending_up, color: Colors.green),
                title: const Text(
                  'Progreso General',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Este mes: ${_monthlyProgress.toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                onTap: () => _showProgressDialog(context),
              ),
              ListTile(
                leading: const Icon(Icons.emoji_events, color: Colors.orange),
                title: const Text(
                  'Logros',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Desbloqueados: ${_stats['achievements'] ?? 0}',
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                onTap: () => _showAchievementsDialog(context),
              ),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.purple),
                title: const Text(
                  'Historial de Actividad',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Ver tu historial completo',
                  style: TextStyle(color: Colors.grey),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                onTap: () => _showHistoryDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            'Notificaciones',
            [
              SwitchListTile(
                secondary: const Icon(Icons.notifications, color: Colors.blue),
                title: const Text(
                  'Habilitar Notificaciones',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Recibe recordatorios de hábitos',
                  style: TextStyle(color: Colors.grey),
                ),
                value: _notificationsEnabled,
                onChanged: (value) async {
                  await _notificationService.setNotificationsEnabled(value);
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.alarm, color: Colors.green),
                title: const Text(
                  'Horarios de Recordatorios',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  _notificationTimes.isEmpty 
                    ? 'No hay horarios configurados'
                    : '${_notificationTimes.length} horarios activos',
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                onTap: () => _showNotificationTimesDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            'Cuenta',
            [
              ListTile(
                leading: const Icon(Icons.person, color: Colors.blue),
                title: const Text(
                  'Perfil de Usuario',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Gestiona tu información personal',
                  style: TextStyle(color: Colors.grey),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                onTap: () => _showProfileDialog(context),
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip, color: Colors.teal),
                title: const Text(
                  'Privacidad y Seguridad',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Protege tus datos personales',
                  style: TextStyle(color: Colors.grey),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                onTap: () => _showPrivacyDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            'Información',
            [
              ListTile(
                leading: const Icon(Icons.info, color: Colors.cyan),
                title: const Text(
                  'Acerca de StepMind',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Versión 1.0.0',
                  style: TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  _showAboutDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.help, color: Colors.teal),
                title: const Text(
                  'Ayuda y Soporte',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Obtener ayuda con la aplicación',
                  style: TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  _showHelpDialog(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF3A3634),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  void _showProgressDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3A3634),
        title: const Text(
          'Progreso General',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Este mes has completado el ${_monthlyProgress.toStringAsFixed(1)}% de tus hábitos',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _monthlyProgress / 100,
                backgroundColor: const Color(0xFF4A4543),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              const SizedBox(height: 16),
              Text(
                _monthlyProgress >= 75 
                  ? '¡Excelente trabajo! Sigue así.'
                  : _monthlyProgress >= 50 
                    ? '¡Buen progreso! Puedes mejorar.'
                    : '¡Sigue esforzándote! Tú puedes.',
                style: const TextStyle(color: Color(0xFFBDBDBD)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showAchievementsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3A3634),
        title: const Text(
          'Logros Desbloqueados',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAchievementItem('🌟 Primer Día', 'Completar todos los hábitos durante un día', _stats['achievements'] >= 1),
                _buildAchievementItem('🔥 Semana Perfecta', 'Mantener racha de 7 días', _stats['achievements'] >= 2),
                _buildAchievementItem('⭐ Doble Semana', 'Mantener racha de 14 días', _stats['achievements'] >= 3),
                _buildAchievementItem('🏆 Mes Completo', 'Mantener racha de 30 días', _stats['achievements'] >= 4),
                _buildAchievementItem('💎 Trimestre Maestro', 'Mantener racha de 90 días', _stats['achievements'] >= 5),
                _buildAchievementItem('🎯 Semestre Leyenda', 'Mantener racha de 180 días', _stats['achievements'] >= 6),
                _buildAchievementItem('👑 Año de Éxito', 'Mantener racha de 365 días', _stats['achievements'] >= 7),
                _buildAchievementItem('⚡ Doble Año', 'Mantener racha de 730 días', _stats['achievements'] >= 8),
                _buildAchievementItem('🏅 Quinquenio', 'Mantener racha de 5 años', _stats['achievements'] >= 9),
                _buildAchievementItem('👑🏆 Década Perfecta', 'Mantener racha de 10 años', _stats['achievements'] >= 10),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(String title, String description, bool unlocked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            unlocked ? Icons.emoji_events : Icons.lock,
            color: unlocked ? const Color(0xFFFFD700) : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: unlocked ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: unlocked ? Colors.grey[300] : Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3A3634),
        title: const Text(
          'Historial de Actividad',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 350,
          height: 450,
          child: _buildCalendar(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;
    final daysInMonth = DateTime(currentYear, currentMonth + 1, 0).day;
    
    return FutureBuilder(
      future: _habitService.getHabits(),
      builder: (context, snapshot) {
        return Column(
          children: [
            // Header del calendario
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4A4543),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: () {
                      // Navegación al mes anterior (implementar después)
                    },
                  ),
                  Text(
                    '${_getMonthName(currentMonth)} $currentYear',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: () {
                      // Navegación al mes siguiente (implementar después)
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Días de la semana
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['D', 'L', 'M', 'M', 'J', 'V', 'S'].map((day) => 
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ).toList(),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Calendario
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1.0,
                ),
                itemCount: daysInMonth,
                itemBuilder: (context, index) {
                  final day = index + 1;
                  final dayDate = DateTime(currentYear, currentMonth, day);
                  final isToday = dayDate.day == now.day && 
                               dayDate.month == now.month && 
                               dayDate.year == now.year;
                  
                  return FutureBuilder<String>(
                    future: _getDayStatus(dayDate),
                    builder: (context, statusSnapshot) {
                      final dayStatus = statusSnapshot.data ?? 'neutral';
                      
                      return Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: _getDayColor(dayStatus, isToday),
                          borderRadius: BorderRadius.circular(8),
                          border: isToday ? Border.all(color: Colors.blue, width: 2) : null,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$day',
                                style: TextStyle(
                                  color: _getDayTextColor(dayStatus, isToday),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getDayEmoji(dayStatus),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month - 1];
  }

  Future<String> _getDayStatus(DateTime dayDate) async {
    final now = DateTime.now();
    
    if (dayDate.isAfter(DateTime(now.year, now.month, now.day))) {
      return 'future';
    }
    
    if (dayDate.isBefore(DateTime(now.year, now.month, now.day))) {
      return 'neutral';
    }
    
    return 'today';
  }

  Color _getDayColor(String status, bool isToday) {
    switch (status) {
      case 'good':
        return Colors.green[700] ?? Colors.green;
      case 'bad':
        return Colors.red[700] ?? Colors.red;
      case 'today':
        return Colors.blue[700] ?? Colors.blue;
      default:
        return const Color(0xFF4A4543);
    }
  }

  Color _getDayTextColor(String status, bool isToday) {
    switch (status) {
      case 'good':
      case 'bad':
      case 'today':
        return Colors.white;
      default:
        return Colors.grey[400] ?? Colors.grey;
    }
  }

  String _getDayEmoji(String status) {
    switch (status) {
      case 'good':
        return '😊';
      case 'bad':
        return '😔';
      case 'today':
        return '📅';
      default:
        return '';
    }
  }

  void _showNotificationTimesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3A3634),
        title: const Text(
          'Horarios de Recordatorios',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Estos son los horarios configurados según tus hábitos:',
                style: TextStyle(color: Color(0xFFBDBDBD)),
              ),
              const SizedBox(height: 16),
              if (_notificationTimes.isEmpty)
                const Text(
                  'No hay hábitos configurados. Añade hábitos para ver sus horarios aquí.',
                  style: TextStyle(color: Colors.grey),
                )
              else
                ..._notificationTimes.map((time) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.alarm, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        time,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                )),
              const SizedBox(height: 16),
              const Text(
                'Las notificaciones se envían automáticamente según los horarios de tus hábitos.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          if (_notificationsEnabled && _notificationTimes.isNotEmpty)
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _testNotification();
              },
              child: const Text('Probar Notificación'),
            ),
        ],
      ),
    );
  }

  Future<void> _testNotification() async {
    try {
      final habits = await _habitService.getHabits();
      if (habits.isNotEmpty) {
        final notificationService = NotificationService();
        await notificationService.scheduleImmediateNotification(habits.first);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Notificación de prueba enviada para ${habits.first.name}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay hábitos configurados para probar notificaciones'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3A3634),
        title: const Text(
          'Perfil de Usuario',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Función de perfil próximamente disponible...',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3A3634),
        title: const Text(
          'Privacidad y Seguridad',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Tus datos están seguros y solo se usan para mejorar tu experiencia en StepMind.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3A3634),
        title: const Text(
          'Acerca de StepMind',
          style: TextStyle(color: Colors.white),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'StepMind v1.0.0',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Tu compañero para desarrollar hábitos positivos y superar adicciones.',
              style: TextStyle(color: Color(0xFFBDBDBD)),
            ),
            SizedBox(height: 8),
            Text(
              '© 2026 StepMind. Todos los derechos reservados.',
              style: TextStyle(color: Color(0xFFBDBDBD)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3A3634),
        title: const Text(
          'Ayuda y Soporte',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Para ayuda o soporte, contacta a: support@stepmind.com',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    if (_userProfile == null) {
      return _buildSection(
        'Perfil de Usuario',
        [
          ListTile(
            leading: const Icon(Icons.person_add, color: Colors.blue),
            title: const Text(
              'Configurar Perfil',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Agrega tu información personal',
              style: TextStyle(color: Colors.grey),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            onTap: () => _navigateToProfileSetup(isEditing: false),
          ),
        ],
      );
    }

    return _buildSection(
      'Perfil de Usuario',
      [
        ListTile(
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF4A4543),
            backgroundImage: _userProfile?.profileImagePath != null
                ? FileImage(File(_userProfile!.profileImagePath!))
                : null,
            child: _userProfile?.profileImagePath == null
                ? const Icon(Icons.person, color: Colors.grey)
                : null,
          ),
          title: Text(
            _userProfile?.fullName ?? 'Usuario',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '@${_userProfile?.username ?? ''}',
            style: const TextStyle(color: Colors.grey),
          ),
          trailing: const Icon(Icons.edit, color: Colors.blue),
          onTap: () => _navigateToProfileSetup(isEditing: true),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline, color: Colors.grey),
          title: Text(
            'Edad: ${_userProfile?.age ?? 'No especificada'}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.public, color: Colors.grey),
          title: Text(
            'País: ${_userProfile?.country ?? 'No especificado'}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _navigateToProfileSetup({required bool isEditing}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileSetupScreen(
          existingProfile: isEditing ? _userProfile : null,
          onProfileSaved: (profile) {
            setState(() {
              _userProfile = profile;
            });
          },
        ),
      ),
    );
  }
}
