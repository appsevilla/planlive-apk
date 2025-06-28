import 'package:flutter/material.dart';

import '../widgets/background_scaffold.dart';

class ComunidadScreen extends StatelessWidget {
  const ComunidadScreen({super.key});

  // Simulamos una lista de publicaciones en comunidad
  final List<String> posts = const [
    'Bienvenidos a la comunidad!',
    '¿Alguien tiene planes para el fin de semana?',
    'Comparte tus mejores tips para organizar eventos.',
    'muy pronto disponible para todosssss!',
  ];

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Comunidad'),
        centerTitle: true,
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return Card(
            color: Colors.white.withOpacity(0.15),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                post,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }
}
