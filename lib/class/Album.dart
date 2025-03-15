import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'Mascota.dart';
class Album {
  String albumId;
  String name;
  String mascotaId;
  Timestamp createdTo;
  bool isCompartido;
  bool isSelected;

  Album({
    required this.albumId,
    required this.name,
    required this.mascotaId,
    required this.createdTo,
    this.isCompartido = false,
    this.isSelected=false,
  });

  // Convertir a JSON para Firestore
  Map<String, dynamic> toJson() {
    return {
      'albumId': albumId,
      'name': name,
      'mascotaId': mascotaId,
      'createdTo': createdTo,
      'isCompartido': isCompartido,
      'isSelected': isSelected, // Agrega el campo 'isSelected'
    };
  }

  // Crear un objeto desde un documento Firestore
  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      albumId: json['albumId'],
      name: json['name'],
      mascotaId: json['mascotaId'],
      createdTo: json['createdTo'],
      isCompartido: json['isCompartido'] ?? false,
      isSelected: json['isSelected'] ?? false, // Lee el campo 'isSelected']
    );
  }
}


class Photo {
  String photoId;      // ID único generado automáticamente (UUID)
  String albumId;      // ID del álbum al que pertenece la foto
  String photoUrl;     // URL de Firebase Storage donde está la foto
  String mediaType;    // 'image' o 'video'
  int likeCount;       // Cantidad de "me gusta"
  Timestamp createdAt; // Fecha de creación en Firestore

  Photo({
    required this.photoId,
    required this.albumId,
    required this.photoUrl,
    required this.mediaType,
    required this.likeCount,
    required this.createdAt,
  });

  /// 🔹 **Crear una instancia desde JSON (para obtener datos de Firestore)**
  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      photoId: json['photoId'] ?? Uuid().v4(), // Genera un UUID si es nulo
      albumId: json['albumId'],
      photoUrl: json['photoUrl'],
      mediaType: json['mediaType'],
      likeCount: json['likeCount'] ?? 0, // Si no existe, inicializa en 0
      createdAt: json['createdAt'] ?? Timestamp.now(), // Si no existe, usa fecha actual
    );
  }

  /// 🔹 **Convertir a JSON (para guardar en Firestore)**
  Map<String, dynamic> toJson() {
    return {
      'photoId': photoId,
      'albumId': albumId,
      'photoUrl': photoUrl,
      'mediaType': mediaType,
      'likeCount': likeCount,
      'createdAt': createdAt,
    };
  }

  /// 🔹 **Guardar en Firestore**
  Future<void> saveToFirestore() async {
    await FirebaseFirestore.instance.collection('photos').doc(photoId).set(toJson());
  }

  /// 🔹 **Eliminar de Firestore**
  Future<void> deleteFromFirestore() async {
    await FirebaseFirestore.instance.collection('photos').doc(photoId).delete();
  }
}
