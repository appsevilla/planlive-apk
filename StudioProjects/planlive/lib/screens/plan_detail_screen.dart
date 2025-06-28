import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

import '../widgets/like_button.dart';
import '../widgets/follow_button.dart';
import '../widgets/plan_chat_screen.dart';
import 'edit_plan_screen.dart';
import 'map_screen.dart';

class PlanDetailScreen extends StatelessWidget {
  final String planId;

  const PlanDetailScreen({super.key, required this.planId});

  Future<LatLng?> _geocodeUbicacion(String direccion) async {
    try {
      final locations = await locationFromAddress(direccion);
      if (locations.isEmpty) return null;
      final loc = locations.first;
      return LatLng(loc.latitude, loc.longitude);
    } catch (e) {
      debugPrint('Error al geocodificar: $e');
      return null;
    }
  }

  void _mostrarDialogoEliminar(BuildContext context, String planId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar plan?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.of(context).pop();
              await FirebaseFirestore.instance.collection('planes').doc(planId).delete();
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: GoogleFonts.poppins(color: Colors.white70))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('planes').doc(planId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Plan no encontrado', style: GoogleFonts.poppins(color: Colors.white)),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Volver'),
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).pushReplacementNamed('/userPlans');
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        final esDelUsuario = data['uid'] == currentUser?.uid;

        final fecha = data['fechaHora'] != null
            ? DateFormat('dd/MM/yyyy • HH:mm').format((data['fechaHora'] as Timestamp).toDate())
            : 'Sin fecha';

        final ubicacion = (data['ubicacion'] as String?)?.trim().isNotEmpty == true
            ? data['ubicacion'].trim()
            : null;

        final categoria = (data['categoriaNombre'] as String?)?.trim().isNotEmpty == true
            ? data['categoriaNombre'].trim()
            : null;

        final nombreCreador = (data['nombreCreador'] as String?)?.trim().isNotEmpty == true
            ? data['nombreCreador'].trim()
            : 'Anónimo';

        // Obtener URL de la imagen
        final imagenUrl = (data['imagenUrl'] as String?)?.trim().isNotEmpty == true
            ? data['imagenUrl'].trim()
            : null;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushReplacementNamed('/userPlans');
                }
              },
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            actions: esDelUsuario
                ? [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditPlanScreen(planId: planId),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: () => _mostrarDialogoEliminar(context, planId),
              ),
            ]
                : [],
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1D1E33), Color(0xFF111328)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen del plan (si existe)
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
                  Text(data['titulo'] ?? 'Sin título',
                      style: GoogleFonts.poppins(
                          color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Creado por: $nombreCreador',
                      style: GoogleFonts.poppins(
                          color: Colors.white70, fontSize: 14, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 8),
                  infoRow(Icons.calendar_today, fecha),
                  if (ubicacion != null) ...[
                    const SizedBox(height: 4),
                    infoRow(Icons.location_on, ubicacion),
                  ],
                  if (categoria != null) ...[
                    const SizedBox(height: 4),
                    infoRow(Icons.category, categoria),
                  ],
                  const SizedBox(height: 16),
                  if (ubicacion != null)
                    FutureBuilder<LatLng?>(
                      future: _geocodeUbicacion(ubicacion),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final latLng = snapshot.data;
                        if (latLng == null) {
                          return Text('No se pudo localizar el lugar',
                              style: GoogleFonts.poppins(color: Colors.white70));
                        }

                        return Column(
                          children: [
                            SizedBox(
                              height: 200,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: GoogleMap(
                                  initialCameraPosition: CameraPosition(target: latLng, zoom: 14),
                                  markers: {
                                    Marker(markerId: const MarkerId('ubicacion'), position: latLng)
                                  },
                                  zoomControlsEnabled: false,
                                  myLocationButtonEnabled: false,
                                  liteModeEnabled: true,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.map_outlined),
                              label: const Text('Abrir en mapa'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => MapScreen(latLng: latLng),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                  Text(data['descripcion'] ?? 'Sin descripción',
                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 24),
                  LikeButton(
                    liked: false,
                    likeCount: data['likes'] ?? 0,
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  if (!esDelUsuario && data['uid'] != null)
                    FollowButton(isFollowing: false, onPressed: () {}),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Abrir chat del plan'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PlanChatScreen(planId: planId),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  JoinOrCancel(planId: planId),
                  const SizedBox(height: 16),
                  ListaInscritos(planId: planId),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// JoinOrCancel y ListaInscritos (sin cambios importantes)

class JoinOrCancel extends StatefulWidget {
  final String planId;

  const JoinOrCancel({super.key, required this.planId});

  @override
  State<JoinOrCancel> createState() => _JoinOrCancelState();
}

class _JoinOrCancelState extends State<JoinOrCancel> {
  bool _isLoading = true;
  bool _isJoined = false;

  @override
  void initState() {
    super.initState();
    _checkIfJoined();
  }

  Future<void> _checkIfJoined() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('planes')
        .doc(widget.planId)
        .collection('inscritos')
        .doc(user.uid)
        .get();

    if (!mounted) return;
    setState(() {
      _isJoined = doc.exists;
      _isLoading = false;
    });
  }

  Future<void> _toggleJoin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final firestore = FirebaseFirestore.instance;
    final userDoc = await firestore.collection('users').doc(user.uid).get();
    final nombre = userDoc.data()?['nombre'] ?? user.displayName ?? 'Usuario sin nombre';

    final planUserRef = firestore
        .collection('planes')
        .doc(widget.planId)
        .collection('inscritos')
        .doc(user.uid);

    setState(() => _isLoading = true);

    try {
      if (_isJoined) {
        await planUserRef.delete();

        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Has cancelado tu participación.')));
      } else {
        final timestamp = FieldValue.serverTimestamp();
        await planUserRef.set({
          'uid': user.uid,
          'nombre': nombre,
          'inscritoEn': timestamp,
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Te has unido al plan.')));
      }

      if (!mounted) return;
      setState(() {
        _isJoined = !_isJoined;
      });
    } catch (e) {
      debugPrint('Error al cambiar participación: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error al procesar.')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const CircularProgressIndicator();

    return ElevatedButton.icon(
      icon: Icon(_isJoined ? Icons.cancel : Icons.check),
      label: Text(_isJoined ? 'Cancelar participación' : 'Apuntarse'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: _isJoined ? Colors.red : Colors.green,
      ),
      onPressed: _toggleJoin,
    );
  }
}

class ListaInscritos extends StatelessWidget {
  final String planId;

  const ListaInscritos({super.key, required this.planId});

  @override
  Widget build(BuildContext context) {
    final inscritosRef = FirebaseFirestore.instance
        .collection('planes')
        .doc(planId)
        .collection('inscritos');

    return FutureBuilder<QuerySnapshot>(
      future: inscritosRef.orderBy('inscritoEn', descending: false).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('Nadie se ha apuntado aún',
              style: TextStyle(color: Colors.white70));
        }

        final inscritos = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Participantes:',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 8),
            ...inscritos.map((doc) {
              final nombre = (doc.data() as Map<String, dynamic>)['nombre'] ?? 'Usuario desconocido';
              return Text('- $nombre', style: const TextStyle(color: Colors.white70));
            }),
          ],
        );
      },
    );
  }
}

