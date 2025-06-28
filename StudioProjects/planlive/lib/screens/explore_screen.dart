import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart';
import 'package:planlive/screens/public_plan_detail.dart';
import 'package:planlive/widgets/background_scaffold.dart';

class FiltroCategoriaState {
  static String? ultimaCategoriaSeleccionada;
}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  List<DocumentSnapshot> _plans = [];
  Set<String> _favoritos = {};
  Set<String> _inscritos = {};
  bool _isLoading = true;

  final List<String> _categorias = [
    'Todas',
    'Aventura',
    'Cultural',
    'Gastronomía',
    'Relax',
    'Deportivos',
    'Para Niños'
  ];
  String? _categoriaSeleccionada;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _categoriaSeleccionada = FiltroCategoriaState.ultimaCategoriaSeleccionada ?? 'Todas';
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      Query query = FirebaseFirestore.instance.collection('planes');

      if (_categoriaSeleccionada != null && _categoriaSeleccionada != 'Todas') {
        query = query.where('categoria', isEqualTo: _categoriaSeleccionada);
      }

      final snapshot = await query.orderBy('fechaHora', descending: false).get();

      final now = DateTime.now();
      List<DocumentSnapshot> filtered = [];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = data['fechaHora'] as Timestamp?;
        final fecha = timestamp?.toDate();

        if (fecha != null && fecha.add(const Duration(minutes: 15)).isBefore(now)) {
          await doc.reference.delete();
          continue;
        }

        filtered.add(doc);
      }

      if (mounted) {
        setState(() {
          _plans = filtered;
        });
      }

      if (_user != null) {
        await _loadFavoritos();
        await _loadInscritos();
      }
    } catch (e) {
      debugPrint('Error loading plans: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadFavoritos() async {
    try {
      final favsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('favoritos')
          .get();

      if (mounted) {
        setState(() {
          _favoritos = favsSnapshot.docs.map((doc) => doc.id).toSet();
        });
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  Future<void> _loadInscritos() async {
    try {
      final inscritosSnapshot = await FirebaseFirestore.instance
          .collectionGroup('inscritos')
          .where('userId', isEqualTo: _user!.uid)
          .get();

      if (mounted) {
        setState(() {
          _inscritos = inscritosSnapshot.docs.map((doc) => doc.reference.parent.parent!.id).toSet();
        });
      }
    } catch (e) {
      debugPrint('Error loading inscritos: $e');
    }
  }

  Future<void> _toggleFavorito(String planId) async {
    if (_user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('favoritos')
        .doc(planId);

    try {
      if (_favoritos.contains(planId)) {
        await docRef.delete();
        if (mounted) {
          setState(() => _favoritos.remove(planId));
        }
      } else {
        await docRef.set({'addedAt': Timestamp.now()});
        if (mounted) {
          setState(() => _favoritos.add(planId));
        }
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  Future<bool?> _pedirClaveDialogo(BuildContext context, String planId) async {
    final TextEditingController claveController = TextEditingController();

    final docPlan = await FirebaseFirestore.instance.collection('planes').doc(planId).get();
    final planData = docPlan.data();

    return showDialog<bool>(
      // ignore: use_build_context_synchronously
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.deepPurple[900],
          title: const Text('Ingrese la clave', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: claveController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Clave de inscripción',
              hintStyle: const TextStyle(color: Colors.white54),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white54),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.deepPurpleAccent),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
              onPressed: () {
                final claveIngresada = claveController.text.trim();
                final claveCorrecta = planData?['clave']?.toString() ?? '';

                if (claveIngresada == claveCorrecta) {
                  Navigator.of(dialogContext).pop(true);
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Clave incorrecta', style: TextStyle(color: Colors.white)),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Entrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final filteredPlans = _plans.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final title = data['titulo']?.toString().toLowerCase() ?? '';
      return title.contains(_searchText.toLowerCase());
    }).toList();

    filteredPlans.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;

      final aDestacado = (_user?.uid == aData['uid'] || _inscritos.contains(a.id)) ? 1 : 0;
      final bDestacado = (_user?.uid == bData['uid'] || _inscritos.contains(b.id)) ? 1 : 0;

      return bDestacado.compareTo(aDestacado);
    });

    return WillPopScope(
      onWillPop: () async => false,
      child: BackgroundScaffold(
        appBar: AppBar(
          title: const Text('Explorar Planes'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildDropdown(),
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 24),
              Expanded(child: _buildPlanList(filteredPlans, now)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Center(
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.deepPurple[900]!.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.deepPurple[800]!.withOpacity(0.9)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _categoriaSeleccionada,
            dropdownColor: Colors.deepPurple[900],
            iconEnabledColor: Colors.white,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            borderRadius: BorderRadius.circular(12),
            items: _categorias.map((cat) {
              return DropdownMenuItem<String>(
                value: cat,
                child: Text(cat),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _categoriaSeleccionada = value;
                FiltroCategoriaState.ultimaCategoriaSeleccionada = value;
                _isLoading = true;
              });
              _loadPlans();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        hintText: 'Buscar por título',
        hintStyle: GoogleFonts.poppins(color: Colors.white70),
        prefixIcon: const Icon(Icons.search, color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      style: GoogleFonts.poppins(color: Colors.white),
      onChanged: (value) => setState(() => _searchText = value),
    );
  }

  Widget _buildPlanList(List<DocumentSnapshot> plans, DateTime now) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent));
    } else if (plans.isEmpty) {
      return Center(
        child: Text(
          'No hay planes disponibles.',
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
        ),
      );
    } else {
      return ListView.builder(
        itemCount: plans.length,
        itemBuilder: (context, index) {
          final planDoc = plans[index];
          final planData = planDoc.data() as Map<String, dynamic>;
          final planId = planDoc.id;
          final isFavorito = _favoritos.contains(planId);

          final String title = planData['titulo'] ?? 'Sin título';
          final String categoria = planData['categoria'] ?? 'Sin categoría';
          final String ubicacion = planData['ubicacion'] ?? 'No especificada';
          final List inscritos = planData['inscritos'] ?? [];
          final String creadorUid = planData['uid'] ?? '';
          final bool esCreador = _user?.uid == creadorUid;
          final bool estaInscrito = _inscritos.contains(planId);
          final bool privado = (planData['privado'] ?? false) == true;

          final timestamp = planData['fechaHora'] as Timestamp?;
          final fechaPlan = timestamp?.toDate();
          final bool planPasado = fechaPlan != null && fechaPlan.isBefore(now);

          return GestureDetector(
            onTap: () async {
              final localContext = context; // guarda el contexto antes del await

              if (privado) {
                final correcto = await _pedirClaveDialogo(localContext, planId);
                if (!mounted) return; // verifica que el widget sigue montado antes de usar contexto
                if (correcto == true) {
                  Navigator.push(
                    Context as BuildContext,
                    MaterialPageRoute(
                      builder: (context) => PublicPlanDetailScreen(planDoc: planDoc),
                    ),
                  );
                }
              } else {
                if (!mounted) return;
                Navigator.push(
                  localContext,
                  MaterialPageRoute(
                    builder: (context) => PublicPlanDetailScreen(planDoc: planDoc),
                  ),
                );
              }
            },
            child: _glassCard(
              title: title,
              categoria: categoria,
              ubicacion: ubicacion,
              inscritosCount: inscritos.length,
              isFavorito: isFavorito,
              onTapFav: () => _toggleFavorito(planId),
              destacado: esCreador || estaInscrito,
              planPasado: planPasado,
              privado: privado,
            ),
          );
        },
      );
    }
  }

  Widget _glassCard({
    required String title,
    required String categoria,
    required String ubicacion,
    required int inscritosCount,
    required bool isFavorito,
    required VoidCallback onTapFav,
    required bool destacado,
    required bool planPasado,
    bool privado = false,
  }) {
    Color backgroundColor;

    if (planPasado) {
      backgroundColor = Colors.red.withOpacity(0.6);
    } else if (privado) {
      backgroundColor = Colors.orange.withOpacity(0.6);
    } else if (destacado) {
      backgroundColor = Colors.green.withOpacity(0.6);
    } else {
      backgroundColor = Colors.white.withOpacity(0.28);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurpleAccent.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(categoria,
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white)),
                const SizedBox(height: 4),
                Text(title,
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.place, size: 10, color: Colors.white),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(ubicacion,
                          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.people, size: 20, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(inscritosCount.toString(),
                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              isFavorito ? Icons.favorite : Icons.favorite_border,
              color: isFavorito ? Colors.deepPurpleAccent : Colors.white,
              size: 35,
            ),
            onPressed: onTapFav,
          ),
        ],
      ),
    );
  }
}
