import 'dart:async';
import 'dart:convert';
import 'dart:io';


import 'package:PetCare/class/UserRoles.dart';
import 'package:PetCare/class/extensions.dart';
import 'package:PetCare/pages/peso_page.dart';
import 'package:PetCare/pages/pet_frendly_page.dart';
import 'package:PetCare/pages/vacuna_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';


import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

import '../class/ActividadEstilista.dart';
import '../class/ActividadNegocio.dart';
import '../class/CalendarioDay.dart';
import '../class/CalendarioWork.dart';
import '../class/Event.dart';
import '../class/Mascota.dart';
import '../class/Review.dart';
import '../class/SessionProvider.dart';
import '../class/User.dart';

import '../services/storage_service.dart';
import 'AdoptionListPage.dart';
import 'CompletarMascotaPage.dart';
import 'ComportamietoMascota.dart';
import 'Config.dart';
import 'TikTokPhotoViewer.dart';
import 'Utiles.dart';
import 'add_mascota.dart';

import 'package:geolocator/geolocator.dart';

import '../class/Negocio.dart';
import 'package:http/http.dart' as http;

import 'amigos_perruno_page.dart';

import 'package:url_launcher/url_launcher.dart';



class HomePageInicio extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}


class _HomePageState extends State<HomePageInicio> {
  int _selectedIndex = 0;
  late FirebaseMessaging messaging;
  bool _showSharedAlbumsPage = false; // 🔹 Controla si se debe mostrar "Social"


  final List<Widget> _pages = [
    MisMascotasPageInicio(),
    //NearbyBusinessesPage(),
    PetFriendlyScreen(),
    TikTokPhotoViewer(),
    ChatScreen(),
    ProfilePage(),
  ];




  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final session = Provider.of<SessionProvider>(context, listen: false);
        session.notifyListeners();

        // ✅ Verificar en SharedPreferences si ya se ejecutó
        SharedPreferences prefs = await SharedPreferences.getInstance();
        bool alreadyValidated = prefs.getBool('isSessionValidated') ?? false;

        if (!alreadyValidated) {
          prefs.setBool('isSessionValidated', true); // Guardar que ya se validó
          _validateSession();
        }
      }
    });


  }



  void _validateSession() async {
    final session = Provider.of<SessionProvider>(context, listen: false);

    // 🔹 Si el usuario no está logueado, redirigir al login
    if (!session.isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // 🔹 Obtener los roles del usuario
    int? perfiles = session.rolAcceso;


    // 🔹 Si el usuario tiene un solo rol, redirigir directamente
    if (perfiles!=null) {
      _navigateToHome(perfiles,session);
      return;
    }


  }

  Future<void> _navigateToHome(int perfil, SessionProvider sessionProvider, ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    bool alreadySelected = prefs.getBool('alreadySelected') ?? false;

    switch (perfil) {
      case 1:
        sessionProvider.rolAcceso=perfil;
        if(alreadySelected){
          Navigator.pushReplacementNamed(context, '/home_inicio');
        }else{
          Navigator.pushReplacementNamed(context, '/encuesta_inicio');
        }

        break;
      case 2:
        sessionProvider.rolAcceso=perfil;
        if(alreadySelected){
          Navigator.pushReplacementNamed(context, '/home_estilista');
        }else{
          Navigator.pushReplacementNamed(context, '/encuesta_inicio');
        }
        break;
      default:
      // Manejo de rol desconocido
        Utiles.showInfoDialog(
            context: context, title: 'Error', message: 'Rol en desarrollo.');
        break;
    }
  }


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;

      if (index == 2) { // ✅ Si entra a "Social"
        print("🔄 Usuario entró a Social, forzando actualización...");
        _showSharedAlbumsPage = false; // Primero, ocultar la página
          setState(() {
            _showSharedAlbumsPage = true; // Ahora sí, crear una nueva instancia
          });

      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mostrar la pantalla actual según _selectedIndex
          Positioned.fill(
            child: _pages[_selectedIndex],
          ),


        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Mascotas'),
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Pet Friendly'),
          BottomNavigationBarItem(icon: Icon(Icons.photo_camera_front), label: 'Social'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green[400],
        onTap: _onItemTapped,
        unselectedItemColor: Colors.black,
        backgroundColor: Colors.blueGrey[900],
        elevation: 10,
      ),
    );
  }
}




class MisMascotasPageInicio extends StatefulWidget {
  @override
  _MisMascotasPageState createState() => _MisMascotasPageState();
}

class _MisMascotasPageState extends State<MisMascotasPageInicio> {
  Mascota? selectedMascota;
  double profileCompletion = 0.0; // Estado inicial del perfil
  bool isLoading = false;
  List<Activity> events = [];
  final Map<String, Color> mascotaColors = {};
  int _eventNotifications = 0;


  //late  List<Mascota> mascotas=[];


  @override
  void initState() {
    super.initState();
    // Aquí tu lógica de WebSocket o inicialización.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final session = Provider.of<SessionProvider>(context, listen: false);
        await session.updateMascotaSession(session.user!.userId); // 🔥 Ahora sí recarga la lista
      }
    });


  }

  Future<void> _loadMascotaEvents() async {
    if (selectedMascota != null) {
      try {
        final events = await _fetchMascotaEvents(selectedMascota!.mascotaid);

        // Filtrar eventos que ocurren en las próximas 24 horas
        setState(() {
          _eventNotifications = events.where((event) => isEventWithinNext24Hours(event)).length;
        });

        // Notificar eventos que ocurren en las próximas 24 horas
        _notifyEventsWithin24Hours(events);

      } catch (error) {
        print('Error al cargar los eventos: $error');
      }
    }
  }

// Método para verificar si un evento es dentro de las próximas 24 horas
  bool isEventWithinNext24Hours(Event event) {
    DateTime eventDate = DateTime.parse(event.startTime); // Convertir la fecha de evento
    DateTime now = DateTime.now();

    // Verificar si el evento es en las próximas 24 horas
    Duration difference = eventDate.difference(now);
    return difference.inHours <= 24 && difference.inHours > 0;
  }

// Método para enviar una notificación para eventos dentro de las próximas 24 horas
  void _notifyEventsWithin24Hours(List<Event> events) {
    for (var event in events) {
      if (isEventWithinNext24Hours(event)) {
        // Lógica para enviar notificación
        print('Notificación: El evento ${event.description} ocurrirá dentro de 24 horas');
        // Aquí puedes usar una lógica para mostrar una notificación, por ejemplo:
        // showLocalNotification(event); o algún otro mecanismo para notificaciones locales.
      }
    }
  }



  @override
  void dispose() {
    // Unsubscribe from the WebSocket channel if the subscription exists
    super.dispose();
  }


  Future<List<Event>> _fetchMascotaEvents(String mascotaId) async {
    try {
      final baseUrl = Config.get('api_base_url');
      final session = Provider.of<SessionProvider>(context, listen: false);
      final url = '$baseUrl/api/events/events/$mascotaId';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${session.token!}',
          'Content-Type': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> eventosJson = json.decode(response.body);
        return eventosJson.map((json) => Event.fromJson(json)).toList();
      }
      if (response.statusCode == 204) {
        return [];
      } else {
        throw Exception('Failed to load events');
      }
    } catch (error) {
      print(error.toString());
      throw Exception('Error al cargar los eventos');
    }
  }

  Future<void> updateEventsPet(Event event, Mascota selectedMascota) async {
    final baseUrl = Config.get('api_base_url');
    final session = Provider.of<SessionProvider>(context, listen: false);
    final url = '$baseUrl/api/events/event-update'; // URL para eliminar fotos

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ' + session.token!,
        'mascotaId': selectedMascota.mascotaid,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'id': event.id,
        'title': event.title,
        'descripcion': event.description,
        'fecha': event.fecha,
        'startTime': event.startTime,
        'endTime': event.endTime,
        'completed': event.isCompleted,
        'leido': event.leido,
        'actividadid': event.actividadId
      }),
    );

    if (response.statusCode == 200) {
      print('Foto eliminada con éxito.');
    } else {
      print('Error al eliminar la foto: ${response.body}');
    }
  }
  Future<void> _showEventRatingDialog(
      BuildContext context, Event evento) async {
    if (evento.isCompleted) {
      final _ratingController = TextEditingController();
      int _rating = 0;
      final session = Provider.of<SessionProvider>(context, listen: false);
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Evaluar Evento'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Descripción: ${evento.description}'),
                SizedBox(height: 8),
                Text('Fecha y hora: ${evento.fecha} ${evento.startTime}'),
                SizedBox(height: 16),
                // Calificación con estrellas
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: Colors.yellow,
                      ),
                      onPressed: () {
                        setState(() {
                          _rating = index + 1;
                        });
                      },
                    );
                  }),
                ),
                SizedBox(height: 16),
                // Campo para comentario
                TextField(
                  controller: _ratingController,
                  decoration: InputDecoration(
                    labelText: 'Comentario',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  // Guardar la calificación y comentario
                  final comentario = _ratingController.text;
                  final calificacion = _rating;

                  // Crear una instancia de Review
                  final review = Review(
                    id: Utiles.getId(), // Genera un ID único para la reseña
                    userid: session.user!.userId,
                    actividadid: evento.actividadId,
                    comment: comentario,
                    rating: calificacion,
                    timestamp: DateTime.now(),
                    likes: 0,
                    responses: [],
                  );

                  // Aquí puedes llamar a la API para guardar la calificación y comentario
                  // por ejemplo, usando la función `saveReview` (ver más abajo)

                  await _saveReview(evento.actividadId, review);

                  // Marcar evento como leído
                  evento.leido = true;
                  Navigator.of(context).pop();
                },
                child: Text('Enviar Calificación'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancelar'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _saveReview(String actividadId, Review review) async {
    // Aquí debes implementar la lógica para llamar a tu API y guardar la calificación
    // Por ejemplo, usando http:
    final session = Provider.of<SessionProvider>(context, listen: false);

    final baseUrl = Config.get('api_base_url');
    String? token = session.token;

    final response = await http.post(
      Uri.parse('$baseUrl/api/comments/comment/new'),
      headers: {
        'Authorization': 'Bearer ${token!}',
        'Content-Type': 'application/json'
      },
      body: jsonEncode(review.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save review');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, session, child) {
        // **Recargar mascotas en tiempo real**
        final mascotas = session.mascotas;

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
                title: Text('Perfil de la Mascota', style: TextStyle(fontFamily: 'Poppins')),
                backgroundColor: const Color(0xFFA0E3A7),
                // Color verde menta de la marca
                elevation: 0, // Sin sombra
              ),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildHeader(mascotas), // ✅ Ahora se actualiza automáticamente
                if (selectedMascota != null &&
                    selectedMascota!.eventos != null &&
                    selectedMascota!.eventos!
                        .where((evento) => !evento.leido && isEventWithinNext24Hours(evento))
                        .isNotEmpty)
                  _buildUpcomingEvents(),
                SizedBox(height: 20),
                _buildActionButtons(mascotas),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddMascotaPage(user: session.user!, token: session.token),
                ),
              );
            },
            child: Icon(Icons.add, color: Colors.white),
            backgroundColor: const Color(0xFF67C8F1),
          ),
        );
      },
    );
  }


