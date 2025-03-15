import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../class/SessionProvider.dart';
import '../services/FirebaseNotificationService.dart';
import 'Config.dart';

class AdoptionListPage extends StatefulWidget {
  @override
  _AdoptionListPageState createState() => _AdoptionListPageState();
}
class _AdoptionListPageState extends State<AdoptionListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final int _limit = 5;
  DocumentSnapshot? _lastDocument;
  bool _isLoading = true;
  bool _hasMore = true;
  List<DocumentSnapshot> _mascotas = [];
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchMascotas();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _fetchMascotas() async {
    if (!_hasMore) return; // 🔹 Evitar consultas innecesarias

    setState(() => _isLoading = true);

    Query query = _firestore
        .collection('adopciones')
        .where('estado', whereIn: ['Para Adoptar', 'Con Interesados'])
        .orderBy('fecha_registro', descending: true)
        .limit(_limit);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    QuerySnapshot snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      _lastDocument = snapshot.docs.last;
      setState(() {
        _mascotas.addAll(snapshot.docs);
        _hasMore = snapshot.docs.length == _limit; // 🔹 Si devuelve menos de `_limit`, no hay más datos
      });
    } else {
      setState(() => _hasMore = false); // 🔹 No hay más datos
    }

    setState(() => _isLoading = false); // 🔹 Deshabilitar loader después de cargar
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent &&
        !_isLoading &&
        _hasMore) {
      _fetchMascotas();
    }
  }

  @override
  Widget build(BuildContext context) {
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
              'Mascotas en adopción',
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
      body: _isLoading && _mascotas.isEmpty
          ? Center(child: CircularProgressIndicator()) // 🔹 Loader solo si la lista está vacía
          : ListView.builder(
        controller: _scrollController,
        itemCount: _mascotas.length + (_hasMore ? 1 : 0), // 🔹 Solo agregar loader si hay más datos
        itemBuilder: (context, index) {
          if (index < _mascotas.length) {
            return _buildAdoptionCard(_mascotas[index]);
          } else {
            return _hasMore
                ? Center(child: CircularProgressIndicator()) // 🔹 Loader al final si hay más datos
                : SizedBox.shrink(); // 🔹 Ocultar loader si no hay más datos
          }
        },
      ),
    );
  }

  Widget _buildAdoptionCard(DocumentSnapshot mascotaDoc) {
    var data = mascotaDoc.data() as Map<String, dynamic>;

    List<String> imagenes = [];
    if (data.containsKey('imagenes') && data['imagenes'] is List) {
      imagenes = List<String>.from(data['imagenes']);
    }

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
            Text("Albergue: ${data['albergue'] ?? 'No especificado'}", style: TextStyle(fontSize: 16)),
            Text("Teléfono: ${data['telefono'] ?? 'No disponible'}", style: TextStyle(fontSize: 16)),
            Text("Dirección: ${data['direccion'] ?? 'No especificada'}", style: TextStyle(fontSize: 16)),
            Text("Estado: ${data['estado'] ?? 'No definido'}",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdoptionChatPage(mascota: data),
                  ),
                );
              },
              child: Text(
                'Adoptar',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Color verde menta para el botón "Adoptar"
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}


class AdoptionChatPage extends StatefulWidget {
  final Map<String, dynamic> mascota;

  AdoptionChatPage({required this.mascota});

  @override
  _AdoptionChatPageState createState() => _AdoptionChatPageState();
}

