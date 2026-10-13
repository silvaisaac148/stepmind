import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/user_profile.dart';

class UserProfileService {
  static const String _profileKey = 'user_profile';
  static const String _updatedAtKey = 'user_profile_updated_at';
  static const String _dirtyKey = 'user_profile_dirty';
  
  Future<UserProfile?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString(_profileKey);
    
    if (profileJson == null) return null;
    
    try {
      final Map<String, dynamic> profileMap = json.decode(profileJson);
      return UserProfile.fromJson(profileMap);
    } catch (e) {
      debugPrint('Error al cargar perfil: $e');
      return null;
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = json.encode(profile.toJson());
    await prefs.setString(_profileKey, profileJson);
    await prefs.setInt(_updatedAtKey, DateTime.now().millisecondsSinceEpoch);
    await prefs.setBool(_dirtyKey, true);
    debugPrint('Perfil guardado exitosamente');
  }

  // --- Sincronización (la foto de perfil se queda solo en el teléfono) ---

  Future<int> profileUpdatedAt() async =>
      (await SharedPreferences.getInstance()).getInt(_updatedAtKey) ?? 0;

  Future<bool> isProfileDirty() async =>
      (await SharedPreferences.getInstance()).getBool(_dirtyKey) ?? true;

  Future<void> markProfileDirty() async =>
      (await SharedPreferences.getInstance()).setBool(_dirtyKey, true);

  /// Marca como subido, salvo que se haya vuelto a editar mientras tanto.
  Future<void> markProfileSynced(int updatedAt) async {
    final prefs = await SharedPreferences.getInstance();
    if ((prefs.getInt(_updatedAtKey) ?? 0) == updatedAt) await prefs.setBool(_dirtyKey, false);
  }

  /// Guarda el perfil bajado de la nube conservando la foto local.
  Future<void> applyRemoteProfile(UserProfile remote, int updatedAt) async {
    final local = await getProfile();
    final merged = UserProfile(
      firstName: remote.firstName,
      lastName: remote.lastName,
      username: remote.username,
      age: remote.age,
      country: remote.country,
      profileImagePath: local?.profileImagePath,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, json.encode(merged.toJson()));
    await prefs.setInt(_updatedAtKey, updatedAt);
    await prefs.setBool(_dirtyKey, false);
  }

  /// Copia la imagen elegida (que el sistema guarda en caché temporal) a la
  /// carpeta de documentos de la app, para que no desaparezca.
  Future<String> persistProfileImage(String sourcePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final extension = p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
    final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}$extension';
    final saved = await File(sourcePath).copy(p.join(directory.path, fileName));
    return saved.path;
  }

  Future<void> deleteProfileImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('Imagen de perfil eliminada: $imagePath');
      }
    } catch (e) {
      debugPrint('Error al eliminar imagen de perfil: $e');
    }
  }

  Future<bool> hasProfile() async {
    final profile = await getProfile();
    return profile != null;
  }

  Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
    await prefs.remove(_updatedAtKey);
    await prefs.remove(_dirtyKey);
    debugPrint('Perfil eliminado');
  }

  // Validación de datos del perfil
  String? validateFirstName(String value) {
    if (value.isEmpty) return 'El nombre es requerido';
    if (value.length < 2) return 'El nombre debe tener al menos 2 caracteres';
    if (value.length > 50) return 'El nombre no puede exceder 50 caracteres';
    return null;
  }

  String? validateLastName(String value) {
    if (value.isEmpty) return 'El apellido es requerido';
    if (value.length < 2) return 'El apellido debe tener al menos 2 caracteres';
    if (value.length > 50) return 'El apellido no puede exceder 50 caracteres';
    return null;
  }

  String? validateUsername(String value) {
    if (value.isEmpty) return 'El nombre de usuario es requerido';
    if (value.length < 3) return 'El nombre de usuario debe tener al menos 3 caracteres';
    if (value.length > 20) return 'El nombre de usuario no puede exceder 20 caracteres';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Solo se permiten letras, números y guiones bajos';
    }
    return null;
  }

  String? validateAge(String value) {
    if (value.isEmpty) return 'La edad es requerida';
    final age = int.tryParse(value);
    if (age == null) return 'Ingresa una edad válida';
    if (age < 13) return 'Debes tener al menos 13 años';
    if (age > 120) return 'Ingresa una edad válida';
    return null;
  }

  String? validateCountry(String value) {
    if (value.isEmpty) return 'El país es requerido';
    if (value.length < 2) return 'Ingresa un país válido';
    if (value.length > 50) return 'El nombre del país no puede exceder 50 caracteres';
    return null;
  }
}
