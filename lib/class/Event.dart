import 'package:intl/intl.dart';

class Event {
  final int id; // Identificador único del evento
  final String title; // Título del evento
  final String description; // Descripción del evento
  final String fecha;
  final String startTime; // Fecha y hora de inicio del evento en formato ISO 8601
  final String? endTime; // Fecha y hora de fin del evento en formato ISO 8601 (opcional)
   bool leido;
   bool isCompleted; // Estado de completado del evento
  String actividadId;
  final String? lastModified;


  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.fecha,
    this.endTime,
    required this.leido,
    required this.isCompleted,
    required this.actividadId,
    this.lastModified
  });

  // Método para crear una instancia de Event a partir de un JSON
  factory Event.fromJson(Map<String, dynamic> json) {
    String fechaConvertida = json['fecha'] != null
        ? DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(json['fecha']))
        : DateFormat('yyyy-MM-dd').format(DateTime.now());


    return Event(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['descripcion'] ?? '',
      fecha: fechaConvertida,
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      isCompleted: json['completed'] as bool,
      leido: json['leido'] as bool,
      actividadId: json['actividadid'] ?? '',
    );
  }

  // Método para convertir una instancia de Event a un JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'descripcion': description,
      'fecha': fecha,
      'startTime': startTime,
      'endTime': endTime,
      'completed': isCompleted,
      'leido': leido,
      'actividadid':actividadId,
      'lastModified': lastModified
    };
  }


}
