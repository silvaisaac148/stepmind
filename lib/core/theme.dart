import 'package:flutter/material.dart';

/// Paleta de StepMind, tomada del diseño de Figma ("Desarrollo StepMind").
class AppColors {
  // Base
  static const background = Color(0xFF3F3C3B);
  static const surface = Color(0xFF353231);
  static const surfaceHigh = Color(0xFF4A4645);

  // Azul petróleo (degradado de la marca y diálogos)
  static const petrol900 = Color(0xFF0F2027);
  static const petrol700 = Color(0xFF203A43);
  static const petrol500 = Color(0xFF2C5364);
  static const dialog = Color(0xFF072833);

  // Acentos
  static const orange = Color(0xFFFF620D);
  static const orangeDeep = Color(0xFF6D3615);
  static const yellow = Color(0xFFFFDE59);

  /// Calma (respiración, SOS). Añadido al diseño original.
  static const teal = Color(0xFF2EC4B6);
  static const coral = Color(0xFFE76F51);

  // Texto
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFFC9C4C2);
  static const textMuted = Color(0xFF9A9492);

  static const petrolGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [petrol900, petrol700, petrol500],
  );

  static const orangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8A3D), orange],
  );
}

class AppTheme {
  static const _font = 'Nunito';

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: AppColors.orange,
      onPrimary: Colors.white,
      secondary: AppColors.petrol500,
      onSecondary: Colors.white,
      tertiary: AppColors.teal,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceContainerHighest: AppColors.surfaceHigh,
      error: AppColors.coral,
      outline: AppColors.textMuted,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      fontFamily: _font,
      scaffoldBackgroundColor: AppColors.background,
    );

    final roundedShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: _font,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.orange),
        actionsIconTheme: IconThemeData(color: AppColors.orange),
      ),
      iconTheme: const IconThemeData(color: AppColors.orange),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontFamily: _font, fontWeight: FontWeight.w800, fontSize: 16),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.textMuted),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontFamily: _font, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.orange,
          textStyle: const TextStyle(fontFamily: _font, fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        shape: CircleBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.18),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIconColor: AppColors.textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.dialog,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        barrierColor: Colors.black.withValues(alpha: 0.6),
        titleTextStyle: const TextStyle(
          fontFamily: _font,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: _font,
          fontSize: 15,
          color: AppColors.textSecondary,
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.dialog,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: AppColors.dialog,
        headerForegroundColor: Colors.white,
        dayForegroundColor: const WidgetStatePropertyAll(Colors.white),
        todayForegroundColor: const WidgetStatePropertyAll(AppColors.orange),
        todayBorder: const BorderSide(color: AppColors.orange),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.dialog,
        dialHandColor: AppColors.orange,
        hourMinuteColor: AppColors.petrol700,
        hourMinuteTextColor: Colors.white,
        dayPeriodColor: AppColors.petrol500,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: roundedShape,
        elevation: 0,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.orange,
        textColor: AppColors.textPrimary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.white : AppColors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? AppColors.orange : AppColors.surfaceHigh,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.orange : null,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.orange),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.petrol700,
        contentTextStyle: const TextStyle(fontFamily: _font, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.orange.withValues(alpha: 0.18),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? AppColors.orange : AppColors.textMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: _font,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: states.contains(WidgetState.selected) ? AppColors.orange : AppColors.textMuted,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: Colors.white.withValues(alpha: 0.08)),
    );
  }
}
