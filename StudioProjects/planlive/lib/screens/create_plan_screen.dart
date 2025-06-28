import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class CreatePlanScreen extends StatefulWidget {
  const CreatePlanScreen({super.key});

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _claveController = TextEditingController();

  DateTime? _fechaHora;
  bool _esPublico = true;
  bool _isLoading = false;
  File? _imagenPlan;
  String? _categoriaSeleccionada;

  final List<String> _categoriasDisponibles = [
    'Todas', 'Aventura', 'Cultural', 'Gastronomía', 'Relax', 'Deportivos', 'Para Niños'
  ];

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _ubicacionController.dispose();
    _claveController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (!mounted) return;
    if (pickedFile != null) {
      setState(() {
        _imagenPlan = File(pickedFile.path);
      });
    }
  }

  Future<String?> _subirImagen() async {
    if (_imagenPlan == null) return null;
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = FirebaseStorage.instance.ref().child('planes/$fileName.jpg');
    final uploadTask = ref.putFile(_imagenPlan!);
    final snapshot = await uploadTask;
    if (!mounted) return null;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> _obtenerUbicacion() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ GPS desactivado. Actívalo para continuar')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Permiso de ubicación denegado')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Permiso denegado permanentemente. Habilítalo desde ajustes.'),
        ),
      );
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (!mounted) return;

      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String direccion =
            '${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}';

        setState(() {
          _ubicacionController.text = direccion;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('📍 Ubicación detectada: $direccion')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ No se pudo obtener la dirección')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al obtener ubicación: $e')),
      );
    }
  }

  Future<void> _seleccionarFechaHora() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;
    if (!mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return;
    if (!mounted) return;

    final selectedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (selectedDateTime.isBefore(DateTime.now())) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ La fecha no puede ser en el pasado')),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _fechaHora = selectedDateTime;
    });
  }

  String _formattedDate() {
    if (_fechaHora == null) return 'Seleccionar fecha y hora';
    return DateFormat('dd/MM/yyyy • HH:mm').format(_fechaHora!);
  }

  Future<void> _crearPlan() async {
    if (!_formKey.currentState!.validate() || _fechaHora == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Completa todos los campos obligatorios')),
      );
      return;
    }

    final direccion = _ubicacionController.text.trim();

    if (direccion.isNotEmpty) {
      try {
        final results = await locationFromAddress(direccion);
        if (!mounted) return;
        if (results.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Dirección inválida o no encontrada')),
          );
          return;
        }
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Dirección inválida o no encontrada')),
        );
        return;
      }
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    String? imagenUrl;
    bool success = false;

    try {
      imagenUrl = await _subirImagen();
      if (!mounted) return;

      final planRef = FirebaseFirestore.instance.collection('planes').doc();
      final planData = {
        'uid': user.uid,
        'titulo': _tituloController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'fechaHora': Timestamp.fromDate(_fechaHora!),
        'creadoEn': FieldValue.serverTimestamp(),
        'nombreCreador': user.displayName ?? 'Anónimo',
        'publico': _esPublico,
        'comentarios': [],
        'imagenUrl': imagenUrl ?? '',
        'categoria': _categoriaSeleccionada,
      };

      if (direccion.isNotEmpty) {
        planData['ubicacion'] = direccion;
      }

      if (!_esPublico) {
        planData['clave'] = _claveController.text.trim();
      }

      await planRef.set(planData);
      if (!mounted) return;

      await planRef.collection('inscritos').doc(user.uid).set({
        'userId': user.uid,
        'nombre': user.displayName ?? 'Anónimo',
        'correo': user.email ?? '',
        'fechaInscripcion': FieldValue.serverTimestamp(),
      });

      success = true;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al crear el plan: $e')),
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Plan creado correctamente')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Plan'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1D1E33), Color(0xFF111328)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField('Título del plan', _tituloController),
              const SizedBox(height: 16),
              _buildTextField('Descripción', _descripcionController, maxLines: 3),
              const SizedBox(height: 16),
              _buildTextField('Ubicación (opcional)', _ubicacionController, isRequired: false),
              TextButton.icon(
                onPressed: _obtenerUbicacion,
                icon: const Icon(Icons.my_location, color: Colors.white),
                label: const Text('Usar mi ubicación actual', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                tileColor: Colors.white10,
                title: Text('Fecha y hora', style: GoogleFonts.poppins(color: Colors.white)),
                subtitle: Text(_formattedDate(), style: GoogleFonts.poppins(color: Colors.white70)),
                trailing: const Icon(Icons.calendar_today, color: Colors.white70),
                onTap: _seleccionarFechaHora,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _categoriaSeleccionada,
                items: _categoriasDisponibles
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                decoration: InputDecoration(
                  labelText: 'Categoría del plan',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                dropdownColor: const Color(0xFF1D1E33),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) => setState(() => _categoriaSeleccionada = value),
                validator: (value) => value == null ? 'Selecciona una categoría' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('¿Público?', style: TextStyle(color: Colors.white)),
                  Switch(
                    value: _esPublico,
                    onChanged: (val) => setState(() => _esPublico = val),
                    activeColor: const Color(0xFF4A90E2), // azul claro profesional
                  ),
                ],
              ),
              if (!_esPublico)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextFormField(
                    controller: _claveController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Clave del plan privado',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white12,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (value) {
                      if (!_esPublico && (value == null || value.trim().isEmpty)) {
                        return 'La clave es obligatoria para planes privados';
                      }
                      return null;
                    },
                  ),
                ),
              const SizedBox(height: 16),
              if (_imagenPlan != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_imagenPlan!, height: 200, fit: BoxFit.cover),
                ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1D1E33), // mismo color de fondo
                  border: Border.all(color: Colors.black), // borde negro para diferenciar
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextButton.icon(
                  onPressed: _seleccionarImagen,
                  icon: const Icon(Icons.image, color: Colors.white),
                  label: const Text(
                    'Agregar imagen',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _crearPlan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple, // botón morado
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Crear plan', style: GoogleFonts.poppins(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1, bool isRequired = true}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white12,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return 'Este campo es obligatorio';
        }
        return null;
      },
    );
  }
}

