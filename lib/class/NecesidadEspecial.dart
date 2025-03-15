import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';

import 'Mascota.dart';

class NecesidadEspecial {
  final String tipoMascota;
  final String necesidadEspecial;
  final String descripcion;
  final int codigoModelo;




  NecesidadEspecial({
    required this.tipoMascota,
    required this.necesidadEspecial,
    required this.descripcion,
    required this.codigoModelo

  });

  // Método para crear una instancia de Event a partir de un JSON
  factory NecesidadEspecial.fromJson(Map<String, dynamic> json) {


    return NecesidadEspecial(
      tipoMascota: json['tipoMascota'] ?? '',
        necesidadEspecial: json['necesidadEspecial'] ?? '',
        descripcion: json['descripcion'] ?? '',
        codigoModelo: json['codigoModelo'] ?? 0

    );
  }

  // Método para convertir una instancia de Event a un JSON
  Map<String, dynamic> toJson() {
    return {
      'tipoMascota': tipoMascota,
      'necesidadEspecial': necesidadEspecial,
      'descripcion': descripcion,
      'codigoModelo': codigoModelo

    };
  }


}
