import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReportesAdminScreen extends StatefulWidget {
  const ReportesAdminScreen({super.key});

  @override
  State<ReportesAdminScreen> createState() => _ReportesAdminScreenState();
}

class _ReportesAdminScreenState extends State<ReportesAdminScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _eliminarReporte(String docId) async {
    try {
      await _firestore.collection('reports').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte eliminado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar reporte: $e')),
        );
      }
    }
  }

  Widget _buildReporteItem(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    final mensaje = data['message'] ?? '';
    final usuarioReportado = data['reportedUserName'] ?? 'Desconocido';
    final idMensaje = data['messageId'] ?? '';
    final idReportero = data['reporterUserId'] ?? 'Desconocido';
    final Timestamp? fechaTimestamp = data['reportedAt'] as Timestamp?;
    final fecha = fechaTimestamp?.toDate();
    final fechaFormateada = fecha != null
        ? '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}'
        : 'Fecha desconocida';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ListTile(
        title: Text(
          'Mensaje reportado: $mensaje',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Usuario reportado: $usuarioReportado'),
            Text('Reportado por: $idReportero'),
            Text('Fecha: $fechaFormateada'),
            const SizedBox(height: 8),
            Text('ID mensaje: $idMensaje', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          tooltip: 'Eliminar reporte',
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Confirmar eliminación'),
                content: const Text('¿Seguro que quieres eliminar este reporte?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
                ],
              ),
            );

            if (confirm == true) {
              _eliminarReporte(doc.id);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración de Reportes'),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('reports').orderBy('reportedAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar reportes'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No hay reportes'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              return _buildReporteItem(docs[index]);
            },
          );
        },
      ),
    );
  }
}
