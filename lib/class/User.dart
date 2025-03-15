import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'Mascota.dart';
import 'UserRoles.dart';

class User {
  late String userId;
  late String firebaseUid;
  late String name;
  late String? phone;
  late int state;
  late String photo;
  late String username;
  late DateTime? deletedDate;
  late  List<Mascota>? mascotas;
  late String? documento;
  late String? fcmToken;
  late List<Perfil> perfil;

  User({
    required this.userId,
    required this.name,
    this.phone,
    required this.firebaseUid,
    required this.state,
    required this.username,
    this.deletedDate,
    required this.photo,
    this.mascotas,
    this.documento,
    required this.fcmToken,
    required this.perfil,
  });

  /// **🔹 Convertir desde Firestore (DocumentSnapshot)**
  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return User(
      userId: doc.id, // Se usa el ID del documento en Firestore
      firebaseUid: data['firebaseUid'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      state: data['state'] ?? 0,
      username: data['username'] ?? '',
      photo: data['photo'] ?? '',
      deletedDate: data['deletedDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['deletedDate'])
          : null,
      documento: data['documento'] ?? '',
      fcmToken: data['fcmToken'] ?? '',
      perfil: (data['perfil'] as List<dynamic>? ?? [])
          .map((i) => Perfil.fromJson(i as Map<String, dynamic>))
          .toList(),
      mascotas: [], // Se cargará después en otro método
    );
  }

  /// **🔹 Convertir a Firestore**
  Map<String, dynamic> toFirestore() {
    return {
      'firebaseUid': firebaseUid,
      'name': name,
      'phone': phone,
      'state': state,
      'photo': photo,
      'username': username,
      'deletedDate': deletedDate?.millisecondsSinceEpoch,
      'documento': documento,
      'fcToken': fcmToken,
      'perfil': perfil.map((p) => p.toJson()).toList(),
    };
  }

  /// **🔹 Método para cargar las `mascotas` desde la subcolección**
  static Future<List<Mascota>> fetchMascotas(String userId) async {
    try {
      QuerySnapshot mascotasSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('mascotas')
          .get();

      return mascotasSnapshot.docs
          .map((doc) => Mascota.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print("Error al obtener mascotas: $e");
      return [];
    }
  }
}
