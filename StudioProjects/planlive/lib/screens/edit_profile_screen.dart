import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _hobbyController = TextEditingController();
  final _edadController = TextEditingController();

  File? _imageFile;
  String? _profileImageUrl;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();

      if (data != null) {
        _nombreController.text = data['name'] ?? '';
        _apellidoController.text = data['surname'] ?? '';
        _ciudadController.text = data['city'] ?? '';
        _hobbyController.text = data['hobby'] ?? '';
        _edadController.text = data['age']?.toString() ?? '';
        _profileImageUrl = data['imagen'] ?? '';
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 75);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Seleccionar de galería'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    String? imageUrl = _profileImageUrl;

    try {
      if (_imageFile != null) {
        final ref = FirebaseStorage.instance.ref('users/${user.uid}/fotoPerfil.jpg');
        await ref.putFile(_imageFile!);
        imageUrl = await ref.getDownloadURL();
      }

      final edad = int.tryParse(_edadController.text.trim()) ?? 0;
      final fcmToken = await FirebaseMessaging.instance.getToken();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _nombreController.text.trim(),
        'surname': _apellidoController.text.trim(),
        'city': _ciudadController.text.trim(),
        'hobby': _hobbyController.text.trim(),
        'age': edad,
        'imagen': imageUrl ?? '',
        'token': fcmToken ?? '',
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Perfil actualizado')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: validator ??
              (value) =>
          value == null || value.trim().isEmpty ? 'Este campo es obligatorio' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageWidget = _imageFile != null
        ? FileImage(_imageFile!)
        : (_profileImageUrl?.isNotEmpty == true
        ? NetworkImage(_profileImageUrl!)
        : const AssetImage('assets/images/curro.jpg')) as ImageProvider;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(radius: 60, backgroundImage: imageWidget),
                  GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.camera_alt, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildTextField(label: 'Nombre', controller: _nombreController),
              const SizedBox(height: 16),
              _buildTextField(label: 'Apellido', controller: _apellidoController),
              const SizedBox(height: 16),
              _buildTextField(label: 'Ciudad', controller: _ciudadController),
              const SizedBox(height: 16),
              _buildTextField(label: 'Afición', controller: _hobbyController),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Edad',
                controller: _edadController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Edad requerida';
                  final num = int.tryParse(value.trim());
                  if (num == null || num <= 0) return 'Edad inválida';
                  return null;
                },
              ),
              const SizedBox(height: 30),
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
                    _isSaving ? 'Guardando...' : 'Guardar cambios',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveProfile,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
