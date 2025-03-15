import 'package:PetCare/pages/AdoptionChatForOfertante.dart';
import 'package:PetCare/pages/AdoptionListPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../class/SessionProvider.dart';

class AdoptionManagementScreen extends StatefulWidget {
  @override
  _AdoptionManagementScreenState createState() => _AdoptionManagementScreenState();
}

class _AdoptionManagementScreenState extends State<AdoptionManagementScreen> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<SessionProvider>(context);
    final userId = sessionProvider.business!.userid;

    return Scaffold(
      appBar: AppBar(
        title: Text("Gestión de Adopciones"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddAdoptionScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: TextField(
              decoration: InputDecoration(
                labelText: "Buscar por nombre, edad o raza",
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection("adopciones")
                  .where("userId", isEqualTo: userId) // Filtrar solo por el usuario logueado
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                var mascotas = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  return (data["nombre"]?.toLowerCase() ?? "").contains(searchQuery) ||
                      (data["raza"]?.toLowerCase() ?? "").contains(searchQuery) ||
                      (data["edad"]?.toString().contains(searchQuery) ?? false);
                }).toList();

                if (mascotas.isEmpty) {
                  return Center(child: Text("No existen mascotas en adopción"));
                }

                return ListView.builder(
                  itemCount: mascotas.length,
                  itemBuilder: (context, index) {
                    return _buildAdoptionCard(mascotas[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdoptionCard(DocumentSnapshot mascotaDoc) {
    var data = mascotaDoc.data() as Map<String, dynamic>;
    List<String> imagenes = data['imagenes'] is List ? List<String>.from(data['imagenes']) : [];
    final sessionProvider = Provider.of<SessionProvider>(context);
    final userId = sessionProvider.business!.userid;
    return Card(
      margin: EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            imagenes.isNotEmpty
                ? CarouselSlider(
              options: CarouselOptions(height: 200.0, enableInfiniteScroll: false),
              items: imagenes.map((image) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 5.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(image: NetworkImage(image), fit: BoxFit.cover),
                  ),
                );
              }).toList(),
            )
                : Container(
              height: 200,
              color: Colors.grey[300],
              alignment: Alignment.center,
              child: Text("Sin imágenes", style: TextStyle(fontSize: 16, color: Colors.black54)),
            ),
            SizedBox(height: 10),
            Text("${data['nombre'] ?? 'Sin nombre'}, ${data['edad'] ?? 'Edad desconocida'}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Sexo: ${data['sexo'] ?? 'Desconocido'}", style: TextStyle(fontSize: 16)),
            Text("Raza: ${data['raza'] ?? 'Sin especificar'}", style: TextStyle(fontSize: 16)),
            Text("Estado: ${data['estado'] ?? 'No definido'}",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InterestedUsersScreen(mascotaId: data["mascotaId"],mascotaData: data),
                      ),
                    );
                  },
                  child: Text("Contactos"),
                ),
                ElevatedButton(
                  onPressed: () {
                    FirebaseFirestore.instance
                        .collection("adopciones")
                        .doc(mascotaDoc.id)
                        .update({"estado": "Adoptada"});
                  },
                  child: Text("Marcar como adoptada"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class InterestedUsersScreen extends StatelessWidget {
  final String mascotaId;
  final Map<String, dynamic> mascotaData;

  InterestedUsersScreen({required this.mascotaId, required this.mascotaData});

  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<SessionProvider>(context);
    final userId = sessionProvider.business!.userid;

    // Asegurarse de que el color de la barra de estado no sea cubierto
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      // Hace la barra de estado transparente
      statusBarIconBrightness: Brightness
          .dark, // Cambia el color de los íconos en la barra de estado
    ));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        // Tamaño estándar de AppBar
        child: SafeArea(
          child: AppBar(
            title: Text(
              'Interesado en la mascota',
              style: TextStyle(
                fontFamily: 'Poppins', // Fuente personalizada
                fontSize: 20,
              ),
            ),
            backgroundColor: const Color(0xFFA0E3A7),
            // Color verde menta de la marca
            elevation: 0, // Sin sombra
          ),
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection("chats")
            .where("mascotaId", isEqualTo: mascotaId)
            .where("ofertanteId", isEqualTo: userId) // ✅ Filtrar por el dueño del negocio
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          if (snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No hay interesados para esta mascota"));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var chatData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return FutureBuilder(
                future: FirebaseFirestore.instance.collection("users")
                    .doc(chatData["interesadoId"]).get(),
                builder: (context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
                  if (!userSnapshot.hasData) return CircularProgressIndicator();

                  // ✅ Verificar si el documento existe antes de acceder a los datos
                  if (!userSnapshot.data!.exists) {
                    return ListTile(
                      leading: CircleAvatar(child: Icon(Icons.person)),
                      title: Text("Usuario no encontrado"),
                      subtitle: Text("Mensajes sin leer: ${chatData['mensajesSinLeer'] ?? 0}"),
                      trailing: Icon(Icons.message, color: Colors.blue),
                    );
                  }

                  var userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: userData["photo"] != null && userData["photo"] != ""
                          ? NetworkImage(userData["photo"])
                          : null,
                      child: (userData["photo"] == null || userData["photo"] == "")
                          ? Icon(Icons.person)
                          : null,
                    ),
                    title: Text(userData["name"] ?? "Usuario desconocido"),
                    subtitle: Text("Mensajes sin leer: ${chatData['mensajesSinLeer'] ?? 0}"),
                    trailing: IconButton(
                      icon: Icon(Icons.message, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdoptionChatForOfertantePage(
                                mascotaId: mascotaId,
                                interesadoId: chatData["interesadoId"],
                                ofertanteId: userId,
                                mascotaData: mascotaData,
                              ),
                            ),
                          );
                        },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}



class AddAdoptionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Agregar Mascota en Adopción")),
      body: Center(child: Text("Formulario para agregar mascota")),
    );
  }
}
