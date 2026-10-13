import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/habit_stats.dart';
import '../providers/providers.dart';
import '../services/notification_service.dart';
import 'calendar_screen.dart';
import 'profile_setup_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final NotificationService _notificationService = NotificationService();

  bool _notificationsEnabled = true;

  List<String> get _notificationTimes =>
      (ref.read(habitsProvider).value?.activeHabits ?? const [])
          .map((habit) => habit.formattedTime)
          .toSet()
          .toList()
        ..sort();

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final enabled = await _notificationService.areNotificationsEnabled();
    if (!mounted) return;
    setState(() => _notificationsEnabled = enabled);
  }

  Future<void> _setNotificationsEnabled(bool value) async {
    if (value && !await _notificationService.requestPermission()) {
      _showPermissionDeniedSnackBar();
      return;
    }
    await _notificationService.setNotificationsEnabled(value);
    if (value) await ref.read(habitsProvider.notifier).syncReminders();
    if (!mounted) return;
    setState(() => _notificationsEnabled = value);
  }

  void _showPermissionDeniedSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Permiso de notificaciones denegado. Actívalo en los ajustes del sistema.',
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(statsProvider).value;
    final monthlyProgress = (stats?.monthlyProgress ?? 0) * 100;
    final activeHabits = ref.watch(habitsProvider).value?.activeHabits ?? const [];

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
            'Progresos y Estadísticas',
            [
              ListTile(
                leading: const Icon(Icons.trending_up, color: Colors.green),
                title: const Text(
                  'Progreso General',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Este mes: ${monthlyProgress.toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                onTap: () => _showProgressDialog(context, monthlyProgress),
              ),
              ListTile(
                leading: const Icon(Icons.emoji_events, color: Colors.orange),
                title: const Text(
                  'Logros',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Desbloqueados: ${stats?.unlockedAchievements ?? 0}/${achievements.length}',
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                onTap: () => _showAchievementsDialog(context, stats?.bestStreak ?? 0),
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
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const CalendarScreen()),
                ),
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
                onChanged: _setNotificationsEnabled,
              ),
              ListTile(
                leading: const Icon(Icons.alarm, color: Colors.green),
                title: const Text(
                  'Horarios de Recordatorios',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  activeHabits.isEmpty
                      ? 'No hay horarios configurados'
                      : '${activeHabits.length} recordatorios activos',
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
                onTap: () => _showAboutDialog(context),
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
                onTap: () => _showHelpDialog(context),
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

  void _showProgressDialog(BuildContext context, double monthlyProgress) {
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
                'Este mes has completado el ${monthlyProgress.toStringAsFixed(1)}% de tus hábitos',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: monthlyProgress / 100,
                backgroundColor: const Color(0xFF4A4543),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              const SizedBox(height: 16),
              Text(
                monthlyProgress >= 75
                    ? '¡Excelente trabajo! Sigue así.'
                    : monthlyProgress >= 50
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

  void _showAchievementsDialog(BuildContext context, int bestStreak) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3A3634),
        title: const Text(
          'Logros',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final achievement in achievements)
                  _buildAchievementItem(
                    achievement.title,
                    achievement.description,
                    bestStreak >= achievement.days,
                  ),
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

  void _showNotificationTimesDialog(BuildContext context) {
    final notificationTimes = _notificationTimes;
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
              if (notificationTimes.isEmpty)
                const Text(
                  'No hay hábitos configurados. Añade hábitos para ver sus horarios aquí.',
                  style: TextStyle(color: Colors.grey),
                )
              else
                ...notificationTimes.map((time) => Padding(
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
          if (_notificationsEnabled && notificationTimes.isNotEmpty)
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
      final habits = ref.read(habitsProvider).value?.activeHabits ?? const [];
      if (habits.isNotEmpty) {
        if (!await _notificationService.requestPermission()) {
          _showPermissionDeniedSnackBar();
          return;
        }
        await _notificationService.showTestNotification(habits.first.name);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Notificación de prueba enviada'),
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
    final userProfile = ref.watch(profileProvider).value;
    if (userProfile == null) {
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
            backgroundImage: userProfile.profileImagePath != null
                ? FileImage(File(userProfile.profileImagePath!))
                : null,
            child: userProfile.profileImagePath == null
                ? const Icon(Icons.person, color: Colors.grey)
                : null,
          ),
          title: Text(
            userProfile.fullName,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '@${userProfile.username}',
            style: const TextStyle(color: Colors.grey),
          ),
          trailing: const Icon(Icons.edit, color: Colors.blue),
          onTap: () => _navigateToProfileSetup(isEditing: true),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline, color: Colors.grey),
          title: Text(
            'Edad: ${userProfile.age}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.public, color: Colors.grey),
          title: Text(
            'País: ${userProfile.country}',
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
          existingProfile: isEditing ? ref.read(profileProvider).value : null,
        ),
      ),
    );
  }
}
