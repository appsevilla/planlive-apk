class UserModel {
  final String uid;
  final String nombre;
  final String apellidos;
  final String ciudad;
  final String aficion;
  final int? edad;
  final String email;

  UserModel({
    required this.uid,
    required this.nombre,
    required this.apellidos,
    required this.ciudad,
    required this.aficion,
    this.edad,
    required this.email,
  });

  /// Construye un UserModel desde un [Map] y el uid del documento
  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      nombre: map['nombre'] ?? '',
      apellidos: map['apellidos'] ?? '',
      ciudad: map['ciudad'] ?? '',
      aficion: map['aficion'] ?? '',
      edad: map['edad'] != null ? int.tryParse(map['edad'].toString()) : null,
      email: map['email'] ?? '',
    );
  }

  /// Convierte el modelo a un [Map] para subirlo a Firestore
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'apellidos': apellidos,
      'ciudad': ciudad,
      'aficion': aficion,
      'edad': edad,
      'email': email,
    };
  }

  /// Crea una copia del modelo con campos opcionales actualizados
  UserModel copyWith({
    String? uid,
    String? nombre,
    String? apellidos,
    String? ciudad,
    String? aficion,
    int? edad,
    String? email,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      nombre: nombre ?? this.nombre,
      apellidos: apellidos ?? this.apellidos,
      ciudad: ciudad ?? this.ciudad,
      aficion: aficion ?? this.aficion,
      edad: edad ?? this.edad,
      email: email ?? this.email,
    );
  }
}
