import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';

import 'Mascota.dart';

@JsonSerializable()
class NecesidadEspecialMascota {
  final int? id;
  final String idmascota;
  @JsonKey(ignore: true) // ❌ Evita la referencia circular
  final Mascota? mascota;
  final String necesidad;



  NecesidadEspecialMascota({
     this.id,
    required this.idmascota,
     this.mascota,
    required this.necesidad,

  });

  // Método para crear una instancia de Event a partir de un JSON
  factory NecesidadEspecialMascota.fromJson(Map<String, dynamic> json) {


    return NecesidadEspecialMascota(
      id: json['id'] ?? 0,
      idmascota: json['idmascota'] ?? '',
      mascota: Mascota.fromJson(json['mascota'] ??{}) ,
      necesidad: json['necesidad'] ?? '',

    );
  }

  // Método para convertir una instancia de Event a un JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      //'mascota': mascota,
      'idmascota':idmascota,
      'necesidad': necesidad,

    };
  }


}
