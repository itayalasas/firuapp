import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';

import 'Mascota.dart';

class Comportamientos {
  final String tipoMascota;
  final String comportamiento;
  final String descripcion;
  final int codigoModelo;



  Comportamientos({
    required this.tipoMascota,
    required this.comportamiento,
    required this.descripcion,
    required this.codigoModelo,

  });

  // Método para crear una instancia de Event a partir de un JSON
  factory Comportamientos.fromJson(Map<String, dynamic> json) {


    return Comportamientos(
      tipoMascota: json['tipoMascota'] ?? '',
      comportamiento: json['comportamiento'] ?? '',
        descripcion: json['descripcion'] ?? '',
      codigoModelo: json['codigoModelo'] ?? 0

    );
  }

  // Método para convertir una instancia de Event a un JSON
  Map<String, dynamic> toJson() {
    return {
      'tipoMascota': tipoMascota,
      'comportamiento': comportamiento,
      'descripcion': descripcion,
      'codigoModelo': codigoModelo,

    };
  }


}


@JsonSerializable()
class ComportamientosMascota {
  final int? id;
  final String idmascota;

  @JsonKey(ignore: true) // ❌ Evita la referencia circular
  final Mascota? mascota;
  final String comportamiento;

  ComportamientosMascota({
     this.id,
    required this.idmascota,
     this.mascota,
    required this.comportamiento,
});

  factory ComportamientosMascota.fromJson(Map<String, dynamic> json) {
    return ComportamientosMascota(
      id: json['id'] ?? 0,
      idmascota: json['idmascota'] ?? '',
      mascota: Mascota.fromJson(json['mascota'] ??{}) ,
      comportamiento: json['comportamiento'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
       'id': id,
      //'mascota':mascota,
       'idmascota':idmascota,
      'comportamiento':comportamiento,

    };
  }
}