class _AdoptionChatPageState extends State<AdoptionChatPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? chatId;
  late String interesadoId;
  late String ofertanteId;
  String interesadoFcmToken = "";
  String ofertanteFcmToken = "";

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final session = Provider.of<SessionProvider>(context, listen: false);
    interesadoId = session.user!.userId;
    ofertanteId = widget.mascota['userId'];

    await _fetchOfertanteInfo();

    chatId = await _getOrCreateChat(interesadoId, ofertanteId, widget.mascota['mascotaId']);

    // Notificar que el estado ha cambiado para que se vuelva a construir el widget
    setState(() {
      _listenToNewMessages();
    });
  }

  /// **🔹 Obtener la información del ofertante**
  Future<void> _fetchOfertanteInfo() async {
    QuerySnapshot adopcionQuery = await _firestore
        .collection('adopciones')
        .where('mascotaId', isEqualTo: widget.mascota['mascotaId'])
        .limit(1)
        .get();

    if (adopcionQuery.docs.isNotEmpty) {
      var adopcionData = adopcionQuery.docs.first.data() as Map<String, dynamic>;

      setState(() {
        ofertanteId = adopcionData['userId'];
        ofertanteFcmToken = adopcionData['fcmToken'] ?? "";
      });
    }
  }

  /// **🔹 Obtener o crear un chat**
  Future<String> _getOrCreateChat(String interesadoId, String ofertanteId, String mascotaId) async {
    QuerySnapshot chatQuery = await _firestore
        .collection('chats')
        .where('mascotaId', isEqualTo: mascotaId)
        .where('interesadoId', isEqualTo: interesadoId)
        .where('ofertanteId', isEqualTo: ofertanteId)
        .limit(1)
        .get();

    if (chatQuery.docs.isNotEmpty) {
      return chatQuery.docs.first.id;
    } else {
      final session = Provider.of<SessionProvider>(context, listen: false);
      DocumentReference newChatRef = await _firestore.collection('chats').add({
        'mascotaId': mascotaId,
        'interesadoId': interesadoId,
        'ofertanteId': ofertanteId,
        'interesadoFcmToken': session.user?.fcmToken,
        'ofertanteFcmToken': ofertanteFcmToken,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return newChatRef.id;
    }
  }

  /// **🔹 Escuchar nuevos mensajes en tiempo real**
  void _listenToNewMessages() {
    if (chatId == null) return;

    _firestore.collection('chats').doc(chatId).collection('mensajes')
        .where('notificadoOfertante', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docChanges) {
        if (doc.type == DocumentChangeType.added) {
          final newMessage = doc.doc.data();
          String senderId = newMessage?['remitente'];
          String receiverId = newMessage?['destinatario'];
          String messageText = newMessage?['mensaje'];

          print("📩 Nuevo mensaje de $senderId para $receiverId: $messageText");

          // ✅ Solo enviar notificación si el mensaje NO fue enviado por el usuario actual
          //if (senderId != interesadoId) {
            String fcmToken = receiverId == ofertanteId ? ofertanteFcmToken : interesadoFcmToken;
            if (fcmToken.isNotEmpty) {
              FirebaseNotificationService.sendNotification(fcmToken, "Nuevo mensaje", messageText, "messaging");
            }
          //}

          doc.doc.reference.update({'notificadoOfertante': true});
        }
      }
    });
  }


  /// **🔹 Enviar un mensaje**
  void _sendMessage() async {
    if (_controller.text.trim().isNotEmpty && chatId != null) {
      String mensaje = _controller.text.trim();
      final session = Provider.of<SessionProvider>(context, listen: false);
      String userId = session.user!.userId;

      String destinatarioId = userId == interesadoId ? ofertanteId : interesadoId;

      await _firestore.collection('chats').doc(chatId).collection('mensajes').add({
        'remitente': userId,
        'destinatario': destinatarioId,
        'mensaje': mensaje,
        'timestamp': FieldValue.serverTimestamp(),
        'notificadoOfertante': false,
      });

      _controller.clear();
      _scrollToBottom();
    }
  }

  /// **🔹 Desplazar al último mensaje**
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
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
              'Chat de Adopción',
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
      body: chatId == null
          ? Center(child: CircularProgressIndicator()) // 🟢 Espera hasta que `chatId` se obtenga
          : Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('chats').doc(chatId).collection('mensajes')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error al cargar mensajes"));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No hay mensajes aún"));
                }

                var messages = snapshot.data!.docs;
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    return _buildMessageBubble(message);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(DocumentSnapshot message) {
    var data = message.data() as Map<String, dynamic>;
    bool isUserRemitente = data['remitente'] == interesadoId;
    String messageText = data['mensaje'];

    return Align(
      alignment: isUserRemitente ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isUserRemitente ? Colors.green[300] : Colors.grey[300],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(messageText, style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Material(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send, color: Colors.green),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

