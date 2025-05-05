import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'ActividadNegocio.dart';

class Business {
  final String id;
  final String name;
  final String? rut;
  final String phone;
  final String longitud;
  final String latitud;
  final DateTime createdAt;
  final String address;
  final String logoUrl;
  final double rating;
  final String userid;
  final List<ActivityBussines>? services;
  final int reviewCount;
  List<Negocio> negocios; // Nueva propiedad para almacenar negocios


  Business({
    required this.id,
    required this.name,
    required this.phone,
    this.rut,
    required this.createdAt,
    required this.longitud,
    required this.latitud,
    required this.address,
    required this.logoUrl,
    required this.rating,
    required this.userid,
    this.services,
    required this.reviewCount,
    List<Negocio>? negocios,
  }): negocios = negocios ?? [];

  /// **🔹 Convertir desde Firestore (DocumentSnapshot)**
  factory Business.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Business(
      id: doc.id,
      name: data['name'] ?? '',
      rut: data['rut'] ?? '',
      phone: data['phone'] ?? '',
      longitud: data['longitud'] ?? '',
      latitud: data['latitud'] ?? '',
      address: data['address'] ?? '',
      logoUrl: data['logoUrl'] ?? '',
      rating: (data['averageRating'] != null) ? (data['averageRating'] as num).toDouble() : 0.0,
      userid: data['userid'] ?? '',
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      reviewCount: data['reviewCount'] ?? 0,
      services: (data['activity'] as List<dynamic>?)
          ?.map((service) => ActivityBussines.fromJson(service as Map<String, dynamic>))
          .toList(),
      negocios: [], // Se inicializa vacía, pero se llenará después con `getNegociosByBusinessId`

    );
  }

  /// **🔹 Convertir a Firestore**
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'rut': rut,
      'phone': phone,
      'address': address,
      'longitud': longitud,
      'latitud': latitud,
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewCount': reviewCount,
      'logoUrl': logoUrl,
      'averageRating': rating,
      'userid': userid,
      'activity': services?.map((service) => service.toJson()).toList(),
    };
  }

  /// Crea la instancia de Business y luego carga la subcolección 'negocios'
  static Future<Business> fromFirestoreWithNegocios(DocumentSnapshot doc) async {
    // Primero crea el Business básico
    final business = Business.fromFirestore(doc);

    // Ahora carga los documentos de la subcolección 'negocios'
    final snapshot = await doc.reference
        .collection('negocios')
        .get();

    // Transforma cada documento en un Negocio y lo asigna
    business.negocios = snapshot.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      return Negocio.fromFirestore(data);
    }).toList();

    return business;
  }

}

class Negocio {
  final int id;
  final String descripcion;
  final String foto;
  final DateTime? assignedAt;
  final List<Actividad> actividades; // 🔹 Lista de actividades asociadas

  Negocio({
    required this.id,
    required this.descripcion,
    required this.foto,
    this.assignedAt,
    this.actividades = const [], // 🔹 Inicializa con una lista vacía
  });

  factory Negocio.fromJson(Map<String, dynamic> json) {
    return Negocio(
      id: json['id'] ?? 0,
      descripcion: json['descripcion'] ?? '',
      foto: json['foto'] ?? '',
      assignedAt: json['assigned_at'] != null
          ? (json['assigned_at'] as Timestamp).toDate()
          : null,
    );
  }

  factory Negocio.fromFirestore(Map<String, dynamic> json) {
    return Negocio(
      id: json['id'] ?? 0,
      descripcion: json['descripcion'] ?? '',
      foto: json['foto'],
      assignedAt: json['assigned_at'] != null
          ? (json['assigned_at'] as Timestamp).toDate()
          : null,
    );
  }
}


class Actividad {
  final int id;
  final String actividad;
  final int negocioId;
  final String status;

  Actividad({
    required this.id,
    required this.actividad,
    required this.negocioId,
    required this.status,
  });

  // 🔹 Convertir un documento Firestore a un objeto Actividad
  factory Actividad.fromJson(Map<String, dynamic> json) {
    return Actividad(
      id: json['id'] ?? 0,
      actividad: json['actividad'] ?? '',
      negocioId: json['negocioId'] ?? 0,
      status: json['status'] ?? 'Disponible', // Estado por defecto
    );
  }

  // 🔹 Convertir un objeto Actividad a un Map para Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'actividad': actividad,
      'negocioId': negocioId,
      'status': status,
    };
  }
}


