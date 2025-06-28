import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _loading = false;
  String? _error;
  bool _showResendButton = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveUserDataAndToken(User user) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final fcmToken = await FirebaseMessaging.instance.getToken();

    final snapshot = await userDoc.get();
    if (!snapshot.exists) {
      await userDoc.set({
        'nombre': user.displayName?.split(' ').first ?? '',
        'apellidos': user.displayName?.split(' ').skip(1).join(' ') ?? '',
        'email': user.email ?? '',
        'uid': user.uid,
        'ciudad': '',
        'aficion': '',
        'edad': null,
        'fechaRegistro': Timestamp.now(),
        'fcmToken': fcmToken ?? '',
      });
    } else {
      await userDoc.update({'fcmToken': fcmToken ?? ''});
    }
  }

  Future<void> loginWithEmail() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Completa todos los campos.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _showResendButton = false;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      var user = FirebaseAuth.instance.currentUser;
      await user?.reload();
      user = FirebaseAuth.instance.currentUser;

      if (!mounted) return;

      if (user != null && !user.emailVerified) {
        await FirebaseAuth.instance.signOut();
        setState(() {
          _error = 'Verifica tu correo antes de ingresar.';
          _showResendButton = true;
        });
        return;
      }

      if (user != null) {
        await _saveUserDataAndToken(user);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/');
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No se encontró el usuario.';
          break;
        case 'wrong-password':
          message = 'Contraseña incorrecta.';
          break;
        case 'invalid-email':
          message = 'Correo no válido.';
          break;
        case 'too-many-requests':
          message = 'Demasiados intentos. Inténtalo más tarde.';
          break;
        default:
          message = 'Error al iniciar sesión: ${e.message}';
      }
      setState(() => _error = message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Error inesperado: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Correo de verificación reenviado.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al reenviar: ${e.toString()}')),
      );
    }
  }

  Future<void> loginWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        await _saveUserDataAndToken(user);
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Error al iniciar con Google: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void goToRegister() async {
    final result = await Navigator.pushNamed(context, '/register');
    if (!mounted) return;
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuenta creada. Verifica tu correo antes de iniciar sesión.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Iniciar sesión"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1D1E33), Color(0xFF111328)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Icon(Icons.lock_open_rounded, size: 72, color: Colors.white),
              const SizedBox(height: 24),
              TextField(
                controller: emailController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email, color: Colors.white),
                  labelStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock, color: Colors.white),
                  labelStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (_showResendButton)
                TextButton(
                  onPressed: resendVerificationEmail,
                  child: const Text(
                    'Reenviar correo de verificación',
                    style: TextStyle(color: Colors.lightBlueAccent),
                  ),
                ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: _loading ? null : loginWithEmail,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Text("Iniciar sesión"),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.g_mobiledata, size: 28),
                label: const Text("Iniciar con Google"),
                onPressed: _loading ? null : loginWithGoogle,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: goToRegister,
                child: const Text(
                  "¿No tienes cuenta? Regístrate",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