// Cabecera con la imagen de la mascota y la barra de progreso
  Widget _buildHeader(List<Mascota> mascotas) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: (selectedMascota != null && selectedMascota!.fotos.isNotEmpty && selectedMascota!.fotos.startsWith('http'))
                      ? NetworkImage(selectedMascota!.fotos) as ImageProvider<Object>
                      : (selectedMascota != null)
                      ? AssetImage(_getAssetImage(selectedMascota!.especie)) as ImageProvider<Object>
                      : null, // Si no hay mascota seleccionada, no se asigna imagen
                  backgroundColor: Colors.white,
                  child: selectedMascota == null
                      ? Icon(Icons.pets, color: Colors.grey[400], size: 50)
                      : null, // Solo muestra el ícono si no hay mascota seleccionada
                ),

                // 🔹 Notificación de eventos (si existen)
                if (selectedMascota != null && _eventNotifications > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.red, // Color de la notificación
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$_eventNotifications', // Mostrar el número de eventos
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Completa el perfil',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 10),
                  _buildProfileCompletionBar(),
                ],
              ),
            ),
            SizedBox(width: 10),
            IconButton(
              icon: Icon(Icons.pets, color: Colors.green[400]),
              onPressed: () => _selectOtherPet(mascotas),
            )
          ],
        ),
        SizedBox(height: 20),
        _buildPetSelector(mascotas),
      ],
    );
  }




