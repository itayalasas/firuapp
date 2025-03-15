import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';


import '../services/FirebaseNotificationService.dart';

class AdoptionChatForOfertantePage extends StatefulWidget {
  final String mascotaId;
  final String interesadoId;
  final String ofertanteId;
  final Map<String, dynamic> mascotaData;

  AdoptionChatForOfertantePage({
    required this.mascotaId,
    required this.interesadoId,
    required this.ofertanteId,
    required this.mascotaData,
  });

  @override
  _AdoptionChatForOfertantePageState createState() => _AdoptionChatForOfertantePageState();
}

class _AdoptionChatForOfertantePageState extends State<AdoptionChatForOfertantePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? chatId;
  String interesadoFcmToken = "";
  String ofertanteFcmToken = "";

  @override
  void initState() {
    super.initState();
    _initializeChatOfert();
  }

  /// **🔹 Busca el chat entre el ofertante y el interesado**
  Future<void> _initializeChatOfert() async {
    chatId = await _getChatId(widget.ofertanteId, widget.interesadoId, widget.mascotaId);

    if (chatId != null) {
      // Cargar tokens de FCM
      await _fetchUserTokens();
      setState(() {
        _listenToNewMessagesOfert();
      });
    }
  }

  /// **🔹 Buscar un chat existente**
  Future<String?> _getChatId(String ofertanteId, String interesadoId, String mascotaId) async {
    QuerySnapshot chatQuery = await _firestore
        .collection('chats')
        .where('mascotaId', isEqualTo: mascotaId)
        .where('interesadoId', isEqualTo: interesadoId)
        .where('ofertanteId', isEqualTo: ofertanteId)
        .limit(1)
        .get();

    if (chatQuery.docs.isNotEmpty) {
      return chatQuery.docs.first.id;
    }
    return null;
  }

  /// **🔹 Obtener los tokens de FCM del interesado y ofertante**
  Future<void> _fetchUserTokens() async {
    var interesadoDoc = await _firestore.collection("users").doc(widget.interesadoId).get();
    var ofertanteDoc = await _firestore.collection("users").doc(widget.ofertanteId).get();

    setState(() {
      interesadoFcmToken = interesadoDoc.data()?["fcmToken"] ?? "";
      ofertanteFcmToken = ofertanteDoc.data()?["fcmToken"] ?? "";
    });
  }

  /// **🔹 Escuchar nuevos mensajes en tiempo real**
  void _listenToNewMessagesOfert() {
    if (chatId == null) return;

    _firestore.collection('chats').doc(chatId).collection('mensajes')
        .where('notificadoInteresado', isEqualTo: false)
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
          //if (senderId != widget.ofertanteId) {
            String fcmToken = receiverId == widget.ofertanteId ? ofertanteFcmToken : interesadoFcmToken;
            if (fcmToken.isNotEmpty) {
              FirebaseNotificationService.sendNotification(fcmToken, "Nuevo mensaje", messageText, "messaging");
            }
        //  }

          doc.doc.reference.update({'notificadoInteresado': true});
        }
      }
    });
  }


  /// **🔹 Enviar un mensaje**
  void _sendMessageOfert() async {
    if (_controller.text.trim().isNotEmpty && chatId != null) {
      String mensaje = _controller.text.trim();
      String senderId = widget.ofertanteId;
      String destinatarioId = widget.interesadoId;

      await _firestore.collection('chats').doc(chatId).collection('mensajes').add({
        'remitente': senderId,
        'destinatario': destinatarioId,
        'mensaje': mensaje,
        'timestamp': FieldValue.serverTimestamp(),
        'notificadoInteresado': false,
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
              'Chat con interesado',
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
          ? Center(child: CircularProgressIndicator())
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
    bool isUserRemitente = data['remitente'] == widget.ofertanteId;
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
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(hintText: 'Escribe un mensaje...'),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: Colors.green),
            onPressed: _sendMessageOfert,
          ),
        ],
      ),
    );
  }
}
