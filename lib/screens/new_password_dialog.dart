import 'package:flutter/material.dart';

import '../services/auth_service.dart';

/// Pide la nueva contraseña tras abrir el enlace de recuperación del correo.
Future<void> showNewPasswordDialog(BuildContext context, AuthService auth) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _NewPasswordDialog(auth: auth),
  );
}

class _NewPasswordDialog extends StatefulWidget {
  final AuthService auth;

  const _NewPasswordDialog({required this.auth});

  @override
  State<_NewPasswordDialog> createState() => _NewPasswordDialogState();
}

class _NewPasswordDialogState extends State<_NewPasswordDialog> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_password.text.length < 6) {
      return setState(() => _error = 'Debe tener al menos 6 caracteres');
    }
    if (_password.text != _confirm.text) {
      return setState(() => _error = 'Las contraseñas no coinciden');
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.auth.updatePassword(_password.text);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada'), backgroundColor: Colors.green),
      );
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF3A3634),
      title: const Text('Nueva contraseña', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _password,
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            decoration: const InputDecoration(labelText: 'Nueva contraseña'),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirm,
            obscureText: true,
            decoration: InputDecoration(labelText: 'Confirmar', errorText: _error),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _saving ? null : _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
