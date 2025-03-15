
import 'package:intl/intl.dart';

import 'Mascota.dart';
import 'User.dart';

class ActivityBussines {
  final String id;
  final String actividad;
  final String descripcion;
  final int tiempo;
  final double precio;
  late final int turnos;
  final String status;

  ActivityBussines({
    required this.id,
    required this.actividad,
    required this.descripcion,
    required this.tiempo,
    required this.precio,
    required this.status,
    required this.turnos,
  });

  factory ActivityBussines.fromJson(Map<String, dynamic> json) {
    return ActivityBussines(
      id: json['id'] ?? '',
      actividad: json['actividad'] ?? '',
      descripcion: json['descripcion']  ?? '',
      tiempo: json['tiempo']  ?? 0,
      precio:json['precio'] ?? 0.0,
      status: json['status']  ?? '',
      turnos: json['turnos']  ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'actividad':actividad,
      'descripcion': descripcion,
      'tiempo': tiempo,
      'precio': precio,
      'status': status,
      'turnos': turnos,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ActivityBussines &&
        other.actividad == actividad &&
        other.descripcion == descripcion;
  }

  @override
  int get hashCode => actividad.hashCode ^ descripcion.hashCode;
}