// Barra de progreso del perfil
  Widget _buildProfileCompletionBar() {
    return Column(
      children: [
        Text(
          selectedMascota != null ? 'Mascota: ${selectedMascota!.nombre}' : 'Seleccione una mascota',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: profileCompletion,
          backgroundColor: Colors.grey[300],
          color: Colors.green[400], // Color verde menta de la marca
          minHeight: 10,
        ),
        SizedBox(height: 8),
        Text(
          '${(profileCompletion * 100).toInt()}% completado',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

// Método que construye el selector de mascotas con notificaciones
  Widget _buildPetSelector(List<Mascota> mascotas) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10), // 🔹 Reduzco margen lateral
      child: SingleChildScrollView( // 🔹 Permite que el contenido sea desplazable
        child: Column(
          children: [
            GridView.builder(
              shrinkWrap: true, // 🔹 Ajusta el tamaño sin overflow
              physics: NeverScrollableScrollPhysics(), // 🔹 Desactiva el scroll del grid
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 🔹 3 mascotas por fila
                crossAxisSpacing: 5, // 🔹 Menos espacio entre columnas
                mainAxisSpacing: 5, // 🔹 Menos espacio entre filas
                childAspectRatio: 1, // 🔹 Relación de aspecto equilibrada
              ),
              itemCount: mascotas.length,
              itemBuilder: (context, index) {
                final mascota = mascotas[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedMascota = mascota;
                      profileCompletion = _calculateProfileCompletion(mascota);
                    });

                    _loadMascotaEvents(); // Cargar eventos al seleccionar
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    CircleAvatar(
                    radius: 40, // 🔹 Aumentamos el tamaño del círculo
                    backgroundImage: mascota.fotos.startsWith('http')
                        ? NetworkImage(mascota.fotos) as ImageProvider<Object>
                        : AssetImage(_getAssetImage(mascota.especie)) as ImageProvider<Object>,
                    backgroundColor: selectedMascota == mascota
                        ? Colors.green[100]
                        : Colors.grey[200],
                  ),
                      SizedBox(height: 2), // 🔹 Menos espacio entre imagen y texto
                      Text(
                        mascota.nombre,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Método para seleccionar la imagen correcta
  String _getAssetImage(String especie) {
    switch (especie.toLowerCase()) {
      case 'perro':
        return 'lib/assets/perro_patica.png';
      case 'gato':
        return 'lib/assets/gato_patica.png';
      case 'ave':
        return 'lib/assets/ave_patica.png';
      default:
        return 'lib/assets/sin_imagen.png'; // 🔹 Imagen por defecto si la especie no coincide
    }
  }


// Método que construye el contenedor de eventos próximos
  Widget _buildUpcomingEvents() {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: selectedMascota!.eventos!
            .where((evento) => !evento.leido && isEventWithinNext24Hours(evento))
            .map((evento) {
          final now = DateTime.now();
          final fechaEvento = DateTime.parse(evento.fecha);
          final diferencia = fechaEvento.difference(now);

          Color color;
          IconData icon;
          if (diferencia.inDays == 0) {
            color = Colors.red;
            icon = Icons.warning;
          } else if (diferencia.inDays < 7) {
            color = Colors.yellow;
            icon = Icons.warning_amber;
          } else {
            color = Colors.grey;
            icon = Icons.info;
          }

          return Dismissible(
            key: Key(evento.id.toString()),
            direction: DismissDirection.horizontal,
            onDismissed: (direction) async {
              // Marcar el evento como leído
              evento.leido = true;
              await updateEventsPet(evento, selectedMascota!);

              setState(() {});

              // Mostrar Snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Evento "${evento.title}" marcado como leído')),
              );
            },
            background: Container(
              color: Colors.green,
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Icon(Icons.done, color: Colors.white),
            ),
            secondaryBackground: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Icon(Icons.delete, color: Colors.white),
            ),
            child: GestureDetector(
              onTap: () async {
                if (evento.isCompleted) {
                  await _showEventRatingDialog(context, evento);
                }
              },
              child: Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: color, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: color),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            evento.title,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Fecha y hora: ${evento.fecha}',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Función para obtener el estado de completado del perfil de la mascota
  double _calculateProfileCompletion(Mascota mascota) {
    final attributes = [
      mascota.nombre,
      mascota.especie,
      mascota.raza,
      mascota.edad,
      mascota.genero,
      mascota.color,
      mascota.fechaNacimiento,

      mascota.tamano,
      mascota.peso,
      mascota.personalidad,
      mascota.historialMedico,
      mascota.necesidadMascota,
      mascota.comportamientosMascota,
      mascota.fotos,
    ];
    final filledAttributes = attributes
        .where((attr) => attr != null && attr.toString().isNotEmpty)
        .length;
    return filledAttributes / attributes.length;
  }

  // Función para cambiar la mascota seleccionada
  void _selectOtherPet(List<Mascota> mascotas) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(10),
          height: 400, // Ajuste de altura para que se vea correctamente
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // 🔹 Máximo 3 mascotas por fila
              crossAxisSpacing: 15, // 🔹 Espaciado entre columnas
              mainAxisSpacing: 15, // 🔹 Espaciado entre filas
              childAspectRatio: 0.8, // 🔹 Proporción adecuada para evitar desbordes
            ),
            itemCount: mascotas.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedMascota = mascotas[index];
                    profileCompletion = _calculateProfileCompletion(selectedMascota!);
                  });
                  Navigator.pop(context);
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [CircleAvatar(
                    radius: 40, // 🔹 Aumentamos el tamaño del círculo
                    backgroundImage:mascotas[index].fotos.startsWith('http')
                        ? NetworkImage(mascotas[index].fotos) as ImageProvider<Object>
                        : AssetImage(_getAssetImage(mascotas[index].especie)) as ImageProvider<Object>,
                    backgroundColor: selectedMascota == mascotas[index]
                        ? Colors.green[100]
                        : Colors.grey[200],
                  ),
                    SizedBox(height: 5),
                    Text(
                      mascotas[index].nombre,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis, // 🔹 Evita desbordamiento de texto
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }


  // Botones de acción que dependen de la mascota seleccionada
  Widget _buildActionButtons(List<Mascota> mascotas) {
    bool areButtonsEnabled = selectedMascota != null; // Habilitar solo si hay una mascota seleccionada
    bool allowGeneralButtons = mascotas.isEmpty; // Habilitar ciertos botones si no hay mascotas

    // 🔹 Validar si se debe habilitar el botón de "Evaluación"
    bool isEvaluationEnabled = selectedMascota != null &&
        ((selectedMascota!.necesidadMascota?.isNotEmpty ?? false) ||
            (selectedMascota!.comportamientosMascota?.isNotEmpty ?? false));

    return Expanded(
      child: SingleChildScrollView( // Permite que el contenido sea desplazable si es necesario
        child: GridView.count(
          shrinkWrap: true, // Hace que el GridView solo ocupe el espacio necesario
          physics: NeverScrollableScrollPhysics(), // Desactiva el scroll interno del GridView
          crossAxisCount: 3, // Tres botones por fila
          childAspectRatio: 1.2, // Ajustamos la proporción ancho/alto para evitar saltos de línea
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _buildActionButton(Icons.vaccines, "Ver Vacunas", areButtonsEnabled, mascotas),
            _buildActionButton(Icons.monitor_weight, "Agregar Peso", areButtonsEnabled, mascotas),
            _buildActionButton(Icons.edit, "Completar Perfil", areButtonsEnabled, mascotas),

            // 🔹 Solo habilitar el botón "Evaluación" si la condición se cumple
            _buildActionButton(Icons.edit, "Evaluación", isEvaluationEnabled, mascotas),

            _buildActionButton(Icons.pets, "Recuerdos", areButtonsEnabled, mascotas),
            _buildActionButton(Icons.search, "Buscar Eventos", false, mascotas),
            _buildActionButton(Icons.delete, "Eliminar", areButtonsEnabled, mascotas),
            _buildActionButton(Icons.home, "Adopción", true, mascotas),
            _buildActionButton(Icons.shopping_bag, "Tienda", false, mascotas),
          ],
        ),
      ),
    );
  }



// Función para construir los botones con borde azul y fondo blanco
  Widget _buildActionButton(IconData icon, String label, bool isEnabled, List<Mascota> mascotas) {
    return OutlinedButton(
      onPressed: isEnabled
          ? () {
        if (label == 'Ver Vacunas') {
          // Abrir la pantalla de "Ver vacunas"
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => VaccinationPage(mascota: selectedMascota!,)),
          );
        }
        else if (label == 'Agregar Peso') {
          // Abrir la pantalla de "Agregar Peso"
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PesoPage(mascota: selectedMascota!,)),
          );
        }
        else if (label == 'Recuerdos') {
          // Abrir la pantalla de "Recuerdos"
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AmigosPerrunosPage(mascota: selectedMascota!,)),
          );
        }
       else if (label == 'Completar Perfil') {
          // Abrir la pantalla de "Recuerdos"
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) =>  CompletarMascotaPage(selectedMascota: selectedMascota!)),
          );
        }

        else if (label == 'Eliminar') {
          _mostrarDialogoEliminarMascota(selectedMascota!,mascotas);

        }else if (label == 'Adopción') {
          // Agregar navegación a la página de adopción
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) =>  AdoptionListPage()),
          );
        } else if (label == 'Tienda') {
          // Agregar navegación a la tienda
        } else if (label == 'Evaluación') {
          if ( selectedMascota!.necesidadMascota!.isNotEmpty || selectedMascota!.comportamientosMascota!.isNotEmpty){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) =>  EvaluacionMascota(mascotaId:selectedMascota!.mascotaid)),
            );
          }
        }
      }
          : null, // Si el botón está deshabilitado, no realiza ninguna acción
      style: OutlinedButton.styleFrom(
        foregroundColor: isEnabled ? Colors.black : Colors.grey,
        side: BorderSide(
          color: Color(0xFF67C8F1), // Borde azul
          width: 1.5, // Ancho del borde
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15), // Bordes suaves
        ),
        backgroundColor: Colors.white, // Cambia el color del ícono según el estado
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: isEnabled ? Color(0xFF0288D1) : Colors.grey), // Ícono azul si está habilitado, gris si está deshabilitado
          SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5, // Reducir el tamaño del texto
              color: isEnabled ? Colors.black : Colors.grey, // Texto negro si está habilitado, gris si está deshabilitado
            ),
            maxLines: 2, // Permitir hasta 2 líneas de texto
          ),
        ],
      ),
    );
  }
  // Widget para los botones de acción
 /* Widget _buildActionButton(IconData icon, String label, Color? color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        padding: EdgeInsets.all(10),
      ),
      onPressed: selectedMascota != null ? () => _performAction(label) : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: Colors.black87),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }*/

  void _mostrarDialogoEliminarMascota(Mascota selectedMascota,List<Mascota> mascotas) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              contentPadding: EdgeInsets.all(20),
              title: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 30),
                  SizedBox(width: 10),
                  Text(
                    'Eliminar Mascota',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pets, color: Colors.green, size: 50),
                  SizedBox(height: 10),
                  Text(
                    '¿Estás seguro de que deseas eliminar a ${selectedMascota.nombre}?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.black),
                  ),
                  SizedBox(height: 15),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: Text(
                    'No',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.red),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                    setStateDialog(() => isLoading = true);
                    final session = Provider.of<SessionProvider>(context, listen: false);
                    bool success = await eliminarMascotaDesdeFirebase(session.user!.userId, selectedMascota.mascotaid, selectedMascota.fotos);

                    Navigator.pop(context); // Cierra el modal después de la eliminación

                    if (success) {
                      _mostrarDialogoExito('Mascota eliminada correctamente.', selectedMascota.mascotaid, mascotas);
                    } else {
                      _mostrarDialogoError('Error al eliminar la mascota. Inténtalo de nuevo.');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isLoading
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    'Sí',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> eliminarMascotaDesdeFirebase(String userId, String mascotaId, String fileUrl) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Eliminar la imagen de la mascota desde Firebase Storage
      if (await StorageService.deleteFileFromFirebase(fileUrl)) {
        // 2. Eliminar documento mascota
        await firestore
            .collection('users')
            .doc(userId)
            .collection('mascotas')
            .doc(mascotaId)
            .delete();

        print('✅ Mascota eliminada');

        // 3. Buscar álbum asociado por mascotaId
        final albumQuery = await firestore
            .collection('albums')
            .where('mascotaId', isEqualTo: mascotaId)
            .get();

        for (final albumDoc in albumQuery.docs) {
          final albumId = albumDoc.id;

          // 4. Buscar y eliminar las fotos asociadas a ese álbum
          final photosQuery = await firestore
              .collection('photos')
              .where('albumId', isEqualTo: albumId)
              .get();

          for (final photoDoc in photosQuery.docs) {
            final photoData = photoDoc.data();
            final photoUrl = photoData['photoUrl'];

            // Eliminar imagen en Firebase Storage (si querés)
            if (photoUrl != null && photoUrl.toString().contains('firebase')) {
              await StorageService.deleteFileFromFirebase(photoUrl);
            }

            // Eliminar documento photo
            await firestore.collection('photos').doc(photoDoc.id).delete();
          }

          // 5. Eliminar el documento del álbum
          await firestore.collection('albums').doc(albumId).delete();
          print('✅ Álbum y fotos asociadas eliminadas');
        }

        return true;
      } else {
        print('⚠️ No se pudo eliminar la imagen de Storage.');
        return false;
      }
    } catch (e) {
      print('❌ Error al eliminar mascota y datos relacionados: $e');
      return false;
    }
  }


  Future<bool> _eliminarMascotaApi(String id, String fileUrl) async {
    try {

      if(await StorageService.deleteFileFromFirebase(fileUrl)){
        final baseUrl = Config.get('api_base_url');
        final session = Provider.of<SessionProvider>(context, listen: false);
        final url = '$baseUrl/api/pet/delete/$id'; // URL para eliminar mascota

        final response = await http.delete(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer ${session.token}',
            'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          return true;
        } else {
          return false;
        }
      }else{
        return false;
      }

    } catch (e) {
      print('Error eliminando mascota: $e');
      return false;
    }
  }

  void _mostrarDialogoExito(String mensaje, String idMascota, List<Mascota> mascotas) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 30),
              SizedBox(width: 10),
              Text(
                'Éxito',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            mensaje,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Poppins', fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  // 🔹 Eliminar la mascota de la lista
                  mascotas.removeWhere((mascota) => mascota.mascotaid == idMascota);

                  // 🔹 Si la mascota eliminada estaba seleccionada, desmarcarla
                  if (selectedMascota != null && selectedMascota!.mascotaid == idMascota) {
                    selectedMascota = null;
                  }
                });

                Navigator.pop(context); // Cerrar el modal
              },
              child: Text(
                'OK',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.green),
              ),
            ),
          ],
        );
      },
    );
  }


  void _mostrarDialogoError(String mensaje) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 30),
              SizedBox(width: 10),
              Text(
                'Error',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            mensaje,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Poppins', fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cerrar',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // Acción cuando se presiona un botón
  void _performAction(String action) {
    if (action == 'Ver Vacunas') {
      // Abrir la pantalla de "Ver vacunas"
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => VaccinationPage(mascota: selectedMascota!,)),
      );
    } else if (action == 'Editar perfil') {
      // Abrir la pantalla de "Editar perfil"
     /* Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EditarPerfilPage()),
      );*/
    } else if (action == 'Eliminar perfil') {
      // Mostrar un diálogo de confirmación antes de eliminar
      _showDeleteConfirmation();
    } else {
      // Acción desconocida o genérica
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Acción seleccionada: $action'),
      ));
    }
  }

  // Función para mostrar un diálogo de confirmación al eliminar
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar eliminación'),
          content: Text('¿Estás seguro de que deseas eliminar el perfil?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar diálogo
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                // Lógica para eliminar el perfil
                Navigator.of(context).pop(); // Cerrar diálogo
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Perfil eliminado con éxito'),
                ));
              },
              child: Text('Eliminar'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        );
      },
    );
  }

  // Función para obtener colores únicos por mascota
  Color _getColorForMascota(Mascota mascota) {
    if (mascotaColors.containsKey(mascota.mascotaid)) {
      return mascotaColors[mascota.mascotaid]!;
    }

    final color = Colors.primaries[mascotaColors.length % Colors.primaries.length];
    mascotaColors[mascota.mascotaid] = color;
    return color;
  }
}


