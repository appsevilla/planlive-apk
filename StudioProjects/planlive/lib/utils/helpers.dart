import 'package:flutter/material.dart';

class Helpers {
  /// Muestra un [SnackBar] flotante con un mensaje.
  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? color,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    final snackBar = SnackBar(
      duration: duration,
      backgroundColor: color ?? Colors.black87,
      behavior: SnackBarBehavior.floating,
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
          ],
          Expanded(child: Text(message)),
        ],
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Muestra un cuadro de diálogo de confirmación.
  static Future<bool?> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String content,
    String cancelText = 'Cancelar',
    String confirmText = 'Confirmar',
    Color confirmColor = Colors.deepPurple,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: confirmColor),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}
