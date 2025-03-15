import 'package:cloud_firestore/cloud_firestore.dart';


import '../class/Mascota.dart';
import '../class/PesoMascota.dart';
import '../class/Vacunas.dart';

class MascotaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// **🔹 Agregar una nueva mascota a Firestore**
  Future<void> addMascota(String userId, Mascota mascota) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('mascotas')
          .doc(mascota.mascotaid)
          .set(mascota.toJson());
    } catch (e) {
      print("Error al agregar mascota: $e");
      throw e;
    }
  }

  /// **🔹 Actualizar datos de una mascota en Firestore**
  Future<void> updateMascota(String userId, Mascota mascota) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('mascotas')
          .doc(mascota.mascotaid)
          .update(mascota.toJson());
    } catch (e) {
      print("Error al actualizar mascota: $e");
      throw e;
    }
  }

  /// **🔹 Eliminar una mascota de Firestore**
  Future<void> deleteMascota(String userId, String mascotaId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('mascotas')
          .doc(mascotaId)
          .delete();
    } catch (e) {
      print("Error al eliminar mascota: $e");
      throw e;
    }
  }

  /// **🔹 Agregar un peso a una mascota**
  Future<void> addPeso(String userId, String mascotaId, PesoMascota peso) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('mascotas')
          .doc(mascotaId)
          .collection('pesos')
          .doc(peso.pesoid)
          .set(peso.toJson());
    } catch (e) {
      print("Error al agregar peso: $e");
      throw e;
    }
  }

  /// **🔹 Obtener todos los pesos de una mascota**
  Future<List<PesoMascota>> getPesos(String userId, String mascotaId) async {
    try {
      QuerySnapshot pesosSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('mascotas')
          .doc(mascotaId)
          .collection('pesos')
          .orderBy('fecha', descending: true)
          .get();

      return pesosSnapshot.docs
          .map((doc) => PesoMascota.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print("Error al obtener pesos: $e");
      throw e;
    }
  }

  /// **🔹 Eliminar un peso registrado**
  Future<void> deletePeso(String userId, String mascotaId, String pesoId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('mascotas')
          .doc(mascotaId)
          .collection('pesos')
          .doc(pesoId)
          .delete();
    } catch (e) {
      print("Error al eliminar peso: $e");
      throw e;
    }
  }

  /// **🔹 Agregar una vacuna a una mascota**
  Future<void> addVacuna(String userId, String mascotaId, Vacunas vacuna) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('mascotas')
          .doc(mascotaId)
          .collection('vacunas')
          .doc(vacuna.vacunaid)
          .set(vacuna.toJson());
    } catch (e) {
      print("Error al agregar vacuna: $e");
      throw e;
    }
  }

  /// **🔹 Obtener todas las vacunas de una mascota**
  Future<List<Vacunas>> getVacunas(String userId, String mascotaId) async {
    try {
      QuerySnapshot vacunasSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('mascotas')
          .doc(mascotaId)
          .collection('vacunas')
          .orderBy('fechaAdministracion', descending: true)
          .get();

      return vacunasSnapshot.docs
          .map((doc) => Vacunas.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print("Error al obtener vacunas: $e");
      throw e;
    }
  }

  /// **🔹 Eliminar una vacuna registrada**
  Future<void> deleteVacuna(String userId, String mascotaId, String vacunaId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('mascotas')
          .doc(mascotaId)
          .collection('vacunas')
          .doc(vacunaId)
          .delete();
    } catch (e) {
      print("Error al eliminar vacuna: $e");
      throw e;
    }
  }

  ///** Metodo para obtener la lista de razas
  Future<List<String>> fetchRazas(String tipoMascota) async {
    try {
      // Referencia a la colección en Firestore
      CollectionReference razaCollection = FirebaseFirestore.instance.collection('tipo_raza');

      // Consulta filtrando por el tipo de mascota
      QuerySnapshot querySnapshot = await razaCollection.where('tipo', isEqualTo: tipoMascota).get();

      // Extraer los nombres de las razas y convertirlos en una lista de Strings
      List<String> razas = querySnapshot.docs.map((doc) {
        return doc['nombre'] as String;
      }).toList();

      print('✅ Razas obtenidas: $razas');
      return razas;
    } catch (e) {
      print('❌ Error al obtener razas: $e');
      return []; // Devolver una lista vacía en caso de error
    }
  }

}
