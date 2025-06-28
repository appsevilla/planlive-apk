import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Importa aquí tu BackgroundScaffold
import '../widgets/background_scaffold.dart';

enum AuthMode { login, register }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  AuthMode _mode = AuthMode.login;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveFcmTokenToFirestore(String uid) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'fcmToken': fcmToken,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error guardando token FCM: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final auth = FirebaseAuth.instance;

      if (_mode == AuthMode.login) {
        final userCredential = await auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passController.text.trim(),
        );
        await _saveFcmTokenToFirestore(userCredential.user!.uid);
      } else {
        final cred = await auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passController.text.trim(),
        );

        await cred.user!.updateDisplayName(_nameController.text.trim());

        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'nombre': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'provider': 'email',
          'uid': cred.user!.uid,
        });

        await _saveFcmTokenToFirestore(cred.user!.uid);
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'user-not-found' => 'Usuario no encontrado',
        'wrong-password' => 'Contraseña incorrecta',
        'email-already-in-use' => 'El correo ya está en uso',
        'weak-password' => 'La contraseña es muy débil',
        'invalid-email' => 'Correo electrónico inválido',
        _ => 'Error de autenticación',
      };

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocurrió un error inesperado')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null && userCredential.additionalUserInfo?.isNewUser == true) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'nombre': user.displayName ?? '',
          'email': user.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'provider': 'google',
          'uid': user.uid,
        });
      }

      if (user != null) {
        await _saveFcmTokenToFirestore(user.uid);
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al iniciar sesión con Google')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = _mode == AuthMode.login;

    return BackgroundScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(isLogin ? 'Iniciar sesión' : 'Registrarse'),
        centerTitle: true,
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                if (!isLogin)
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Ingresa tu nombre' : null,
                  ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Correo electrónico'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                  value == null || !value.contains('@') ? 'Correo inválido' : null,
                ),
                TextFormField(
                  controller: _passController,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                  validator: (value) =>
                  value == null || value.length < 6 ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 20),
                if (_isLoading)
                  const CircularProgressIndicator()
                else ...[
                  ElevatedButton(
                    onPressed: _submit,
                    child: Text(isLogin ? 'Iniciar sesión' : 'Registrarse'),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.login),
                    label: const Text('Iniciar con Google'),
                    onPressed: _signInWithGoogle,
                  ),
                ],
                TextButton(
                  onPressed: () {
                    setState(() {
                      _mode = isLogin ? AuthMode.register : AuthMode.login;
                    });
                  },
                  child: Text(isLogin
                      ? '¿No tienes cuenta? Regístrate'
                      : '¿Ya tienes cuenta? Inicia sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

