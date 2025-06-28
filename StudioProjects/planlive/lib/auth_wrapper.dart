import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:planlive/screens/explore_screen.dart';


import 'screens/login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Muestra cargando mientras espera la conexión
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Maneja errores de la conexión
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Ocurrió un error al iniciar sesión.')),
          );
        }

        // Usuario autenticado y con email verificado (o debug mode)
        final user = snapshot.data;
        if (user != null && (user.emailVerified || kDebugMode)) {
          return const ExploreScreen();
        }

        // Usuario no autenticado o email no verificado
        return const LoginScreen();
      },
    );
  }
}
