import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ComentariosWidget extends StatelessWidget {
  final String planId;

  const ComentariosWidget({super.key, required this.planId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('planes')
          .doc(planId)
          .collection('comentarios')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final comentarios = snapshot.data!.docs;

        if (comentarios.isEmpty) {
          return Center(
            child: Text(
              'Sé el primero en comentar',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          itemCount: comentarios.length,
          itemBuilder: (context, index) {
            final data = comentarios[index].data() as Map<String, dynamic>;
            final texto = data['texto'] ?? '';
            final autor = data['autor'] ?? 'Anónimo';

            return ListTile(
              title: Text(
                autor,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                texto,
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            );
          },
        );
      },
    );
  }
}
