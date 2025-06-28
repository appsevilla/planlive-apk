import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ComentariosDelUsuario extends StatelessWidget {
  final String uid;

  const ComentariosDelUsuario({super.key, required this.uid});

  Future<List<Map<String, dynamic>>> _getComentariosUsuario() async {
    final planesSnapshot = await FirebaseFirestore.instance.collection('planes').get();
    final List<Map<String, dynamic>> comentarios = [];

    for (var planDoc in planesSnapshot.docs) {
      final planId = planDoc.id;
      final comentariosSnapshot = await FirebaseFirestore.instance
          .collection('planes')
          .doc(planId)
          .collection('comentarios')
          .where('autorId', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .get();

      for (var comentarioDoc in comentariosSnapshot.docs) {
        final data = comentarioDoc.data();
        data['planId'] = planId;
        comentarios.add(data);
      }
    }

    return comentarios;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getComentariosUsuario(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final comentarios = snapshot.data ?? [];

        if (comentarios.isEmpty) {
          return const Center(child: Text("No has hecho comentarios aún", style: TextStyle(color: Colors.white70)));
        }

        return ListView.builder(
          itemCount: comentarios.length,
          itemBuilder: (context, index) {
            final comentario = comentarios[index];
            return Card(
              color: Colors.white10,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text(
                  comentario['texto'] ?? '',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'En plan: ${comentario['planId']}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
