import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';


class Vacunas {
  final String vacunaid;
  final String mascotaid;
  final String nombreVacuna;
  final DateTime fechaAdministracion;
  final DateTime proximaFechaVacunacion;
  final String? veterinarioResponsable;
  final String? clinicaVeterinaria;
  final String loteVacuna;
  final String? observaciones;


  Vacunas({
    required this.vacunaid,
    required this.mascotaid,
    required this.nombreVacuna,
    required this.fechaAdministracion,
    required this.proximaFechaVacunacion,
    this.veterinarioResponsable,
    this.clinicaVeterinaria,
    required this.loteVacuna,
    this.observaciones,

  });

  factory Vacunas.fromJson(Map<String, dynamic> json) {
    return Vacunas(
      vacunaid: json['vacunaid'] ?? '',
      mascotaid: json['mascotaid'] ?? '',

      nombreVacuna: json['nombreVacuna'] ?? '',
      fechaAdministracion: _parseFecha(json['fechaAdministracion']),
      proximaFechaVacunacion: _parseFecha(json['proximaFechaVacunacion']),
      veterinarioResponsable: json['veterinarioResponsable'] ?? '',
      clinicaVeterinaria: json['clinicaVeterinaria'] ?? '',
      loteVacuna: json['loteVacuna'] ?? '',
      observaciones: json['observaciones'] ?? '',

    );
  }

  Map<String, dynamic> toJson() {
    final dateFormat = DateFormat('yyyy-MM-dd');
    return {
      'vacunaid': vacunaid,
      'mascotaid': mascotaid,
      'nombreVacuna': nombreVacuna,
      'fechaAdministracion': fechaAdministracion,
      'proximaFechaVacunacion': proximaFechaVacunacion,
      'veterinarioResponsable': veterinarioResponsable,
      'clinicaVeterinaria': clinicaVeterinaria,
      'loteVacuna': loteVacuna,
      'observaciones': observaciones,
    };
  }


// 🔹 Función auxiliar para convertir String/Timestamp a DateTime
  static DateTime _parseFecha(dynamic fecha) {
    if (fecha == null) {
      return DateTime(2000, 1, 1); // 🔹 Valor por defecto si no hay fecha
    } else if (fecha is String) {
      return DateTime.parse(fecha); // 🔹 Convierte String ISO a DateTime
    } else if (fecha is Timestamp) {
      return fecha.toDate(); // 🔹 Convierte Timestamp de Firestore a DateTime
    } else {
      throw Exception("Formato de fecha no compatible: $fecha");
    }
  }

}