import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class EditPlanScreen extends StatefulWidget {
  final String planId;

  const EditPlanScreen({super.key, required this.planId});

  @override
  State<EditPlanScreen> createState() => _EditPlanScreenState();
}

class _EditPlanScreenState extends State<EditPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _ubicacionController = TextEditingController();

  DateTime? _fechaHora;
  bool _isSaving = false;
  bool _isLoading = true;

  // Imagen
  String? _imagenUrl; // URL actual de la imagen guardada
  File? _imagenNueva;  // Imagen seleccionada nueva (local)

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('planes')
          .doc(widget.planId)
          .get();

      if (!mounted) return;

      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Plan no encontrado')),
        );
        Navigator.of(context).pop();
        return;
      }

      final data = doc.data()!;
      _tituloController.text = data['titulo'] ?? '';
      _descripcionController.text = data['descripcion'] ?? '';
      _ubicacionController.text = data['ubicacion'] ?? '';
      final timestamp = data['fechaHora'] as Timestamp?;
      _fechaHora = timestamp?.toDate();
      _imagenUrl = data['imagenUrl'] as String?;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al cargar el plan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _ubicacionController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final now = DateTime.now();
    final initialDate = _fechaHora ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: DateTime(2100),
    );

    if (!mounted || pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (!mounted || pickedTime == null) return;

    setState(() {
      _fechaHora = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  String _formattedDate() {
    if (_fechaHora == null) return 'Seleccionar fecha y hora';
    return DateFormat('dd/MM/yyyy – HH:mm').format(_fechaHora!);
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);

    if (pickedFile != null) {
      setState(() {
        _imagenNueva = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('planes')
          .child(widget.planId)
          .child('imagen_plan.jpg');

      final uploadTask = storageRef.putFile(imageFile);

      final snapshot = await uploadTask;

      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('Error al subir imagen: $e');
      return null;
    }
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate() || _fechaHora == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Por favor completa todos los campos y selecciona una fecha.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? nuevaImagenUrl = _imagenUrl;

      if (_imagenNueva != null) {
        final url = await _uploadImage(_imagenNueva!);
        if (url != null) {
          nuevaImagenUrl = url;
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Error al subir la imagen')),
          );
          setState(() => _isSaving = false);
          return;
        }
      }

      await FirebaseFirestore.instance
          .collection('planes')
          .doc(widget.planId)
          .update({
        'titulo': _tituloController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'ubicacion': _ubicacionController.text.trim(),
        'fechaHora': Timestamp.fromDate(_fechaHora!),
        'imagenUrl': nuevaImagenUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Plan actualizado con éxito.')),
      );

      Navigator.of(context).pop(true); // Vuelve con resultado 'true' para indicar éxito
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al actualizar: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.white70),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Plan'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
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
              GestureDetector(
                onTap: _pickImage,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _imagenNueva != null
                          ? Image.file(
                        _imagenNueva!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                          : (_imagenUrl != null && _imagenUrl!.isNotEmpty)
                          ? Image.network(
                        _imagenUrl!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Text(
                              'No se pudo cargar la imagen',
                              style: TextStyle(color: Colors.white70),
                            ),
                          );
                        },
                      )
                          : Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.white10,
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            size: 60,
                            color: Colors.white30,
                          ),
                        ),
                      ),
                      Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.black38,
                        alignment: Alignment.center,
                        child: const Text(
                          'Pulsa la imagen para cambiar',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                label: 'Título',
                controller: _tituloController,
                validator: (value) =>
                value == null || value.trim().isEmpty ? 'Ingrese un título válido' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Descripción',
                controller: _descripcionController,
                maxLines: 4,
                validator: (value) => value == null || value.trim().length < 10
                    ? 'La descripción debe tener al menos 10 caracteres'
                    : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Ubicación',
                controller: _ubicacionController,
                validator: (value) =>
                value == null || value.trim().isEmpty ? 'Ingrese una ubicación válida' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                tileColor: Colors.white10,
                title: Text(
                  'Fecha y hora',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                subtitle: Text(
                  _formattedDate(),
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
                trailing: const Icon(Icons.calendar_today, color: Colors.white70),
                onTap: _selectDateTime,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: _isSaving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.save),
                  label: Text(
                    _isSaving ? 'Guardando...' : 'Guardar Cambios',
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                  onPressed: _isSaving ? null : _savePlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
