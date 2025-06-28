import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Usuario actual
  User? get currentUser => _auth.currentUser;

  /// Escucha los cambios de estado de autenticación
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Inicia sesión con correo y contraseña
  Future<User?> signIn({required String email, required String password}) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user != null && cred.user!.emailVerified) {
        return cred.user;
      } else {
        // Si el usuario no ha verificado su correo, cerrar sesión por seguridad
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'El correo no ha sido verificado. Revisa tu bandeja de entrada.',
        );
      }
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Registra un nuevo usuario
  Future<User?> register({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await cred.user?.sendEmailVerification();
      return cred.user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Cierra la sesión del usuario actual
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Envía un correo para restablecer la contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: e.message ?? 'Error al enviar el correo de recuperación.',
      );
    }
  }

  /// Verifica si el correo fue verificado
  Future<bool> isEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }
}
