import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart'; // Necesario para debugPrint

class UserService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Permite seleccionar una imagen desde la galería
  Future<File?> seleccionarImagen() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    return pickedFile != null ? File(pickedFile.path) : null;
  }

  /// Sube una imagen a Firebase Storage y retorna la URL
  Future<String?> subirImagen(File imagen, String uid) async {
    try {
      final String nombreArchivo = basename(imagen.path);
      final Reference ref = _storage.ref().child('users/$uid/$nombreArchivo');
      final UploadTask uploadTask = ref.putFile(imagen);
      await uploadTask;
      final String url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      debugPrint('❌ Error al subir imagen: $e');
      return null;
    }
  }
}
