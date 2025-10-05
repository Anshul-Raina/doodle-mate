import 'dart:ui';

class DrawingStroke {
  final String id;
  final String userId;
  final Color color;
  final double width;
  final List<Offset> points;
  final bool deleted;
  final DateTime timestamp;

  DrawingStroke({
    required this.id,
    required this.userId,
    required this.color,
    required this.width,
    required this.points,
    this.deleted = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  DrawingStroke copyWith({
    String? id,
    String? userId,
    Color? color,
    double? width,
    List<Offset>? points,
    bool? deleted,
    DateTime? timestamp,
  }) {
    return DrawingStroke(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      color: color ?? this.color,
      width: width ?? this.width,
      points: points ?? this.points,
      deleted: deleted ?? this.deleted,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'color': color.value,
      'width': width,
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'deleted': deleted,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory DrawingStroke.fromJson(Map<String, dynamic> json) {
    return DrawingStroke(
      id: json['id'],
      userId: json['userId'],
      color: Color(json['color']),
      width: json['width'].toDouble(),
      points: (json['points'] as List)
          .map((p) => Offset(p['x'].toDouble(), p['y'].toDouble()))
          .toList(),
      deleted: json['deleted'] ?? false,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    );
  }
}