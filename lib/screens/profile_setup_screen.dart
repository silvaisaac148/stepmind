import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  final UserProfile? existingProfile;
  final Function(UserProfile) onProfileSaved;

  const ProfileSetupScreen({
    super.key,
    this.existingProfile,
    required this.onProfileSaved,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userProfileService = UserProfileService();
  
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _usernameController;
  late TextEditingController _ageController;
  late TextEditingController _countryController;
  
  String? _profileImagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Inicializar controladores con datos existentes si hay
    _firstNameController = TextEditingController(
      text: widget.existingProfile?.firstName ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.existingProfile?.lastName ?? '',
    );
    _usernameController = TextEditingController(
      text: widget.existingProfile?.username ?? '',
    );
    _ageController = TextEditingController(
      text: widget.existingProfile?.age.toString() ?? '',
    );
    _countryController = TextEditingController(
      text: widget.existingProfile?.country ?? '',
    );
    
    _profileImagePath = widget.existingProfile?.profileImagePath;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _ageController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _profileImagePath = image.path;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error al seleccionar imagen: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _profileImagePath = photo.path;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error al tomar foto: $e');
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF3A3634),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Seleccionar foto de perfil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ImagePickerOption(
                  icon: Icons.camera_alt,
                  label: 'Cámara',
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                ),
                _ImagePickerOption(
                  icon: Icons.photo_library,
                  label: 'Galería',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Solo usar la imagen seleccionada, no pedir nueva
      final savedImagePath = _profileImagePath;

      final profile = UserProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        username: _usernameController.text.trim(),
        age: int.parse(_ageController.text),
        country: _countryController.text.trim(),
        profileImagePath: savedImagePath,
      );

      await _userProfileService.saveProfile(profile);
      
      if (mounted) {
        widget.onProfileSaved(profile);
        Navigator.pop(context);
        _showSuccessSnackBar('Perfil guardado exitosamente');
      }
    } catch (e) {
      _showErrorSnackBar('Error al guardar perfil: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF282524),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3A3634),
        title: Text(
          widget.existingProfile == null ? 'Configurar Perfil' : 'Editar Perfil',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Foto de perfil
              GestureDetector(
                onTap: _showImagePicker,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF4A4543),
                    border: Border.all(color: Colors.grey, width: 2),
                  ),
                  child: _profileImagePath != null
                      ? ClipOval(
                          child: Image.file(
                            File(_profileImagePath!),
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPlaceholderAvatar();
                            },
                          ),
                        )
                      : _buildPlaceholderAvatar(),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Toca para cambiar foto',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 30),

              // Campos del formulario
              _buildTextField(
                controller: _firstNameController,
                label: 'Nombre',
                icon: Icons.person,
                validator: (value) => _userProfileService.validateFirstName(value ?? ''),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _lastNameController,
                label: 'Apellido',
                icon: Icons.person_outline,
                validator: (value) => _userProfileService.validateLastName(value ?? ''),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _usernameController,
                label: 'Nombre de Usuario',
                icon: Icons.alternate_email,
                validator: (value) => _userProfileService.validateUsername(value ?? ''),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _ageController,
                label: 'Edad',
                icon: Icons.cake,
                keyboardType: TextInputType.number,
                validator: (value) => _userProfileService.validateAge(value ?? ''),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _countryController,
                label: 'País',
                icon: Icons.public,
                validator: (value) => _userProfileService.validateCountry(value ?? ''),
              ),
              const SizedBox(height: 40),

              // Botón de guardar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Guardar Perfil',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return const Icon(
      Icons.person,
      size: 50,
      color: Colors.grey,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF4A4543),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4CAF50)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        prefixIcon: Icon(icon, color: Colors.grey),
      ),
    );
  }
}

class _ImagePickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImagePickerOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4A4543),
              border: Border.all(color: Colors.grey, width: 1),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
