import 'package:cloud_firestore/cloud_firestore.dart';
import '../class/Negocio.dart';

class BusinessService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;



  Stream<Business?> getBusinessStreamByUserId(String userId) {
    return _firestore
        .collection("businesses")
        .where("userid", isEqualTo: userId)
        .limit(1)
        .snapshots()
        .map((query) async {
      if (query.docs.isNotEmpty) {
        Business business = Business.fromFirestore(query.docs.first);

        // 🔹 Obtener lista de negocios en tiempo real
        business.negocios = await fetchNegociosWithActividades(business.id);
        return business;
      }
      return null;
    }).asyncMap((event) async => await event);
  }

  /// **🔹 Obtener negocios de una empresa por `userId`**
  Future<List<Negocio>> fetchNegociosWithActividades(String negocioId) async {
    try {
      // 🔹 Obtener negocios desde Firestore
      QuerySnapshot negociosSnapshot = await FirebaseFirestore.instance
          .collection("businesses")
          .doc(negocioId)
          .collection("negocios")
          .get();

      List<Negocio> negocios = [];

      for (var negocioDoc in negociosSnapshot.docs) {
        Map<String, dynamic> negocioData = negocioDoc.data() as Map<String, dynamic>;

        // 🔹 Obtener actividades asociadas al negocio
        QuerySnapshot actividadesSnapshot = await FirebaseFirestore.instance
            .collection("businesses")
            .doc(negocioId)
            .collection("negocios")
            .doc(negocioDoc.id)
            .collection("actividades")
            .get();

        List<Actividad> actividades = actividadesSnapshot.docs.map((doc) {
          return Actividad.fromJson(doc.data() as Map<String, dynamic>);
        }).toList();

        // 🔹 Agregar actividades a la instancia de `Negocio`
        Negocio negocio = Negocio.fromFirestore(negocioData);
        negocio = Negocio(
          id: negocio.id,
          descripcion: negocio.descripcion,
          foto: negocio.foto,
          assignedAt: negocio.assignedAt,
          actividades: actividades, // 🔹 Agregar la lista de actividades
        );

        negocios.add(negocio);
      }

      return negocios;
    } catch (e) {
      print("❌ Error al obtener negocios con actividades: $e");
      return [];
    }
  }




  /// **🔹 Obtener todas las empresas**
  Future<List<Business>> getAllBusinesses() async {
    try {
      QuerySnapshot query = await _firestore.collection("business").get();

      return query.docs.map((doc) => Business.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error al obtener empresas: $e");
      return [];
    }
  }

  /// **🔹 Agregar una nueva empresa**
  Future<void> addBusiness(Business business) async {
    try {
      await _firestore
          .collection("business")
          .doc(business.userid)
          .set(business.toFirestore());
    } catch (e) {
      print("Error al agregar empresa: $e");
    }
  }

  /// **🔹 Actualizar datos de una empresa**
  Future<void> updateBusiness(String businessId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection("business")
          .doc(businessId)
          .update(data);
    } catch (e) {
      print("Error al actualizar empresa: $e");
    }
  }

  /// **🔹 Eliminar una empresa**
  Future<void> deleteBusiness(String businessId) async {
    try {
      await _firestore
          .collection("business")
          .doc(businessId)
          .delete();
    } catch (e) {
      print("Error al eliminar empresa: $e");
    }
  }
}
