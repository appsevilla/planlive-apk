import 'package:flutter/material.dart';

class ClaveDialog extends StatefulWidget {
  final String claveCorrecta;

  const ClaveDialog({super.key, required this.claveCorrecta});

  @override
  State<ClaveDialog> createState() => _ClaveDialogState();
}

class _ClaveDialogState extends State<ClaveDialog> {
  final _claveController = TextEditingController();
  String? _errorText;

  void _validarClave() {
    if (_claveController.text.trim() == widget.claveCorrecta) {
      Navigator.of(context).pop(true); // Clave correcta, retorna true
    } else {
      setState(() {
        _errorText = 'Clave incorrecta. Intenta de nuevo.';
      });
    }
  }

  @override
  void dispose() {
    _claveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Introduce la clave de inscripción'),
      content: TextField(
        controller: _claveController,
        obscureText: true,
        decoration: InputDecoration(
          labelText: 'Clave',
          errorText: _errorText,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false), // Cancelar
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _validarClave,
          child: const Text('Validar'),
        ),
      ],
    );
  }
}
