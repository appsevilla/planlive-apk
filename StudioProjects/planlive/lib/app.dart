import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_database/firebase_database.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;
  bool isLoading = true;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _hobbyController = TextEditingController();
  final _photoUrlController = TextEditingController();

  File? _imageFile;

  @override
  void initState() {
    super.initState();
    if (user != null) _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        userData = doc.data();
        _nameController.text = userData?['nombre'] ?? '';
        _cityController.text = userData?['ciudad'] ?? '';
        _hobbyController.text = userData?['aficion'] ?? '';
        _photoUrlController.text = userData?['fotoUrl'] ?? '';
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar datos del perfil')),
      );
    }
    if (!mounted) return;
    setState(() => isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    String? uploadedUrl = _photoUrlController.text.trim();
    if (_imageFile != null) {
      final ref = FirebaseStorage.instance.ref().child('profile_photos/${user!.uid}.jpg');
      await ref.putFile(_imageFile!);
      uploadedUrl = await ref.getDownloadURL();
    }

    final dataToSave = {
      'nombre': _nameController.text.trim(),
      'ciudad': _cityController.text.trim(),
      'aficion': _hobbyController.text.trim(),
      'fotoUrl': uploadedUrl,
      'email': user!.email,
    };

    try {
      // Guardar en Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set(dataToSave, SetOptions(merge: true));

      // Guardar también en Firebase Realtime Database
      final dbRef = FirebaseDatabase.instance.ref().child('users/${user!.uid}');
      await dbRef.set(dataToSave);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar el perfil')),
      );
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _sendPasswordReset() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Correo de restablecimiento enviado')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo enviar el correo')),
      );
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _hobbyController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No hay usuario autenticado')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        leading: Navigator.canPop(context)
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        )
            : null,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : (_photoUrlController.text.isNotEmpty
                      ? NetworkImage(_photoUrlController.text)
                      : const AssetImage('assets/avatar_placeholder.png'))
                  as ImageProvider,
                ),
              ),
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Cambiar foto de perfil'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _photoUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL de foto de perfil (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'Nombre obligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Ciudad',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hobbyController,
                decoration: const InputDecoration(
                  labelText: 'Afición',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _saveProfile,
                icon: const Icon(Icons.save),
                label: const Text('Guardar perfil'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _sendPasswordReset,
                icon: const Icon(Icons.lock_reset),
                label: const Text('Cambiar contraseña'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