class NearbyBusinessesPage extends StatefulWidget {
  final Mascota mascota;

  NearbyBusinessesPage({required this.mascota});

  @override
  _NearbyBusinessesPageState createState() => _NearbyBusinessesPageState();
}

class _NearbyBusinessesPageState extends State<NearbyBusinessesPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Business> _businesses = [];
  bool _isLoading = false;

  Future<void> _fetchNearbyBusinesses() async {
    setState(() {
      _isLoading = true;
    });

    //Position position = await _determinePosition();
    String query = _searchController.text;

    final session = Provider.of<SessionProvider>(context, listen: false);
    final baseUrl = Config.get('api_base_url');
    String? token = session.token;

    var url = Uri.parse(
        '$baseUrl/api/businesses/list-businesses'); // Reemplaza con la URL de tu API

    // Agrega los parámetros a la URL
    final params = {'search': query};

    // Construye la URL con los parámetros
    final uri = url.scheme == 'https'
        ? Uri.https(url.authority, url.path, params)
        : Uri.http(url.authority, url.path, params);

    var response = await http.get(
      uri,
      headers: {
        'Authorization':
            'Bearer ${token!}', // Reemplaza 'tu_token_aqui' con tu token real
        'Content-Type':
            'application/json', // Ejemplo de otro encabezado opcional
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _businesses =
            (data as List).map((json) => Business.fromFirestore(json)).toList();
        _isLoading = false;
      });
    } else {
      _businesses = [];
      setState(() {
        _isLoading = false;
      });
      throw Exception('Failed to load businesses');
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  void _navigateToBusinessCalendar(
      User user, Mascota mascota, Business business) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CalendarPageBusiness(
            user: user, mascota: mascota, business: business),
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buscar Servicio para ' + widget.mascota.nombre),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _fetchNearbyBusinesses,
                  child: Icon(Icons.search),
                ),
              ],
            ),
            SizedBox(height: 16),
            _isLoading
                ? CircularProgressIndicator()
                : Expanded(
                    child: ListView.builder(
                      itemCount: _businesses.length,
                      itemBuilder: (context, index) {
                        var business = _businesses[index];
                        var users = business.userid;
                        final session = Provider.of<SessionProvider>(context, listen: false);

                        return ListTile(
                          leading: Image.network(
                            business.logoUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                          title: Text(business.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(business.address),
                              _buildStarRating(business.rating),
                            ],
                          ),
                          onTap: () => _navigateToBusinessCalendar(
                              session.user!, widget.mascota, _businesses[index]),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class CalendarPageBusiness extends StatefulWidget {
  final User user;
  final Mascota mascota;
  final Business business;
  CalendarPageBusiness(
      {required this.user, required this.mascota, required this.business});

  @override
  BusinessCalendarPage createState() => BusinessCalendarPage();
}

class BusinessCalendarPage extends State<CalendarPageBusiness> {
  late Future<List<Activity>> _activitiesFuture;
  late Map<DateTime, List<Activity>> _events = {};
  late Set<int> _workableDays = {}; // Días de la semana habilitados
  late List<Calendariowork> _workingHours; // Horarios de trabajo
  DateTime _focusedDay = DateTime.now();
  //DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  bool _isLoading = false;
  late List<Calendarioday> _calendarDays; // Días de trabajo y horarios
  late List<ActivityBussines> _activityBussines;
  late StreamSubscription _sub;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final session = Provider.of<SessionProvider>(context, listen: false);
      _selectedDay = _focusedDay;
      _events = {};
      String? token = session.token;
      _fetchActivitiesAndInitializeCalendar(widget.user.userId, token!);
      _fetchActivitiesBusiness(widget.business.id, token);



      if (session.mascotas.isEmpty) { // ✅ Solo carga mascotas si la lista está vacía
        await session.fetchMascotas(session.user!.userId);
        setState(() {}); // 🔹 Forzar reconstrucción solo si realmente se actualizaron los datos
      }
    });




  }



  void _handleIncomingLink(Uri uri) {
    // Obtener el estado de la transacción de la URL
    final String path = uri.host;

    if (path.contains('success')) {
      //Actualizar el estado de la reserva y registrar los datos de la transaccion
      // Redirige a la página de éxito
      Utiles.showConfirmationDialog(
          context: context,
          title: 'Pago exitoso',
          content: 'Su pago quedo registrado.',
          onConfirm: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomePageInicio()),
            );
          });
    } else if (path.contains('failure')) {
      // Redirige a la página de fallo
      /* Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FailureScreen()),
          );*/
      Utiles.showErrorDialog(
          context: context,
          title: 'Error',
          content: "No se pudo procesar el pago.");
    } else if (path.contains('pending')) {
      // Redirige a la página de pendiente
      /*Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PendingScreen()),
          );*/
      Utiles.showErrorDialog(
          context: context,
          title: 'Error',
          content: "No se pudo procesar el pago.");
    }
  }

  Future<void> _fetchActivitiesAndInitializeCalendar(
      String userid, String token) async {
    try {
      // Obtén las actividades y datos de calendario de la API
      List<Activity> activities =
          await fetchActivities(userid, token); // Reemplaza con valores reales
      List<Calendarioday> calendarDays = await fetchCalendarDays(userid,
          token); // Implementa este método para obtener los días laborables
      // _workingHours = await fetchWorkingHours(); // Implementa este método para obtener los horarios de trabajo
      Map<DateTime, List<Activity>> groupedEvents = {};
      // Agrupa las actividades por fecha
      if (activities.isNotEmpty)
        groupedEvents = _groupActivitiesByDate(activities);

      // Obtén los días laborables
      _workableDays = _getWorkableDays(calendarDays);
      _calendarDays = calendarDays;

      setState(() {
        _events = groupedEvents;
      });
    } catch (e) {
      // Manejo de errores
      print('Error fetching activities: $e');
    }
  }

  Future<void> _fetchActivitiesBusiness(String negocioId, String token) async {
    final baseUrl = Config.get('api_base_url');
    final url = Uri.parse('$baseUrl/api/businesses/list-activity-businesses');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json; charset=utf-8'
    };
    // Agrega los parámetros a la URL
    final params = {'negocioId': negocioId};

    // Construye la URL con los parámetros
    final uri = Uri.http(url.authority, url.path, params);
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      _activityBussines =
          data.map((item) => ActivityBussines.fromJson(item)).toList();
    } else if (response.statusCode == 204) {
      Utiles.showErrorDialogBoton(
          context: context,
          title: 'Notificación',
          content: 'El negocio seleccionado (' +
              widget.business.name +
              ') no tiene eventos registrados. Seleccione otro.',
          onConfirm: () {
           /* Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ManagementPage()),
            );*/
          });
      throw Exception('Failed to load calendar days');
    } else {
      throw Exception('Failed to load calendar days');
    }
  }

  Future<List<Calendarioday>> fetchCalendarDays(
      String userId, String token) async {
    final baseUrl = Config.get('api_base_url');
    final url = Uri.parse('$baseUrl/api/parameterscalendario-word-user');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json; charset=utf-8'
    };
    // Agrega los parámetros a la URL
    final params = {'userid': userId};

    // Construye la URL con los parámetros
    final uri = url.scheme == 'https'
        ? Uri.https(url.authority, url.path, params)
        : Uri.http(url.authority, url.path, params);

    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((item) => Calendarioday.fromJson(item)).toList();
    } else if (response.statusCode == 204) {
      Utiles.showErrorDialogBoton(
          context: context,
          title: 'Notificación',
          content: 'No ha definido un calendario. Registre uno a continuación.',
          onConfirm: () {
            /*Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ManagementPage()),
            );*/
          });
      throw Exception('Failed to load calendar days');
    } else {
      throw Exception('Failed to load calendar days');
    }
  }

  Future<void> _registrar(DateTime selectedDay, DateTime startTime,
      DateTime endTime, ActivityBussines evento) async {
    // if (_formKey.currentState!.validate()) {
    //   _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
    });

    final hour = TimeOfDay(hour: startTime.hour, minute: startTime.minute);
    final hourInicioString =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final hourFinString =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

    final session = Provider.of<SessionProvider>(context, listen: false);
    String? token = session.token;

    final reserva = Activity(
        actividadid: Utiles.getId(),
        mascotaid: widget.mascota.mascotaid,
        userid: session.user!.userId,
        title: widget.business.name,
        description: "",
        startime: hourInicioString,
        endtime: hourFinString,
        precio: evento.precio,
        fecha: selectedDay.toIso8601String(),
        status: "Aprobada",
        turnos: 1);

    final baseUrl = Config.get('api_base_url');
    final url = Uri.parse('$baseUrl/api/activity/add-activity'); // URL
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
      body: jsonEncode(reserva.toJson()),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      /*  Utiles.showConfirmationDialog(
          context: context,
          title: 'Registro exitoso',
          content: 'Su evento: ' + widget.business.name + " en el " + widget.business.name,
          onConfirm: () async {
            Navigator.of(context).pop(); // Cierra el diálogo de confirmación
            List<Activity> activities = await fetchActivities(session.user!.userid, token!) ; // Reemplaza con valores reales
            Map<DateTime, List<Activity>> groupedEvents={};

            if(activities.isNotEmpty)
              groupedEvents = _groupActivitiesByDate(activities);

              _events = groupedEvents;
              _showTimeSelectionDialog(selectedDay, _calendarDays); // Actualiza el modal



          },
        );*/

      // Inicializa el servicio de Mercado Pago
      // final mercadoPagoService = MercadoPagoService('TEST-7014566769079605-072823-7dbc2512afe8a0bbd20ea29e348bd00b-448163743'); // Reemplaza con tu Access Token

      // Muestra un diálogo de confirmación
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Confirmar Reserva y Pago'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Actividad: ${evento.actividad}'),
                Text('Precio: ${evento.precio} UYU'),
                Text(
                    'Hora de inicio: ${TimeOfDay.fromDateTime(startTime).format(context)}'),
                Text(
                    'Hora de fin: ${TimeOfDay.fromDateTime(endTime).format(context)}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  // Abre la URL de pago en el navegador
                  final baseUrl = Config.get('api_mercado_pago');
                  final url = Uri.parse('$baseUrl/create_preference');
                  final preferenceResponse = await http.post(
                    url,
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'title': evento.actividad,
                      'quantity': 1,
                      'currency_id': 'UYU',
                      'unit_price': evento.precio,
                    }),
                  );

                  if (preferenceResponse.statusCode == 200) {
                    final preferenceId =
                        jsonDecode(preferenceResponse.body)['id'];

                    //final Uri mercadoPagoUrl = Uri.parse('https://flutter.dev');
                    final Uri mercadoPagoUrl = Uri.parse(
                      'https://www.mercadopago.com.uy/checkout/v1/redirect?preference-id=$preferenceId',
                    );
                    print('Attempting to launch URL: $mercadoPagoUrl');

                    if (await canLaunchUrl(mercadoPagoUrl)) {
                      print('Launching URL...');

                      await launchUrl(mercadoPagoUrl,
                          mode: LaunchMode.externalApplication);
                      // Después de que el usuario complete el pago y vuelva a la aplicación,
                      // puedes navegar a la pantalla de verificación del pago
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentConfirmationScreen(
                              preferenceId: preferenceId),
                        ),
                      );
                    } else {
                      print('Failed to launch URL.');

                      throw 'Could not launch $mercadoPagoUrl';
                    }
                  } else {
                    print('Failed to create preference');
                  }
                },
                child: Text('Pagar'),
              ),
            ],
          );
        },
      );
    } else {
      Utiles.showErrorDialog(
          context: context, title: 'Error', content: jsonDecode(response.body));
    }

    Future.delayed(
      Duration(seconds: 2),
      () {
        setState(() {
          _isLoading = false;
        });
        // Show success dialog
        // Aquí va la acción a ejecutar cuando se confirma
        print('Perfil registrado confirmado');
      },
    );

    // }
  }

  Set<int> _getWorkableDays(List<Calendarioday> days) {
    final workableDays = <int>{};
    for (var day in days) {
      if (day.check) {
        final dayOfWeek = _getDayOfWeekFromString(day.day);
        if (dayOfWeek != null) {
          workableDays.add(dayOfWeek);
        }
      }
    }
    return workableDays;
  }

  int? _getDayOfWeekFromString(String dayString) {
    switch (dayString.toLowerCase()) {
      case 'lun':
        return DateTime.monday;
      case 'mar':
        return DateTime.tuesday;
      case 'mie':
        return DateTime.wednesday;
      case 'jue':
        return DateTime.thursday;
      case 'vie':
        return DateTime.friday;
      case 'sab':
        return DateTime.saturday;
      case 'dom':
        return DateTime.sunday;
      default:
        return null;
    }
  }

  Map<DateTime, List<Activity>> _groupActivitiesByDate(
      List<Activity> activities) {
    Map<DateTime, List<Activity>> data = {};
    for (var activity in activities) {
      final date = DateTime.parse(activity
          .fecha); // Asegúrate de que `activity.date` esté en formato compatible
      if (data[activity.fecha] == null) data[date] = [];
      data[activity.fecha]!.add(activity);
    }
    return data;
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  List<Activity> _getEventsForDay(DateTime day) {
    return _events[_normalizeDate(day)] ?? [];
  }

  bool _isDayEnabled(DateTime day) {
    return _workableDays.contains(day.weekday);
  }

  Future<List<Activity>> fetchActivities(String userId, String token) async {
    final baseUrl = Config.get('api_base_url');
    final url =
        Uri.parse('$baseUrl/api/activity/activitys?id=$userId&status=Aprobada');
    final response = await http.get(
      url,
      headers: {
        'Authorization':
            'Bearer $token', // Reemplaza 'tu_token_aqui' con tu token real
        'Content-Type':
            'application/json; charset=utf-8', // Ejemplo de otro encabezado opcional
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Activity.fromJson(json)).toList();
    } else if (response.statusCode == 204) {
      Future<List<Activity>> _activitiesFuture = Future.value([]);
      return _activitiesFuture;
    } else {
      throw Exception('Failed to load activities');
    }
  }

  void _showTimeSelectionDialog(
      DateTime selectedDay, List<Calendarioday> calendarDays) async {
    try {
      final eventsForDay = _getEventsForDay(selectedDay);

      int hourInicio = 0;
      int minutoInicio = 0;
      int hourFin = 0;
      int minutoFin = 0;

      for (var day in calendarDays) {
        hourInicio = int.parse(day.calendario.startTime.split(":")[0]);
        minutoInicio =
            int.parse(day.calendario.startTime.split(":")[1].substring(0, 2));
        hourFin = int.parse(day.calendario.endTime.split(":")[0]);
        minutoFin =
            int.parse(day.calendario.endTime.split(":")[1].substring(0, 2));
        break;
      }

      final startTime = TimeOfDay(
        hour: hourInicio,
        minute: minutoInicio,
      );

      final endTime = TimeOfDay(
        hour: hourFin,
        minute: minutoFin,
      );

      final selectedStartTime = await showDialog<TimeOfDay>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
                'Seleccionar Horas para el ${selectedDay.toLocal().toShortDateString()}'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(24, (index) {
                  final hour = TimeOfDay(hour: index, minute: 0);
                  final hourString =
                      '${hour.hour.toString().padLeft(2, '0')}:${hour.minute.toString().padLeft(2, '0')}';

                  bool isWithinWorkingHours =
                      hour.hour >= startTime.hour && hour.hour < endTime.hour;
                  final isOccupied = eventsForDay
                      .any((event) => event.startime.startsWith(hourString));

                  if (!isWithinWorkingHours) return Container();

                  return ListTile(
                    title: Text(hourString),
                    trailing: isOccupied
                        ? Icon(Icons.lock, color: Colors.red)
                        : Icon(Icons.check, color: Colors.green),
                    onTap: () {
                      if (!isOccupied) {
                        // _selectTimeRange(selectedDay);
                        Navigator.pop(context, hour);
                      }
                    },
                  );
                }),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cerrar'),
              ),
            ],
          );
        },
      );
      if (selectedStartTime != null) {
        _selectTimeRange(selectedDay, selectedStartTime);
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('No se encontró un día de calendario coincidente')),
      );
    }
  }

  void _selectTimeRange(DateTime selectedDay, TimeOfDay startHour) async {
    ActivityBussines? selectedActivity;
    DateTime? selectedStartTime;
    DateTime? selectedEndTime;

    // Mostrar el diálogo para seleccionar la actividad
    selectedActivity = await showDialog<ActivityBussines>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Seleccionar Actividad'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return DropdownButton<ActivityBussines>(
                hint: Text("Seleccionar Actividad"),
                value: selectedActivity,
                onChanged: (ActivityBussines? newValue) {
                  setState(() {
                    selectedActivity = newValue;
                  });
                },
                items: _activityBussines.map((ActivityBussines activity) {
                  return DropdownMenuItem<ActivityBussines>(
                    value: activity,
                    child: Text(activity.actividad),
                  );
                }).toList(),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(selectedActivity);
              },
              child: Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (selectedActivity == null) {
      // No se seleccionó ninguna actividad
      return;
    }

    selectedStartTime = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
      startHour.hour,
      startHour.minute,
    );

    selectedEndTime =
        selectedStartTime.add(Duration(minutes: selectedActivity!.tiempo));

    bool isConflicting = _getEventsForDay(selectedDay).any((event) {
      final eventStartTime = DateTime(
        selectedDay.year,
        selectedDay.month,
        selectedDay.day,
        int.parse(event.startime.split(":")[0]),
        int.parse(event.startime.split(":")[1].substring(0, 2)),
      );
      return selectedStartTime!.isAtSameMomentAs(eventStartTime) ||
          selectedStartTime!.isBefore(eventStartTime) &&
              selectedEndTime!.isAfter(eventStartTime);
    });

    if (isConflicting) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'El intervalo seleccionado se superpone con una actividad existente')),
      );
      return;
    }

    // Mostrar el precio y habilitar el botón para confirmar
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirmar Reserva'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Actividad: ${selectedActivity?.actividad}'),
              Text('Precio: ${selectedActivity?.precio}'),
              Text('Hora de inicio: ${startHour.format(context)}'),
              Text(
                  'Hora de fin: ${TimeOfDay.fromDateTime(selectedEndTime!).format(context)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _registrar(selectedDay, selectedStartTime!, selectedEndTime!,
                    selectedActivity!);
              },
              child: Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendario'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  calendarFormat: _calendarFormat,
                  onDaySelected: (selectedDay, focusedDay) {
                    if (_isDayEnabled(selectedDay)) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                      _showTimeSelectionDialog(selectedDay,
                          _calendarDays); // Aquí se pasan ambos argumentos
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Este día no es laborable')),
                      );
                    }
                  },
                  eventLoader: _getEventsForDay,
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  enabledDayPredicate: _isDayEnabled,
                ),
                const SizedBox(height: 8.0),
                Expanded(
                  child: ListView.builder(
                    itemCount: _getEventsForDay(_selectedDay).length,
                    itemBuilder: (context, index) {
                      final activity = _getEventsForDay(_selectedDay)[index];
                      return ListTile(
                        leading: Image.asset("lib/assets/perro.png",
                            width: 50, height: 50),
                        title: Text(activity.title),
                        subtitle: Text('${activity.startime} '),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class PaymentConfirmationScreen extends StatefulWidget {
  final String preferenceId;

  PaymentConfirmationScreen({required this.preferenceId});

  @override
  _PaymentConfirmationScreenState createState() =>
      _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  late Future<Map<String, dynamic>> paymentStatus;

  @override
  void initState() {
    super.initState();
    paymentStatus = _getPaymentStatus(widget.preferenceId);
  }

  Future<Map<String, dynamic>> _getPaymentStatus(String preferenceId) async {
    // URL de tu backend para verificar el estado del pago usando el preferenceId
    final baseUrl = Config.get('api_mercado_pago');
    final paymentStatusUrl = Uri.parse('$baseUrl/payment-status/$preferenceId');
    //final Uri paymentStatusUrl = Uri.parse('http://localhost:3000/payment-status/$preferenceId');

    final response = await http.get(paymentStatusUrl);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load payment status');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Confirmación de Pago'),
      ),
      body: Center(
        child: FutureBuilder<Map<String, dynamic>>(
          future: paymentStatus,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Text('No hay información de pago disponible.');
            } else {
              final paymentData = snapshot.data!;
              final status = paymentData['status'];

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Estado del Pago: $status'),
                  if (status == 'approved')
                    Icon(Icons.check_circle, color: Colors.green, size: 64.0),
                  if (status != 'approved')
                    Icon(Icons.error, color: Colors.red, size: 64.0),
                  Text('ID de Preferencia: ${widget.preferenceId}'),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}

class TipsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Tips',
        style: TextStyle(fontSize: 24.0),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  late String dialogflowSessionId = "your-session-id";  // Cambia esto a tu ID de sesión
  final String dialogflowProjectId = "firuapp-3696c";  // Cambia esto a tu ID de proyecto en Dialogflow
  //final String dialogflowToken = "Bearer ya29.c.c0ASRK0Gb-nWeWgl6ih9UiphWp0pTpkvinc-2TohVvdC5oLDAPbxBbFECYhEZEHyMN_OZ6V5i4-ZyI79PRkM-KMu5I8HIPs1FPxKtG9LP6WrRo7VAeyDwbyw6cRjC31msI0tkky69DOMYt3I9kulgBJPKg-WAmbxWmZw71qFm-l3_6AZVJUS2l_hjXlTe3cvNoti5SqcEOymm98gaRkqxSxyxofBZ_tdfp5f7QqrspwaeKnUzdX39t6nW_2GlffEtkMB-azUvXxdcwL9j27t-ojSD99xwxEAQW-dSnJgsNAtI6zs2SwKUFU6klJCAn34sbAUW6_PFqGoqg5eVO0MN2pSgzb9j9aNJsjn3Q0c8UEoled9ge91iNPxX_eOgp0s_-j5LViRQE400A7izUkUS_I3tBFaZ2U7Fil133lxvykBltwjjlJdOS90WiSF72ewtmzVIfqJuwB4vy2blWjQRj60Q71zMMnz3bRky3mYX2b_o47FReSJz610RX4tp9pU1RdtJ6q2bdBvoWs08MIziaWmUw8usac9OZsuBa7-nFwn_BkWuz7snWYchg0gc9Yvbh3B8aoYQYkb_0kSfM60jR2ikSed7n6F0rkXXqobXVxfv2dJhzBmm8ZwZZZSaXBQ9noWanvc-1xyS0R3cd130oW-3XsRIr55QwqWtgx6W59_j3YXgJWluXvkeckBbYOrewMI2dRRr3wU1lXFrXx04V3sYldbxOd7zUUFjeVWJxwl5SVJW8wkzdn4_Od-2BjF1wUvo9p1QpryoVgXMnSFzuJ32QUW5xe4f1Ws-SvlVkfIv6YOxVrhtV6a3BwRoFcb3eXQt92lhep1iUqgVxSuvo9Y4krQpvqazZ1h8XI_blb0biz40ejO4Oe__SnkwrIuknvgVcFlVmIXrJXzeSYQwvr4s3MfjViwjz_erx3mbj13mMSuBa8WVQudiy-SFyvM7fjp03w29edxMt8fW9Vb9VvVVy-2SbiwWVm_MJVqOiBe1Qrvjyw5sBrey";

  bool _isGreetingReceived = false;  // Indica si ya se ha recibido un saludo
  List<String> _dialogflowResponses = [];  // Lista para almacenar las respuestas de Dialogflow para los botones

  // Comienza a construir el mensaje completo con el subtítulo
  String fullMessage = "";
  bool bandera=false;
  Map<String, dynamic>? jsonData;

  @override
  void initState() {
    super.initState();
    if (context.mounted) {
      final session = Provider.of<SessionProvider>(context, listen: false);
      session.notifyListeners();
      dialogflowSessionId = session.user!.userId;
    }

    cargarJsonExterno();
  }

  Future<void> cargarJsonExterno() async {
    try {

      final url = Config.get('url_json_chatbot');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          jsonData = json.decode(response.body);
        });
      } else {
        print('Error al cargar el JSON: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<String?> getAccessTokenFromServiceAccount() async {
    try {

      // URL para obtener el token
     final url = Config.get('api_oauth2_googleapis');
      // Crear JWT (token Web)
      final jwt = createJwt(jsonData!);

      // Enviar solicitud POST para obtener el token de acceso
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          'assertion': jwt,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['access_token'];
      } else {
        print('Error obteniendo token: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

// Función para crear el JWT (JSON Web Token)
  String createJwt(Map<String, dynamic> serviceAccount) {
    final header = {
      'alg': 'RS256',
      'typ': 'JWT',
    };

    final now = DateTime.now();
    final claims = {
      'iss': serviceAccount['client_email'], // Email de la cuenta de servicio
      'scope': 'https://www.googleapis.com/auth/dialogflow', // Alcance para Dialogflow
      'aud': 'https://oauth2.googleapis.com/token', // Destinatario
      'exp': (now.millisecondsSinceEpoch / 1000 + 3600).round(), // Expira en 1 hora
      'iat': (now.millisecondsSinceEpoch / 1000).round(), // Hora actual
    };

    // Cargar la clave privada en formato PEM
    final privateKeyPem = serviceAccount['private_key'];

    // Eliminar los encabezados y pies de la clave
    final privateKey = privateKeyPem
        .replaceAll('-----BEGIN PRIVATE KEY-----', '')
        .replaceAll('-----END PRIVATE KEY-----', '')
        .replaceAll(RegExp(r'\s+'), ''); // Elimina los espacios en blanco

    // Decodificar la clave en bytes
    final privateKeyBytes = base64.decode(privateKey);

    // Crear el JWT con las claims y firmarlo con la clave privada
    final jwt = JWT(claims);

    // Firmar el JWT usando RS256 y la clave privada
    final token = jwt.sign(RSAPrivateKey(privateKeyPem), algorithm: JWTAlgorithm.RS256);

    return token;
  }

// Función para firmar el JWT usando la clave privada de la cuenta de servicio
  String signJwt(String input, String privateKey) {
    // Aquí debes implementar la firma usando RS256 (puedes usar la librería 'rsa_pkcs')
    // Añade la lógica de firma con la clave privada
    // Este es un ejemplo simple, necesitas incluir el código para la firma.
    return 'signed_data'; // Reemplazar con el JWT firmado
  }


  @override
  Widget build(BuildContext context) {
    final session = Provider.of<SessionProvider>(context, listen: false);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight), // Tamaño del AppBar estándar
        child: SafeArea( // Asegura que el AppBar no cubra la barra de estado
          child: AppBar(
            title: Text(
              'Chatea',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: const Color(0xFFA0E3A7), // Color verde menta de la marca
            elevation: 0,
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('messages').orderBy('timestamp').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                var messages = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: messages.length + 1, // Sumar 1 para incluir los botones
                  itemBuilder: (context, index) {
                    // Si el índice es mayor que el total de mensajes, muestra los botones
                    if (index == messages.length) {

                      return _buildResponseButtons(); // Aquí se agregan los botones debajo del último mensaje
                    }
                    var message = messages[index];
                    bool isUser = message['userid'] == session.user!.userId;  // Verificar si el mensaje es del usuario
                    bool isRobot= false;

                      if(message['sender']=='Chatbot' && message['userid'] == session.user!.userId)
                        isRobot=true;

                    return _buildMessageTile(message, isUser, isRobot);

                  },
                );
              },
            ),
          ),
          if (!_isGreetingReceived) _buildInitialMessageInput(),
        ],
      ),
    );
  }

  // Construir un mensaje en la lista de chat
  Widget _buildMessageTile(QueryDocumentSnapshot message, bool isUser, bool isRobot) {
    final session = Provider.of<SessionProvider>(context, listen: false);

    // Verificamos si el mensaje pertenece al usuario logueado
    if (message['userid'] != session.user!.userId) {
      return SizedBox.shrink(); // Retornamos un widget vacío si el mensaje no es del usuario logueado
    }

    String mensaje = message['text'];

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isRobot) _buildAvatar('robot'), // Si es el chatbot, muestra el avatar de robot
          if (isUser && !isRobot) _buildAvatar('user'),   // Si es el usuario, muestra su avatar

          SizedBox(width: 10),

          Expanded(
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue[100] : Colors.grey[300],  // Color para mensajes del usuario o chatbot
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                mensaje,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // Crear un avatar en función del remitente
  Widget _buildAvatar(String sender) {
    final session = Provider.of<SessionProvider>(context, listen: false);

    return CircleAvatar(
      radius: 20,
      backgroundImage: sender == 'user'
          ? NetworkImage(session.user!.photo)
          : Utiles.getDefaultImageForSpecies(sender),  // Si no, se utiliza la imagen local predeterminada
      onBackgroundImageError: (error, stackTrace) {
        print('Error cargando la imagen del usuario: $error');
      },
    );
  }

  // Mostrar el input inicial para enviar un saludo
  Widget _buildInitialMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(hintText: 'Escribe un saludo...'),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: _handleInitialMessage,
          ),
        ],
      ),
    );
  }

  // Manejar el mensaje inicial (debe ser un saludo)
  void _handleInitialMessage() {
    final session = Provider.of<SessionProvider>(context, listen: false);

    if (_controller.text.isNotEmpty) {
      // Verificamos si el mensaje es un saludo
      if (_isGreeting(_controller.text)) {
        FirebaseFirestore.instance.collection('messages').add({
          'text': _controller.text,
          'userid': session.user!.userId,
          'sender': 'User',
          'timestamp': FieldValue.serverTimestamp(),
        });
        //_controller.clear();

        // Dialogflow responde al saludo
        _getChatbotResponse(_controller.text, afterGreeting: true);
      } else {
        _showError('Por favor, escribe un saludo para comenzar.');
      }
    }
  }

  // Verifica si el mensaje es un saludo
  bool _isGreeting(String message) {
    final greetings = ['hola', 'buenos días', 'buenas tardes', 'buenas noches', 'buenas', 'hi','hello'];
    return greetings.any((greeting) => message.toLowerCase().contains(greeting));
  }

  // Mostrar error en caso de que no se detecte un saludo
  void _showError(String errorMessage) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
  }

  // Llamada a Dialogflow para procesar un mensaje y obtener una Basic Card
  Future<void> _getChatbotResponse(String message, {bool afterGreeting = false}) async {
    final String dialogflowUrl =
        'https://dialogflow.googleapis.com/v2/projects/$dialogflowProjectId/agent/sessions/$dialogflowSessionId:detectIntent';

    final response = await http.post(
      Uri.parse(dialogflowUrl),
      headers: {
        'Authorization': 'Bearer ${await getAccessTokenFromServiceAccount()}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "query_input": {
          "text": {
            "text": message,
            "language_code": "es",
          }
        }
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      _dialogflowResponses.clear();
      // Si el saludo ha sido recibido, mostramos la tarjeta con las opciones de mascota
      if (!_isGreetingReceived) {
        _showPetCard(data);
        setState(() {
          _isGreetingReceived = true;
        });
      } else {

        _showPetCard(data);
      }
    } else {
      print('Error al contactar con Dialogflow: ${response.statusCode}');
    }
  }
