class Comentario {
  final String id;
  final String autorId;
  final String autorNombre;
  final String contenido;
  final DateTime fecha;

  Comentario({
    required this.id,
    required this.autorId,
    required this.autorNombre,
    required this.contenido,
    required this.fecha,
  });

  Map<String, dynamic> toJson() => {
    'autorId': autorId,
    'autorNombre': autorNombre,
    'contenido': contenido,
    'fecha': fecha.toIso8601String(),
  };

  factory Comentario.fromJson(Map<String, dynamic> json, String id) {
    return Comentario(
      id: id,
      autorId: json['autorId'],
      autorNombre: json['autorNombre'],
      contenido: json['contenido'],
      fecha: DateTime.parse(json['fecha']),
    );
  }
}
