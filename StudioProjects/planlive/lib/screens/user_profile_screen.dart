import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String? _name, _surname, _city, _hobby, _imageUrl;
  int? _age;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _name = data['name'] ?? '';
          _surname = data['surname'] ?? '';
          _city = data['city'] ?? '';
          _hobby = data['hobby'] ?? '';
          _age = data['age'] is int
              ? data['age']
              : int.tryParse(data['age']?.toString() ?? '');
          _imageUrl = data['imagen'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontraron datos del perfil.')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar el perfil: $e')),
      );
    }
  }

  Future<void> _goToEditProfile() async {
    final result = await Navigator.of(context).pushNamed('/edit_profile');
    if (result == true && mounted) {
      setState(() => _isLoading = true);
      _loadUserData();
    }
  }

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Se envió el correo para cambiar la contraseña.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar el correo de restablecimiento: $e')),
      );
    }
  }

  Widget _buildProfileDetail(String label, String? value, IconData icon) {
    return Card(
      color: const Color(0xFF1D1E33),
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurpleAccent),
        title: Text(
          label,
          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          value?.isNotEmpty == true ? value! : 'No especificado',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Volver a Explorar',
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          },
        ),
        title: const Text(
          'Perfil',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
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
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.lock_reset, color: Colors.white),
                    tooltip: 'Cambiar contraseña',
                    onPressed: _changePassword,
                  ),
                ),
                CircleAvatar(
                  radius: 70,
                  backgroundImage: (_imageUrl != null && _imageUrl!.isNotEmpty)
                      ? NetworkImage(_imageUrl!)
                      : const AssetImage('assets/images/curro.jpg') as ImageProvider,
                  backgroundColor: Colors.grey[700],
                ),
                const SizedBox(height: 20),
                Text(
                  '${_name ?? ''} ${_surname ?? ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                _buildProfileDetail('Ciudad', _city, Icons.location_city),
                _buildProfileDetail('Afición', _hobby, Icons.favorite),
                _buildProfileDetail('Edad', _age?.toString(), Icons.cake),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _goToEditProfile,
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar perfil'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

