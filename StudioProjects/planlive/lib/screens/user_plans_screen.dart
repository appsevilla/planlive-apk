import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:planlive/widgets/background_scaffold.dart';

class UserPlansScreen extends StatefulWidget {
  const UserPlansScreen({super.key});

  @override
  State<UserPlansScreen> createState() => _UserPlansScreenState();
}

class _UserPlansScreenState extends State<UserPlansScreen> {
  User? _user;
  bool _loadingUserData = true;

  @override
  void initState() {
    super.initState();
    _initUser();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          _user = user;
          if (user != null) {
            _updateUserData(user);
          }
        });
      }
    });
  }

  Future<void> _initUser() async {
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) await _updateUserData(_user!);
    if (mounted) setState(() => _loadingUserData = false);
  }

  Future<void> _updateUserData(User user) async {
    try {
      final token = await user.getIdToken();
      final userDocRef =
      FirebaseFirestore.instance.collection('users').doc(user.uid);
      final userData = <String, dynamic>{
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'lastLogin': FieldValue.serverTimestamp(),
        'token': token,
      };
      await userDocRef.set(userData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error actualizando datos de usuario: $e');
    }
  }

  Future<List<DocumentSnapshot>> _fetchPlanesApuntados(
      String uid, List<String> createdPlanIds) async {
    try {
      final inscritosSnap = await FirebaseFirestore.instance
          .collectionGroup('inscritos')
          .where('userId', isEqualTo: uid)
          .get();

      final apuntadoPlans = <DocumentSnapshot>[];

      for (final doc in inscritosSnap.docs) {
        final parentPlanRef = doc.reference.parent.parent;
        if (parentPlanRef != null) {
          final planSnap = await parentPlanRef.get();
          if (planSnap.exists && !createdPlanIds.contains(planSnap.id)) {
            apuntadoPlans.add(planSnap);
          }
        }
      }

      return apuntadoPlans;
    } catch (e) {
      debugPrint('Error obteniendo planes apuntados: $e');
      return [];
    }
  }

  Future<Map<String, int>> _fetchInscritosForAll(
      List<DocumentSnapshot> docs) async {
    final Map<String, int> inscritosMap = {};
    for (final doc in docs) {
      final inscritos = await doc.reference.collection('inscritos').get();
      inscritosMap[doc.id] = inscritos.size;
    }
    return inscritosMap;
  }

  Future<void> _autoDeleteIfExpired(DocumentSnapshot doc, DateTime fecha) async {
    final now = DateTime.now();
    if (fecha.isBefore(now.subtract(const Duration(minutes: 30)))) {
      try {
        await doc.reference.delete();
        debugPrint('Plan eliminado automáticamente: ${doc.id}');
      } catch (e) {
        debugPrint('Error al eliminar automáticamente: $e');
      }
    }
  }

  void _openPlanDetail(String planId) {
    Navigator.pushNamed(
      context,
      '/plan_detail',
      arguments: planId,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUserData) {
      return const Scaffold(
        backgroundColor: Color(0xFF111328),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF111328),
        body: Center(
          child: Text('Usuario no autenticado',
              style: TextStyle(fontSize: 18, color: Colors.white)),
        ),
      );
    }

    final createdPlansStream = FirebaseFirestore.instance
        .collection('planes')
        .where('uid', isEqualTo: _user!.uid)
        .orderBy('fechaHora', descending: true)
        .snapshots();

    return WillPopScope(
      onWillPop: () async => false,
      child: BackgroundScaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Mis Planes', style: TextStyle(color: Colors.white)),
          centerTitle: true,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 120, 16, 16),
          child: StreamBuilder<QuerySnapshot>(
            stream: createdPlansStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final createdDocs = snapshot.data?.docs ?? [];
              final createdIds = createdDocs.map((doc) => doc.id).toList();

              return FutureBuilder<List<DocumentSnapshot>>(
                future: _fetchPlanesApuntados(_user!.uid, createdIds),
                builder: (context, apuntadosSnapshot) {
                  if (apuntadosSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final apuntadosDocs = apuntadosSnapshot.data ?? [];
                  final allDocs = [...createdDocs, ...apuntadosDocs];

                  if (allDocs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No tienes planes creados ni apuntados.',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    );
                  }

                  return FutureBuilder<Map<String, int>>(
                    future: _fetchInscritosForAll(allDocs),
                    builder: (context, inscritosSnapshot) {
                      if (!inscritosSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final inscritosMap = inscritosSnapshot.data!;

                      return ListView.builder(
                        itemCount: allDocs.length,
                        itemBuilder: (context, index) {
                          final doc = allDocs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final fecha = (data['fechaHora'] as Timestamp).toDate();
                          final inscritos = inscritosMap[doc.id] ?? 0;
                          final esCreador = data['uid'] == _user!.uid;

                          final ubicacion = data['ubicacion'] ?? 'Ubicación no especificada';
                          final categoria = data['categoria'] ?? 'Sin categoría';

                          final ahora = DateTime.now();
                          final haPasado = fecha.isBefore(ahora);
                          final expirado = fecha.isBefore(
                            ahora.subtract(const Duration(minutes: 30)),
                          );

                          // Eliminar automáticamente si ya pasó hace más de 30 min
                          if (expirado) _autoDeleteIfExpired(doc, fecha);

                          final cardColor = haPasado
                              ? Colors.red.withOpacity(0.15)
                              : Colors.white.withOpacity(0.15);

                          return Card(
                            color: cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              onTap: () => _openPlanDetail(doc.id),
                              title: Text(
                                data['titulo'] ?? 'Sin título',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ubicación: $ubicacion',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    Text(
                                      'Inscritos: $inscritos',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    Text(
                                      'Categoría: $categoria',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      esCreador ? '(Creado por ti)' : '(Apuntado)',
                                      style: TextStyle(
                                        color: esCreador
                                            ? Colors.greenAccent
                                            : Colors.orangeAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

