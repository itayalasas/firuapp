import 'package:PetCare/class/NecesidadEspecial.dart';
import 'package:json_annotation/json_annotation.dart';
import 'User.dart';
import 'Vacunas.dart';
import 'PesoMascota.dart';
import 'Event.dart';
import 'MascotaAddress.dart';
import 'Comportamientos.dart';
import 'NecesidadesEspecialesMascota.dart';

@JsonSerializable(explicitToJson: true)
class Mascota {
  final String mascotaid;
  late  String nombre;
  final String especie;
  late  String raza;
  late final int? edad;
  late  String? genero;
  late  String? color;
  late  String? tamano;
  late  String? personalidad;
  late  String? historialMedico;
  final String fotos;
  late  String? fechaNacimiento;
  late  List<Vacunas>? vacunas;
  late  List<PesoMascota>? peso;
  final bool isSelected;
  final bool reservedTime;
  final double? servicePrice;
  final String? actividadId;
  late  List<Event>? eventos;
  late  String? microchip;
  late  DateTime? fechaRegistroChip;
  final MascotaAddress? direccion;
  late  String? castrado;
  late  List<Comportamientos>? comportamientosMascota;
  late  List<NecesidadEspecial>? necesidadMascota;

  Mascota({
    required this.mascotaid,
    required this.nombre,
    required this.especie,
    required this.raza,
    this.edad,
    this.genero,
    this.color,
    this.tamano,
    this.personalidad,
    this.historialMedico,
    required this.fotos,
    this.vacunas = const [],  // 🔹 Inicializar con una lista vacía en lugar de null
    this.peso = const [],
    this.fechaNacimiento,
    required this.isSelected,
    required this.reservedTime,
    this.servicePrice,
    this.actividadId,
    this.eventos = const [],
    this.microchip,
    this.fechaRegistroChip,
    this.direccion,
    this.castrado,
    this.comportamientosMascota = const [],
    this.necesidadMascota = const [],
  });

  /// **🔹 Método para convertir desde JSON (Firebase)**
  factory Mascota.fromJson(Map<String, dynamic> json) {
    return Mascota(
      mascotaid: json['mascotaid'] ?? '',
      nombre: json['nombre'] ?? '',
      especie: json['especie'] ?? '',
      raza: json['raza'] ?? '',
      edad: json['edad'] ?? 0,
      genero: json['genero'] ?? '',
      color: json['color'] ?? '',
      tamano: json['tamano'] ?? '',
      personalidad: json['personalidad'] ?? '',
      historialMedico: json['historialMedico'] ?? '',
      fotos: json['fotos'] ?? '',
      fechaNacimiento: json['fechaNacimiento'] ?? '',

      vacunas: (json['vacunas'] as List<dynamic>?)
          ?.map((v) => Vacunas.fromJson(v as Map<String, dynamic>))
          .toList(),
      peso: (json['peso'] as List<dynamic>?)
          ?.map((p) => PesoMascota.fromJson(p as Map<String, dynamic>))
          .toList(),
      eventos: (json['eventos'] as List<dynamic>?)
          ?.map((e) => Event.fromJson(e as Map<String, dynamic>))
          .toList(),
      comportamientosMascota: (json['comportamientosMascota'] as List<dynamic>?)
          ?.map((c) => Comportamientos.fromJson(c as Map<String, dynamic>))
          .toList(),
      necesidadMascota: (json['necesidadMascota'] as List<dynamic>?)
          ?.map((n) => NecesidadEspecial.fromJson(n as Map<String, dynamic>))
          .toList(),

      isSelected: json['isSelected'] ?? false,
      reservedTime: json['reservedTime'] ?? false,
      microchip: json['microchip'] ?? '',
      fechaRegistroChip: json['fechaRegistroChip'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['fechaRegistroChip'])
          : null,
      direccion: json['direccion'] != null
          ? MascotaAddress.fromJson(json['direccion'] as Map<String, dynamic>)
          : null,
      castrado: json['castrado'] ?? '',
    );
  }

  /// **🔹 Método para convertir a JSON (para Firebase)**
  Map<String, dynamic> toJson() {
    return {
      'mascotaid': mascotaid,
      'nombre': nombre,
      'especie': especie,
      'raza': raza,
      'edad': edad,
      'genero': genero,
      'color': color,
      'tamano': tamano,
      'personalidad': personalidad,
      'historialMedico': historialMedico,
      'fotos': fotos,
      'fechaNacimiento': fechaNacimiento,

      'vacunas': vacunas?.map((v) => v.toJson()).toList(),
      'peso': peso?.map((p) => p.toJson()).toList(),
      'eventos': eventos?.map((e) => e.toJson()).toList(),
      'comportamientosMascota': comportamientosMascota?.map((c) => c.toJson()).toList(),
      'necesidadMascota': necesidadMascota?.map((n) => n.toJson()).toList(),

      'isSelected': isSelected,
      'reservedTime': reservedTime,
      'microchip': microchip,
      'fechaRegistroChip': fechaRegistroChip?.millisecondsSinceEpoch,
      'direccion': direccion?.toJson(),
      'castrado': castrado,
    };
  }
}
