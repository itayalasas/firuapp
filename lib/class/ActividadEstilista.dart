


import 'package:intl/intl.dart';

import 'Mascota.dart';
import 'User.dart';

class Activity {
  final String actividadid;
  final String mascotaid;
  final String title;
  final String description;
  final String startime;
  final String endtime;
  final double precio;
  final String fecha;
  final String status;
  final String? note;
  final String userid;
  final int turnos;

  Activity({
    required this.actividadid,
    required this.mascotaid,
    required this.userid,
    required this.title,
    required this.description,
    required this.startime,
    required this.endtime,
    required this.precio,
    required this.fecha,
    this.note,
    required this.status,
    required this.turnos,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    String fechaConvertida = json['fecha'] != null
        ? DateFormat('yyyy-MM-dd').format(
        DateTime.fromMillisecondsSinceEpoch(json['fecha']))
        : DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Activity(
      actividadid: json['actividadid'] ?? '',
      userid: json['usuario'] ?? '',
      mascotaid: json['mascotaid'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      startime: json['startime'] ?? '',
      endtime: json['endtime'] ?? '',
      precio: json['precio'] ?? 0.0,
      fecha: fechaConvertida,
      /*fecha: json['fecha'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['fecha'])
          : DateTime.now(),*/
      status: json['status'] ?? '',
      note: json['note'] ?? '',
      turnos: json['turnos'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    final dateFormat = DateFormat('yyyy-MM-dd');

    return {
      'actividadid': actividadid,
      'userid': userid,
      'mascotaid': mascotaid,
      'title': title,
      'description': description,
      'startime': startime,
      'endtime': endtime,
      'precio': precio,
      'fecha': fecha,
      'note': note,
      'status': status,
    };
  }

  Activity copyWith({
    String? actividadid,
    Mascota? mascota,
    String? title,
    String? description,
    String? startime,
    String? endtime,
    double? precio,
    String? fecha,
    String? status,
    String? note,
    User? user,
    int? turnos,
  }) {
    return Activity(
      actividadid: actividadid ?? this.actividadid,
      mascotaid: mascotaid ?? this.mascotaid,
      title: title ?? this.title,
      description: description ?? this.description,
      startime: startime ?? this.startime,
      endtime: endtime ?? this.endtime,
      precio: precio ?? this.precio,
      fecha: fecha ?? this.fecha,
      status: status ?? this.status,
      note: note ?? this.note,
      userid: userid ?? this.userid,
      turnos: turnos ?? this.turnos,
    );
  }
}

