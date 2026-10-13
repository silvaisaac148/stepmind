import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/habit_stats.dart';
import '../providers/providers.dart';
import '../services/notification_service.dart';
import 'calendar_screen.dart';
import 'login_screen.dart';
import 'profile_setup_screen.dart';
import '../core/theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final NotificationService _notificationService = NotificationService();

  bool _notificationsEnabled = true;

  /// Permiso de alarmas exactas (solo Android; `null` mientras se consulta).
  bool? _exactRemindersAllowed;

  /// Al volver de los ajustes del sistema el permiso puede haber cambiado.
  late final AppLifecycleListener _lifecycle;

  List<String> get _notificationTimes =>
      (ref.read(habitsProvider).value?.activeHabits ?? const [])
          .map((habit) => habit.formattedTime)
          .toSet()
          .toList()
        ..sort();

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _loadNotificationSettings);
    _loadNotificationSettings();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _loadNotificationSettings() async {
    final enabled = await _notificationService.areNotificationsEnabled();
    final exact = Platform.isAndroid
        ? await _notificationService.canScheduleExactReminders()
        : null;
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = enabled;
      _exactRemindersAllowed = exact;
    });
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
        backgroundColor: AppColors.background,
      ),
      backgroundColor: AppColors.background,
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
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.textMuted),
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
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.textMuted),
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
                  style: TextStyle(color: AppColors.textMuted),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.textMuted),
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
                  style: TextStyle(color: AppColors.textMuted),
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
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.textMuted),
                onTap: () => _showNotificationTimesDialog(context),
              ),
              if (_notificationsEnabled && _exactRemindersAllowed != null)
                ListTile(
                  leading: Icon(
                    Icons.schedule,
                    color: _exactRemindersAllowed! ? Colors.green : Colors.orange,
                  ),
                  title: const Text(
                    'Recordatorios a la hora exacta',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    _exactRemindersAllowed!
                        ? 'Activado'
                        : 'Desactivado: pueden llegar con hasta 1 h de retraso. Toca para activarlo.',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  trailing: _exactRemindersAllowed!
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.arrow_forward_ios, color: AppColors.textMuted),
                  onTap: _exactRemindersAllowed!
                      ? null
                      : _notificationService.requestExactReminders,
                ),
              if (Platform.isAndroid)
                ListTile(
                  leading: const Icon(Icons.help_outline, color: Colors.amber),
                  title: const Text(
                    '¿No te llegan los recordatorios?',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Ajustes de batería según tu teléfono',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.textMuted),
                  onTap: () => _showReminderHelpDialog(context),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            'Cuenta',
            [
              ..._buildAccountTiles(),
              ListTile(
                leading: const Icon(Icons.privacy_tip, color: Colors.teal),
                title: const Text(
                  'Privacidad y Seguridad',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Protege tus datos personales',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.textMuted),
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
                  style: TextStyle(color: AppColors.textMuted),
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
                  style: TextStyle(color: AppColors.textMuted),
                ),
                onTap: () => _showHelpDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAccountTiles() {
    if (ref.watch(authServiceProvider) == null) return const [];
    final user = ref.watch(authUserProvider).value;
    if (user == null) {
      return [
        ListTile(
          leading: const Icon(Icons.cloud_outlined, color: Colors.lightBlue),
          title: const Text(
            'Iniciar sesión o crear cuenta',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: const Text(
            'Copia en la nube y usar StepMind en otro teléfono',
            style: TextStyle(color: AppColors.textMuted),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.textMuted),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const LoginScreen(fromSettings: true)),
          ),
        ),
      ];
    }

    final sync = ref.watch(syncProvider);
    final last = sync.lastSyncedAt;
    final status = sync.syncing
        ? 'Sincronizando…'
        : sync.error ??
            (last == null
                ? 'Pendiente de sincronizar'
                : 'Sincronizado a las ${TimeOfDay.fromDateTime(last).format(context)}');
    return [
      ListTile(
        leading: const Icon(Icons.cloud_done, color: Colors.lightBlue),
        title: Text(user.email ?? 'Cuenta', style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          status,
          style: TextStyle(color: sync.error != null ? Colors.orange : AppColors.textMuted),
        ),
        trailing: sync.syncing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                icon: const Icon(Icons.sync, color: AppColors.textMuted),
                tooltip: 'Sincronizar ahora',
                onPressed: () => ref.read(syncProvider.notifier).syncNow(),
              ),
      ),
      ListTile(
        leading: const Icon(Icons.logout, color: Colors.redAccent),
        title: const Text('Cerrar sesión', style: TextStyle(color: Colors.white)),
        onTap: _confirmSignOut,
      ),
    ];
  }

  Future<void> _confirmSignOut() async {
    final wipe = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Tus datos quedan guardados en la nube. ¿Quieres conservarlos también en '
          'este teléfono o borrarlos de él?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar del teléfono', style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Conservar'),
          ),
        ],
      ),
    );
    if (wipe == null) return;
    try {
      await ref.read(syncProvider.notifier).signOut(wipeLocalData: wipe);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cerrar sesión. $e'), backgroundColor: Colors.red),
      );
    }
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
            color: AppColors.surface,
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
                backgroundColor: AppColors.surfaceHigh,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              const SizedBox(height: 16),
              Text(
                monthlyProgress >= 75
                    ? '¡Excelente trabajo! Sigue así.'
                    : monthlyProgress >= 50
                        ? '¡Buen progreso! Puedes mejorar.'
                        : '¡Sigue esforzándote! Tú puedes.',
                style: const TextStyle(color: AppColors.textSecondary),
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
            color: unlocked ? AppColors.yellow : AppColors.textMuted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: unlocked ? Colors.white : AppColors.textMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: unlocked ? AppColors.textSecondary : AppColors.textMuted,
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
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              if (notificationTimes.isEmpty)
                const Text(
                  'No hay hábitos configurados. Añade hábitos para ver sus horarios aquí.',
                  style: TextStyle(color: AppColors.textMuted),
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
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
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

  void _showReminderHelpDialog(BuildContext context) {
    const tips = [
      ('Todos', 'Ajustes → Aplicaciones → StepMind → Notificaciones: actívalas.'),
      ('Todos', 'Ajustes → Aplicaciones → StepMind → Batería: elige "Sin restricciones".'),
      ('Honor / Huawei', 'Ajustes → Batería → Inicio de aplicaciones → StepMind: '
          'desactiva "Gestionar automáticamente" y permite ejecutar en segundo plano.'),
      ('Xiaomi / Redmi / POCO', 'Ajustes → Aplicaciones → StepMind: activa "Inicio automático" '
          'y en Ahorro de batería elige "Sin restricciones".'),
      ('Samsung', 'Ajustes → Batería → Límites de uso en segundo plano: '
          'quita StepMind de "Aplicaciones en suspensión".'),
      ('Oppo / Realme / OnePlus', 'Ajustes → Batería → StepMind: '
          'permite actividad en segundo plano e inicio automático.'),
    ];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '¿No te llegan los recordatorios?',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Algunos teléfonos cierran las apps en segundo plano para ahorrar '
                'batería y eso bloquea los recordatorios. Revisa estos ajustes:',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              for (final (brand, tip) in tips) ...[
                const SizedBox(height: 12),
                Text(
                  brand,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(tip, style: const TextStyle(color: AppColors.textMuted)),
              ],
              const SizedBox(height: 12),
              const Text(
                'Los nombres de los menús pueden variar según la versión del sistema.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
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
              style: TextStyle(color: AppColors.textSecondary),
            ),
            SizedBox(height: 8),
            Text(
              '© 2026 StepMind. Todos los derechos reservados.',
              style: TextStyle(color: AppColors.textSecondary),
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
              style: TextStyle(color: AppColors.textMuted),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.textMuted),
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
            backgroundColor: AppColors.surfaceHigh,
            backgroundImage: userProfile.profileImagePath != null
                ? FileImage(File(userProfile.profileImagePath!))
                : null,
            child: userProfile.profileImagePath == null
                ? const Icon(Icons.person, color: AppColors.textMuted)
                : null,
          ),
          title: Text(
            userProfile.fullName,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '@${userProfile.username}',
            style: const TextStyle(color: AppColors.textMuted),
          ),
          trailing: const Icon(Icons.edit, color: Colors.blue),
          onTap: () => _navigateToProfileSetup(isEditing: true),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline, color: AppColors.textMuted),
          title: Text(
            'Edad: ${userProfile.age}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.public, color: AppColors.textMuted),
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
