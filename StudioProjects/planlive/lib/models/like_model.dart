class Like {
  final String userId;
  final DateTime fecha;

  Like({
    required this.userId,
    required this.fecha,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'fecha': fecha.toIso8601String(),
  };

  factory Like.fromJson(Map<String, dynamic> json) {
    return Like(
      userId: json['userId'],
      fecha: DateTime.parse(json['fecha']),
    );
  }
}
