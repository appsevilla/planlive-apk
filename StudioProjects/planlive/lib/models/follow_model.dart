class Follow {
  final String userId;
  final DateTime fecha;

  Follow({
    required this.userId,
    required this.fecha,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'fecha': fecha.toIso8601String(),
  };

  factory Follow.fromJson(Map<String, dynamic> json) {
    return Follow(
      userId: json['userId'],
      fecha: DateTime.parse(json['fecha']),
    );
  }
}