// Manejar respuestas de Dialogflow para opciones de mascotas
  void _showPetCard(Map<String, dynamic> data) {
    final session = Provider.of<SessionProvider>(context, listen: false);
    _dialogflowResponses.clear();  // Limpiar respuestas anteriores

    // Verifica que fulfillmentMessages existe y es una lista
    if (data['queryResult'] != null && data['queryResult']['fulfillmentMessages'] != null) {
      List<dynamic> fulfillmentMessages = data['queryResult']['fulfillmentMessages'];

      // Itera sobre los mensajes para buscar una tarjeta o botones en el payload
      for (var message in fulfillmentMessages) {
        // Primero, aseguramos que el mensaje tiene un 'payload'
        if (message.containsKey('payload')) {
          // Si el payload contiene una card o algo similar
          if (message['payload'].containsKey('card')) {
            var card = message['payload']['card'];
            if (card.containsKey('line')) {
              String line = card['line'];
              if(line=='SI'){
                _handleResponses(data);
              }else{


                // Guardar y mostrar el subtítulo si existe
                if (card.containsKey('title')) {
                  String subtitle = card['title'];
                  fullMessage += subtitle + "\n\n";  // Añadir subtítulo al mensaje completo

                  FirebaseFirestore.instance.collection('messages').add({
                    'text': subtitle,
                    'userid': session.user!.userId,
                    'sender': 'Chatbot',
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                }

                // Procesar los botones y añadirlos al mensaje completo
                if (card.containsKey('buttons')) {
                  List<dynamic> buttons = card['buttons'];

                  // Añadir cada botón al mensaje completo
                  for (var button in buttons) {
                    fullMessage += "- " + button['text'] + "\n";  // Formato: Lista de botones

                    // Mostrar cada botón en la interfaz
                    setState(() {
                      _dialogflowResponses.add(button['text']);  // Añadir el botón a las respuestas de Dialogflow
                    });
                  }
                }

              }
            }



            // Guardar el mensaje completo (con subtítulo y botones) en Firebase cuando el usuario seleccione una opción
         /*   FirebaseFirestore.instance.collection('messages').add({
              'text': fullMessage,  // Guardar todo el mensaje junto
              'userid': '',
              'sender': 'Chatbot',
              'timestamp': FieldValue.serverTimestamp(),
            });*/
          }else{
            _handleResponses(data);

          }
        }else{
          _handleResponses(data);
        }
      }
    }
  }

// Enviar mensaje basado en la opción seleccionada
  void _sendMessage(String selectedResponse) {
    final session = Provider.of<SessionProvider>(context, listen: false);
    /* if(bandera){
       FirebaseFirestore.instance.collection('messages').add({
         'text': fullMessage,  // Guardar todo el mensaje junto
         'userid': '',
         'sender': 'Chatbot',
         'timestamp': FieldValue.serverTimestamp(),
       });
       bandera=false;
     }*/

    // Guardar la selección del botón sin duplicar el mensaje completo
    FirebaseFirestore.instance.collection('messages').add({
      'text': selectedResponse,
      'userid': session.user!.userId,
      'sender': 'User',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Luego de seleccionar el botón, enviar la respuesta a Dialogflow y obtener la respuesta relacionada
    _getChatbotResponse(selectedResponse);
  }

// Construir botones con las respuestas de Dialogflow
  Widget _buildResponseButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _dialogflowResponses.map((response) {
          return Column(
            children: [
              ElevatedButton.icon(
                label: Text(response),
                onPressed: () {
                  // Al seleccionar el botón, solo guarda el texto del botón, no lo vuelvas a mostrar como respuesta duplicada
                  _sendMessage(response);
                  _dialogflowResponses.clear();

                },
              ),
              SizedBox(height: 10),
            ],
          );
        }).toList(),
      ),
    );
  }



  // Manejar respuestas normales (texto) de Dialogflow
  void _handleResponses(Map<String, dynamic> data) {
    _dialogflowResponses.clear();  // Limpiar respuestas anteriores
    final session = Provider.of<SessionProvider>(context, listen: false);

    List<dynamic> fulfillmentMessages = data['queryResult']['fulfillmentMessages'];
    for (var message in fulfillmentMessages) {
      if (message['text'] != null) {
        String botMessage = message['text']['text'][0];
        if(botMessage!=""){
          // Guardar la selección del botón sin duplicar el mensaje completo
          FirebaseFirestore.instance.collection('messages').add({
            'text': botMessage,
            'userid': session.user!.userId,
            'sender': 'Chatbot',
            'timestamp': FieldValue.serverTimestamp(),
          });
        }


      }
    }
  }




}



class SubscriptionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Suscripciones'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Elige tu plan de suscripción:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  SubscriptionPlan(
                    color: Colors.green,
                    title: 'Básico',
                    price: '\$5.00',
                    features: [
                      'Acceso a contenido básico',
                      'Soporte limitado',
                      'Actualizaciones mensuales'
                    ],
                    onSubscribe: () {
                      // Implementar suscripción utilizando Mercado Pago
                      print('Suscribirse al plan Básico');
                    },
                  ),
                  SubscriptionPlan(
                    color: Colors.red,
                    title: 'Estándar',
                    price: '\$15.00',
                    features: [
                      'Acceso a contenido estándar',
                      'Soporte prioritario',
                      'Actualizaciones semanales'
                    ],
                    onSubscribe: () {
                      // Implementar suscripción utilizando Mercado Pago
                      print('Suscribirse al plan Estándar');
                    },
                  ),
                  SubscriptionPlan(
                    color: Colors.black,
                    title: 'Premium',
                    price: '\$30.00',
                    features: [
                      'Acceso a todo el contenido',
                      'Soporte 24/7',
                      'Actualizaciones diarias'
                    ],
                    onSubscribe: () {
                      // Implementar suscripción utilizando Mercado Pago
                      print('Suscribirse al plan Premium');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SubscriptionPlan extends StatelessWidget {
  final Color color;
  final String title;
  final String price;
  final List<String> features;
  final VoidCallback onSubscribe;

  const SubscriptionPlan({
    required this.color,
    required this.title,
    required this.price,
    required this.features,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              price,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            ...features.map((feature) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Icon(Icons.check, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                          child: Text(feature,
                              style: TextStyle(color: Colors.white))),
                    ],
                  ),
                )),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: onSubscribe,
              child: Text('Suscribirse'),
              style: ElevatedButton.styleFrom(
                foregroundColor: color,
                backgroundColor: Colors.white, // Color del texto del botón
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  @override
  _ProfileManagementPageState createState() => _ProfileManagementPageState();
}

class _ProfileManagementPageState extends State<ProfilePage> {
  final _picker = ImagePicker();
  File? _profileImage;
  bool _isEditing = false;

  // Controladores para las contraseñas
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final session = Provider.of<SessionProvider>(context, listen: false);
        session.notifyListeners();
      }
    });


  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
      // Llama al método para actualizar la imagen en la base de datos
      await _updateProfileImage(pickedFile);
    }
  }

  Future<void> _updateProfileImage(XFile pickedFile) async {
    final session = Provider.of<SessionProvider>(context, listen: false);

    // Convert the image to base64
    final bytes = await pickedFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    // Call the API to update the image in the database
    final response = await http.post(
      Uri.parse('${Config.get('api_base_url')}/api/user/update-photo'),
      headers: {
        'Authorization': 'Bearer ${session.token!}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'photo': base64Image,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Foto de perfil actualizada exitosamente')),
      );
      // Update the photo in the session

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar la foto de perfil')),
      );
    }
  }

  void _showImageSourceDialog() {
    final session = Provider.of<SessionProvider>(context, listen: false);

    // Check if the platform is "manual"
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Select Profile Picture'),
            actions: [
              TextButton(
                onPressed: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
                child: Text('Take a Photo'),
              ),
              TextButton(
                onPressed: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
                child: Text('Choose from Gallery'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancel'),
              ),
            ],
          );
        },
      );

  }


  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    final user = sessionProvider.user; // Obtener el usuario logueado

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight), // Tamaño del AppBar estándar
        child: SafeArea( // Asegura que el AppBar no cubra la barra de estado
          child: AppBar(
            title: Text(
              'Perfil',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: const Color(0xFFA0E3A7), // Color verde menta de la marca
            elevation: 0,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: user!.photo != null
                          ? (user.photo.startsWith('http')
                          ? NetworkImage(user.photo) // Cargar imagen desde URL
                          : MemoryImage(base64Decode(user!.photo)) // Opción para manejar base64, en caso de ser necesario
                      ) as ImageProvider
                          : null,
                      child: user.photo == null
                          ? Icon(Icons.person, size: 60) // Icono de persona si no hay imagen
                          : null,

                    ),

                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: _showImageSourceDialog,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 20),
                Divider(height: 1, color: Colors.grey),
                // Opciones de perfil
                ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Editar Perfil'),
                  onTap: () {
                    Navigator.pushNamed(context, '/editProfile');
                  },
                ),
               /* ListTile(
                  title: Text('Suscripciones'),
                  leading: Icon(Icons.subscriptions, color: Colors.blue),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubscriptionPage(),
                      ),
                    );
                  },
                ),*/
                ListTile(
                  leading: Icon(Icons.add_box_outlined),
                  title: Text('Nuevo perfil'),
                  onTap: () {
                    _showAssignRoleModal(context, sessionProvider.user!.userId);

                  },
                ),

                ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Cerrar Sesión'),
                  onTap: () {
                    // Eliminar la sesión y redirigir a la página de login
                    Provider.of<SessionProvider>(context, listen: false)
                        .signOut(context);
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }





  void _showAssignRoleModal(BuildContext context, String userId) {
    String? selectedRole;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('user_perfil').get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final rolesData = snapshot.data!.docs
                    .map((doc) => {
                  'id': doc['id'],
                  'perfil': doc['perfil'],
                })
                    .toList();

                // 🔹 Obtener los perfiles asignados del `SessionProvider`
                final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
                final assignedRoles = sessionProvider.perfil;

                // 🔹 Filtrar roles que ya tiene el usuario
                List<Map<String, dynamic>> availableRoles = rolesData.map((role) {
                  bool isAssigned = assignedRoles.any((assignedRole) => assignedRole.id == role['id']);
                  return {
                    'id': role['id'],
                    'perfil': role['perfil'],
                    'isAssigned': isAssigned,
                  };
                }).toList();

                return Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 🔹 Encabezado
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFA0E3A7),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                          ),
                          padding: EdgeInsets.all(15),
                          child: Center(
                            child: Text(
                              "Selecciona un perfil",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),

                        // 🔹 Selector de Perfil (Dropdown)
                        Padding(
                          padding: EdgeInsets.all(15),
                          child: DropdownButtonFormField<int>(
                            decoration: InputDecoration(
                              labelText: "Perfil",
                              border: OutlineInputBorder(),
                            ),
                            value: selectedRole != null ? int.tryParse(selectedRole!) : null,
                            items: availableRoles.map<DropdownMenuItem<int>>((role) {
                              return DropdownMenuItem<int>(
                                value: role['id'],
                                enabled: !role['isAssigned'], // 🔹 Deshabilitar si ya está asignado
                                child: Text(
                                  role['perfil'],
                                  style: TextStyle(
                                    color: role['isAssigned'] ? Colors.grey : Colors.black,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (int? value) {
                              setState(() {
                                selectedRole = value.toString();
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Por favor selecciona un perfil';
                              }
                              return null;
                            },
                          ),
                        ),

                        // 🔹 Botones de acción
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // 🔹 Botón Cancelar
                              TextButton(
                                child: Text(
                                  "Cancelar",
                                  style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.red),
                                ),
                                onPressed: () {
                                  Navigator.of(dialogContext, rootNavigator: true).pop();
                                },
                              ),

                              // 🔹 Botón Guardar con loader
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () async {
                                  if (selectedRole != null) {
                                    bool alreadyAssigned = assignedRoles.any((role) => role.id == int.parse(selectedRole!));

                                    if (alreadyAssigned) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text("Este perfil ya está asignado."),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                      return;
                                    }

                                    Navigator.of(dialogContext, rootNavigator: true).pop();

                                    // 🔹 Mostrar loader
                                    BuildContext? loaderContext;
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (BuildContext loadingContext) {
                                        loaderContext = loadingContext;
                                        return Dialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                          child: Padding(
                                            padding: EdgeInsets.all(20),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                CircularProgressIndicator(),
                                                SizedBox(height: 20),
                                                Text(
                                                  "Asignando perfil...",
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 16,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );

                                    try {
                                      // 🔹 Guardar el nuevo perfil en Firestore
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(userId)
                                          .collection('roles')
                                          .add({
                                        'roles': {
                                          'id': int.parse(selectedRole!),
                                          'perfil': availableRoles
                                              .firstWhere((role) => role['id'] == int.parse(selectedRole!))['perfil'],
                                        },
                                        'assigned_at': Timestamp.now(),
                                      });

                                      // 🔹 Actualizar la lista de perfiles en SessionProvider
                                      List<Perfil> updatedProfiles = [
                                        ...sessionProvider.perfil,
                                        Perfil(
                                          id: int.parse(selectedRole!),
                                          perfil: availableRoles
                                              .firstWhere((role) => role['id'] == int.parse(selectedRole!))['perfil'],
                                        ),
                                      ];
                                      sessionProvider.setUserPerfil(updatedProfiles);

                                      // 🔹 Cerrar loader correctamente
                                      if (loaderContext?.mounted ?? false) {
                                        Navigator.of(loaderContext!, rootNavigator: true).pop();
                                      }

                                      // ✅ **Notificar a la UI**
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text("Perfil asignado correctamente."),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (loaderContext?.mounted ?? false) {
                                        Navigator.of(loaderContext!, rootNavigator: true).pop();
                                      }

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text("Error al asignar perfil."),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text("Por favor selecciona un perfil."),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Text(
                                  "Guardar",
                                  style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }


}
