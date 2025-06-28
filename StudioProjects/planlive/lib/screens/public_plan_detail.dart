import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PublicPlanDetailScreen extends StatefulWidget {
  final DocumentSnapshot planDoc;

  const PublicPlanDetailScreen({super.key, required this.planDoc});

  @override
  State<PublicPlanDetailScreen> createState() => _PublicPlanDetailScreenState();
}

class _PublicPlanDetailScreenState extends State<PublicPlanDetailScreen> {
  bool _inscrito = false;
  bool _loading = true;
  int _numInscritos = 0;

  DocumentSnapshot get _planDoc => widget.planDoc;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !mounted) return;

    final inscritosRef = _planDoc.reference.collection('inscritos');
    final inscripcionDoc = await inscritosRef.doc(user.uid).get();
    final totalInscritos = await inscritosRef.get();

    if (!mounted) return;

    setState(() {
      _inscrito = inscripcionDoc.exists;
      _numInscritos = totalInscritos.docs.length;
      _loading = false;
    });
  }

  Future<void> _inscribirseEnPlan() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      await _planDoc.reference.collection('inscritos').doc(user.uid).set({
        'userId': user.uid,
        'nombre': userData.data()?['nombre'] ?? 'Anónimo',
        'correo': user.email ?? '',
        'fechaInscripcion': Timestamp.now(),
      });

      if (!mounted) return;

      setState(() {
        _inscrito = true;
        _numInscritos++;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Te has inscrito en el plan')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al inscribirse: $e')),
      );
    }
  }

  Future<void> _cancelarInscripcion() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _planDoc.reference.collection('inscritos').doc(user.uid).delete();

      if (!mounted) return;

      setState(() {
        _inscrito = false;
        _numInscritos--;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Has cancelado tu inscripción')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cancelar inscripción: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF111328),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final Map<String, dynamic> data = _planDoc.data() as Map<String, dynamic>? ?? {};
    final DateTime? fecha = data['fechaHora'] is Timestamp ? (data['fechaHora'] as Timestamp).toDate() : null;

    final formattedDate = fecha != null
        ? DateFormat('dd/MM/yyyy • HH:mm', 'es_ES').format(fecha)
        : 'Fecha no disponible';

    final isOwner = FirebaseAuth.instance.currentUser?.uid == data['uid'];
    final esPrivado = data['privado'] == true;

    // Obtener URL de la imagen
    final imagenUrl = (data['imagenUrl'] as String?)?.trim().isNotEmpty == true
        ? data['imagenUrl'].trim()
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Plan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1D1E33), Color(0xFF111328)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (esPrivado)
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Text(
                  '🔒 Este es un plan privado',
                  style: TextStyle(color: Colors.amber, fontSize: 16),
                ),
              ),
            Text(
              data['titulo'] ?? 'Sin título',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 12),

            if (imagenUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imagenUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text('No se pudo cargar la imagen',
                          style: TextStyle(color: Colors.white70)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    formattedDate,
                    style: const TextStyle(color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    data['ubicacion'] ?? 'Lugar no especificado',
                    style: const TextStyle(color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Descripción:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              data['descripcion'] ?? 'Sin descripción.',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Text(
              'Personas inscritas: $_numInscritos',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const Spacer(),
            if (!isOwner)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _inscrito ? _cancelarInscripcion : _inscribirseEnPlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _inscrito ? Colors.red : Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    _inscrito ? 'Cancelar inscripción' : 'Inscribirme',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}



