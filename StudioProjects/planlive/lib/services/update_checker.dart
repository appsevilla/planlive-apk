import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> checkForUpdate(BuildContext context) async {
  try {
    // Paso 1: Obtener versión actual instalada
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    // Paso 2: Obtener versión publicada en GitHub Pages
    const url = 'https://appsevilla.github.io/planlive/version.json';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final remoteData = json.decode(response.body);
      final latestVersion = remoteData['latest_version'];
      final downloadUrl = remoteData['update_url'];

      if (_isNewerVersion(latestVersion, currentVersion)) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Actualización disponible'),
              content: Text('Hay una nueva versión ($latestVersion) disponible.'),
              actions: [
                TextButton(
                  child: const Text('Más tarde'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('Actualizar'),
                  onPressed: () {
                    launchUrl(Uri.parse(downloadUrl), mode: LaunchMode.externalApplication);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        }
      } else {
        if (kDebugMode) debugPrint('La app está actualizada.');
      }
    }
  } catch (e) {
    if (kDebugMode) debugPrint('Error comprobando actualización: $e');
  }
}

bool _isNewerVersion(String remote, String local) {
  List<int> r = remote.split('.').map(int.parse).toList();
  List<int> l = local.split('.').map(int.parse).toList();
  for (int i = 0; i < r.length; i++) {
    if (r[i] > l[i]) return true;
    if (r[i] < l[i]) return false;
  }
  return false;
}
