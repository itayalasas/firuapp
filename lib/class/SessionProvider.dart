import 'package:PetCare/class/Comportamientos.dart';
import 'package:PetCare/class/Event.dart';
import 'package:PetCare/class/NecesidadEspecial.dart';
import 'package:PetCare/class/NecesidadesEspecialesMascota.dart';
import 'package:PetCare/class/PesoMascota.dart';
import 'package:PetCare/class/Vacunas.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

import 'Mascota.dart';
import 'Negocio.dart';
import 'User.dart';
import 'UserRoles.dart';

class SessionProvider extends  ChangeNotifier {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  bool isInitialized = false;
  bool _isLoggedIn = false;
  String? _token;
  fb.User? _firebaseUser;
  late User _userCustom; // Nuestra versión de User con más datos
  int? _rolAcceso; // Cambiado a String para coincidir con Firestore
  List<Mascota> _mascotas = [];
  Business? _business;
  List<Perfil> _perfil = [];
///Para monetizar
  bool _hasSubscription = false;
  bool get hasSubscription => _hasSubscription;
  ///


  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  fb.User? get firebaseUser => _firebaseUser;
  User? get user => _userCustom;
  int? get rolAcceso => _rolAcceso;
  List<Mascota> get mascotas => _mascotas;
  Business? get business => _business;
  List<Perfil> get perfil => _perfil;


  // Método para iniciar sesión con Firebase y recuperar datos del usuario
  Future<void> signIn(fb.UserCredential userCredential) async {
    _firebaseUser  = userCredential.user;
    _token = await _firebaseUser?.getIdToken();
    _isLoggedIn = true;

    if (_firebaseUser != null) {
      await _fetchUserData(_firebaseUser!.uid);
      _mascotas= await fetchMascotas(_firebaseUser!.uid); // Cargar mascotas al iniciar sesión
      // Guardar datos en SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', _firebaseUser!.uid);

      if (_rolAcceso != null) {
        await prefs.setInt('rolAcceso', _rolAcceso!);
      }

      await prefs.setBool('isLoggedIn', true);
    }
    await loadSession(); // Ahora sí cargamos la sesión

    notifyListeners();
  }

  Future<void> updateMascotaSession(String userId) async {

      _mascotas = await fetchMascotas(userId);


      notifyListeners();
  }



  Future<List<Mascota>> fetchMascotas(String userId) async {
    try {
      // 🔹 Obtener la colección de mascotas de Firestore
      QuerySnapshot mascotasSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('mascotas')
          .get();

      List<Mascota> mascotas = [];

      // 🔹 Recorrer cada documento de mascota y convertirlo en un objeto `Mascota`
      for (var doc in mascotasSnapshot.docs) {
        Map<String, dynamic> mascotaData = doc.data() as Map<String, dynamic>;
        String mascotaId = doc.id;

        print("🔍 Cargando datos de mascota: $mascotaId");

        // 🔹 Crear la instancia de `Mascota` usando `fromJson()`
        Mascota mascota = Mascota.fromJson(mascotaData);

        mascotas.add(mascota);
      }

      // 🔹 Notificar cambios en `SessionProvider` (si es necesario)
      notifyListeners();

      return mascotas;
    } catch (e) {
      print("❌ Error al obtener mascotas: $e");
      return [];
    }
  }


  // Ya tenés un getter; ahora agreguemos un método para recargarlo:
  Future<void> reloadBusiness() async {
    // Supongamos que tu negocio está en la colección 'businesses' y
    // tenés el ID guardado en sesión:
    final String negocioId = _business!.id;
    final doc = await FirebaseFirestore.instance
        .collection('businesses')
        .doc(negocioId)
        .get();
    _business = await Business.fromFirestoreWithNegocios(doc);
    notifyListeners();
  }

  /// **📌 Método genérico para obtener subcolecciones**
  Future<List<T>> _fetchSubCollection<T>(
      String userId,
      String mascotaId,
      String subcollection,
      T Function(Map<String, dynamic>) fromJson,
      ) async {
    try {
      QuerySnapshot subcollectionSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('mascotas')
          .doc(mascotaId)
          .collection(subcollection)
          .get();

      if (subcollectionSnapshot.docs.isEmpty) {
        print("⚠️ No hay datos en la subcolección: $subcollection para mascota: $mascotaId");
      }

      return subcollectionSnapshot.docs
          .map((doc) => fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print("❌ Error al obtener $subcollection para mascota $mascotaId: $e");
      return [];
    }
  }

  // Método para obtener los datos del usuario desde Firestore
  Future<void> _fetchUserData(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        if (userDoc.exists) {
          _userCustom = User.fromFirestore(userDoc);
         _mascotas = await User.fetchMascotas(userId); // Cargar mascotas
          notifyListeners();        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error al obtener datos del usuario: $e");
    }
  }


  // Cerrar sesión y limpiar datos
  Future<void> signOut(BuildContext context) async {
    await _auth.signOut();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Limpiar solo las claves que no queremos conservar
    await prefs.remove('userId');
    await prefs.remove('token');
    await prefs.remove('rolAcceso');
    await prefs.remove('sessionData'); // Agrega otras claves si es necesario
    await prefs.remove('isLoggedIn');

    _isLoggedIn = false;
    _firebaseUser = null;
    _token = null;
    _rolAcceso = null;

    notifyListeners();
    Navigator.pushReplacementNamed(context, '/login');
  }

  set rolAcceso(int? value) {
    _rolAcceso = value;
    notifyListeners(); // Notify listeners that the state has changed
  }

  set business(Business? value) {
    _business= value;
    notifyListeners(); // Notify listeners that the state has changed
  }

  // Método para cargar sesión desde SharedPreferences
  Future<void> loadSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;    isInitialized = true; // Marcar como inicializado

    if (_isLoggedIn) {
      _rolAcceso = prefs.getInt('rolAcceso');
    }

    notifyListeners();

  }

  // ✅ Método para guardar los roles del usuario en la sesión
  Future<void> setUserPerfil(List<Perfil> perfil) async{
    _perfil = perfil;
    notifyListeners(); // 🔄 Notificar cambios en la UI
  }

  //Monetizar
  /*void checkSubscriptionStatus() async {
    final InAppPurchaseConnection connection = InAppPurchase.instance;
    final bool available = await connection.isAvailable();
    if (!available) return;

    final QueryPurchaseDetailsResponse response =
    await connection.queryPastPurchases();

    for (var purchase in response.pastPurchases) {
      if (purchase.productID == "your_subscription_id" &&
          purchase.status == PurchaseStatus.purchased) {
        _hasSubscription = true;
        notifyListeners();
        return;
      }
    }
    _hasSubscription = false;
    notifyListeners();
  }*/

}
