import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:planlive/screens/user_profile_screen.dart';
import 'package:planlive/screens/login_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';

class MenuScreen {
  static const String currentVersion = '1.0.0';

  static Future<void> show(BuildContext context, WidgetRef ref) async {
    // Primero comprueba la actualización fuera del contexto async
    bool updateAvailable = await _checkForUpdateFlag();

    // Luego verifica que el widget esté montado antes de mostrar el modal
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.account_circle),
                title: const Text('Mi perfil'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UserProfileScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Compartir'),
                onTap: () {
                  Navigator.pop(context);
                  Share.share(
                    '¡Descubre y únete a planes cerca de ti con PlanLive! 🔥\n\nDescárgala aquí: https://appsevilla.github.io/planlive',
                    subject: 'PlanLive - Planes espontáneos cerca de ti',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.report),
                title: const Text('Reportar un problema'),
                onTap: () {
                  Navigator.pop(context);
                  _showReportDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.contact_mail),
                title: const Text('Contacto'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contacto: appsevilla2025@gmail.com')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: Row(
                  children: [
                    const Text('Configuración'),
                    const SizedBox(width: 6),
                    if (updateAvailable)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showSettingsDialog(context, ref, updateAvailable);
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Cerrar sesión',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static void _showSettingsDialog(BuildContext context, WidgetRef ref, bool updateAvailable) {
    bool isDarkMode = ref.read(themeNotifierProvider).isDarkMode;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Configuración'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.system_update),
                    title: Row(
                      children: [
                        const Text('Buscar actualización'),
                        const SizedBox(width: 6),
                        if (updateAvailable)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    onTap: () async {
                      Navigator.of(ctx).pop(); // Cierra diálogo antes del await

                      final bool update = await _checkForUpdate(context);

                      if (!context.mounted) return;

                      if (update) {
                        _showUpdateDialog(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('La aplicación está actualizada.')),
                        );
                      }
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Modo oscuro'),
                    secondary: const Icon(Icons.dark_mode),
                    value: isDarkMode,
                    onChanged: (value) {
                      setState(() {
                        isDarkMode = value;
                      });
                      ref.read(themeNotifierProvider).toggleTheme();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('Propiedad'),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Propiedad'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Propiedad de Jose Baco'),
                              SizedBox(height: 8),
                              Text('Marca registrada'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cerrar'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  static Future<bool> _checkForUpdateFlag() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('appConfig').doc('version').get();
      if (!doc.exists) return false;

      final data = doc.data();
      if (data == null || !data.containsKey('latestVersion')) return false;

      final String latestVersion = data['latestVersion'];

      return _isNewerVersion(latestVersion, currentVersion);
    } catch (e) {
      return false;
    }
  }

  static Future<bool> _checkForUpdate(BuildContext context) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('appConfig').doc('version').get();
      if (!doc.exists) return false;

      final data = doc.data();
      if (data == null || !data.containsKey('latestVersion')) return false;

      final String latestVersion = data['latestVersion'];

      bool newer = _isNewerVersion(latestVersion, currentVersion);

      return newer;
    } catch (e) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al comprobar actualización: $e')),
      );
      return false;
    }
  }

  static bool _isNewerVersion(String latest, String current) {
    List<int> latestParts = latest.split('.').map(int.parse).toList();
    List<int> currentParts = current.split('.').map(int.parse).toList();

    for (int i = 0; i < latestParts.length; i++) {
      if (i >= currentParts.length) return true;
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  static void _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva actualización disponible'),
        content: const Text('¿Quieres descargar e instalar la nueva versión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Descargando actualización...')),
              );
              // Aquí va la lógica para descargar o redirigir a la tienda
            },
            child: const Text('Instalar'),
          ),
        ],
      ),
    );
  }

  static void _showReportDialog(BuildContext context) {
    final TextEditingController reportController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Reportar un problema'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: reportController,
              maxLines: 4,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Describe el problema o contenido ofensivo...',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().length < 10) {
                  return 'Por favor, escribe al menos 10 caracteres.';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Debes iniciar sesión para reportar.')),
                  );
                  return;
                }

                try {
                  await FirebaseFirestore.instance.collection('reports').add({
                    'userId': user.uid,
                    'userEmail': user.email ?? '',
                    'reportText': reportController.text.trim(),
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Reporte enviado. Gracias por ayudar a mejorar.')),
                  );
                } catch (e) {
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Error al enviar reporte: $e')),
                  );
                }
              },
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
  }
}
