import 'package:cloud_firestore/cloud_firestore.dart';

class PlanModel {
  final String id;
  final String creatorId;
  final String titulo;
  final String descripcion;
  final DateTime? fecha;
  final String ubicacion;
  final bool privado;  // nuevo campo

  PlanModel({
    required this.id,
    required this.creatorId,
    required this.titulo,
    required this.descripcion,
    this.fecha,
    required this.ubicacion,
    this.privado = false,  // valor por defecto
  });

  /// Crea un objeto PlanModel desde un DocumentSnapshot de Firestore
  factory PlanModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PlanModel(
      id: doc.id,
      creatorId: data['creatorId'] ?? '',
      titulo: data['titulo'] ?? '',
      descripcion: data['descripcion'] ?? '',
      fecha: data['fecha'] != null
          ? (data['fecha'] as Timestamp).toDate()
          : null,
      ubicacion: data['ubicacion'] ?? '',
      privado: data['privado'] ?? false,  // leer campo privado
    );
  }

  /// Convierte el objeto PlanModel a un Map para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'creatorId': creatorId,
      'titulo': titulo,
      'descripcion': descripcion,
      'fecha': fecha != null ? Timestamp.fromDate(fecha!) : null,
      'ubicacion': ubicacion,
      'privado': privado,  // guardar campo privado
    };
  }

  /// Permite crear una copia modificada del objeto (útil en edición)
  PlanModel copyWith({
    String? id,
    String? creatorId,
    String? titulo,
    String? descripcion,
    DateTime? fecha,
    String? ubicacion,
    bool? privado,  // también aquí
  }) {
    return PlanModel(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      fecha: fecha ?? this.fecha,
      ubicacion: ubicacion ?? this.ubicacion,
      privado: privado ?? this.privado,
    );
  }
}
