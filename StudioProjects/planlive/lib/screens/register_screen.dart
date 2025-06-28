import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _hobbyController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;

  Future<void> register() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final name = _nameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final city = _cityController.text.trim();
      final hobby = _hobbyController.text.trim();
      final age = int.tryParse(_ageController.text.trim()) ?? -1;

      if (email.isEmpty ||
          password.isEmpty ||
          name.isEmpty ||
          lastName.isEmpty ||
          city.isEmpty ||
          hobby.isEmpty ||
          age <= 0) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Por favor, complete todos los campos correctamente')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;

      if (user != null) {
        final fcmToken = await FirebaseMessaging.instance.getToken();

        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'name': name,
          'surname': lastName,
          'city': city,
          'hobby': hobby,
          'age': age,
          'createdAt': FieldValue.serverTimestamp(),
          'fcmToken': fcmToken ?? '',
          'imagen': '',
        });

        await user.sendEmailVerification();

        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Usuario registrado. Verifica tu correo electrónico.')),
        );

        if (mounted) {
          /// ✅ Usamos `pop(true)` en vez de `pushReplacementNamed(...)`
          Navigator.pop(context, true);
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Error al registrar el usuario.';
      if (e.code == 'email-already-in-use') {
        message = 'El correo ya está registrado.';
      } else if (e.code == 'weak-password') {
        message = 'La contraseña es muy débil.';
      } else if (e.code == 'invalid-email') {
        message = 'El correo es inválido.';
      }
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error inesperado: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _lastNameController.dispose();
    _cityController.dispose();
    _hobbyController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Correo electrónico'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña'),
              ),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Apellidos'),
              ),
              TextField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'Ciudad'),
              ),
              TextField(
                controller: _hobbyController,
                decoration: const InputDecoration(labelText: 'Hobby'),
              ),
              TextField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Edad'),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: register,
                child: const Text('Registrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
