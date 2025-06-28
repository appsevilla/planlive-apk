import 'package:cloud_firestore/cloud_firestore.dart';

class PlanModel {
  final String titulo;
  final String descripcion;
  final String ubicacion;
  final DateTime? fecha;
  final String? nombreCreador;
  final bool privado;  // Nuevo campo

  PlanModel({
    required this.titulo,
    required this.descripcion,
    required this.ubicacion,
    this.fecha,
    this.nombreCreador,
    this.privado = false,  // valor por defecto
  });

  factory PlanModel.fromMap(Map<String, dynamic> map) {
    return PlanModel(
      titulo: map['titulo'] ?? '',
      descripcion: map['descripcion'] ?? '',
      ubicacion: map['ubicacion'] ?? '',
      fecha: map['fechaHora'] != null
          ? (map['fechaHora'] as Timestamp).toDate()
          : null,
      nombreCreador: map['nombreCreador'] ?? '',
      privado: map['privado'] ?? false,  // leer campo privado
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'ubicacion': ubicacion,
      'fechaHora': fecha != null ? Timestamp.fromDate(fecha!) : null,
      'nombreCreador': nombreCreador,
      'privado': privado,  // guardar campo privado
    };
  }
}
