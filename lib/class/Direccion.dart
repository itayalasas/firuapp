
import 'Calle.dart';
import 'Departamento.dart';
import 'Localidad.dart';
import 'Numero.dart';

class Direccion {

  Departamento departamento;
  Localidad localidad;
  Calle calle;
  Numero numero;
  int codigoPostal;
  int codigoPostalAmpliado;
  double puntoX;
  double puntoY;
  int idPunto;
  int srid;
  int idTipoClasificacion;
  String? error;

  Direccion({
    required this.departamento,
    required this.localidad,
    required this.calle,
    required this.numero,
    required this.codigoPostal,
    required this.codigoPostalAmpliado,
    required this.puntoX,
    required this.puntoY,
    required this.idPunto,
    required this.srid,
    required this.idTipoClasificacion,
    this.error,
  });


  factory Direccion.fromJson(Map<String, dynamic> json) {
    return Direccion(
      departamento: Departamento.fromJson(json['direccion']['departamento'] ?? {}),
      localidad: Localidad.fromJson(json['direccion']['localidad'] ?? {}),
      calle: Calle.fromJson(json['direccion']['calle'] ?? {}),
      numero: Numero.fromJson(json['direccion']['numero'] ?? {}),
      codigoPostal: json['codigoPostal'] ?? 0,
      codigoPostalAmpliado: json['codigoPostalAmpliado']  ?? 0,
      puntoX: json['puntoX']  ?? 0.0,
      puntoY: json['puntoY'] ?? 0.0,
      idPunto: json['idPunto']  ?? 0,
      srid: json['srid']  ?? 0,
      idTipoClasificacion: json['idTipoClasificacion']  ?? 0,
      error: json['error']  ?? '',
    );
  }
}