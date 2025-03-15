import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'Mascota.dart';

class PesoMascota {
  final String pesoid;

  final DateTime fecha;
  final double peso;
  final String um;



  PesoMascota({
    required this.pesoid,

    required this.fecha,
    required this.peso,
    required this.um,

  });

  factory PesoMascota.fromJson(Map<String, dynamic> json) {
    return PesoMascota(
      pesoid: json['pesoid'] ?? '', // Proporciona un valor predeterminado si el valor es nulo

      fecha: json['fecha'] is Timestamp
          ? (json['fecha'] as Timestamp).toDate()  // ✅ Convierte correctamente
          : DateTime.now(),
      peso: (json['peso'] as num).toDouble(), // ✅ Evita errores de tipo
      um: json['um'] ?? '',



    );
  }

  Map<String, dynamic> toJson() {
    final dateFormat = DateFormat('yyyy-MM-dd');

    return {
      'pesoid': pesoid,

      'fecha': Timestamp.fromDate(fecha), // ✅ Convierte a Timestamp
      'peso': peso,
      'um': um,
    };
  }
}