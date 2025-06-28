import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _marcarResuelto(String reportId) async {
    await _firestore.collection('reportes_chat').doc(reportId).update({
      'resuelto': true,
      'fechaResuelto': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _eliminarMensaje(String mensajeId, String reportId) async {
    final batch = _firestore.batch();
    final mensajeRef = _firestore.collection('global_chat').doc(mensajeId);
    final reporteRef = _firestore.collection('reportes_chat').doc(reportId);

    batch.delete(mensajeRef);
    batch.update(reporteRef, {'resuelto': true, 'accion': 'mensaje eliminado', 'fechaResuelto': FieldValue.serverTimestamp()});
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar reportes'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('reportes_chat')
            .where('resuelto', isEqualTo: false)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No hay reportes pendientes'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data()! as Map<String, dynamic>;
              final reportId = docs[index].id;
              final mensajeId = data['messageId'] as String? ?? '';
              final mensaje = data['mensaje'] as String? ?? '';
              final senderName = data['senderName'] as String? ?? 'Anon';
              final motivo = data['motivo'] as String? ?? 'Sin motivo';
              final reporterId = data['reporterId'] as String? ?? '';
              final timestamp = data['timestamp'] as Timestamp?;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mensaje: $mensaje', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Enviado por: $senderName'),
                      Text('Reportado por: $reporterId'),
                      Text('Motivo: $motivo'),
                      if (timestamp != null)
                        Text('Fecha reporte: ${timestamp.toDate().toLocal()}'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () => _marcarResuelto(reportId),
                            child: const Text('Marcar como resuelto'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () => _eliminarMensaje(mensajeId, reportId),
                            child: const Text('Eliminar mensaje'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
