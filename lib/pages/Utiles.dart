import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

import '../class/UserInteraction.dart';

class Utiles {


  static void showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }


  static void showErrorDialogBoton({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.blue),
              SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static void showErrorDialog({
    required BuildContext context,
    required String title,
    required String content,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white, // Fondo blanco limpio
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), // Bordes redondeados
          ),
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red), // Icono de error en rojo
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Poppins', // Tipografía de la marca
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // Título en negro
                ),
              ),
            ],
          ),
          content: Text(
            content,
            style: TextStyle(
              fontFamily: 'Poppins', // Tipografía de la marca
              fontSize: 16,
              color: Colors.grey[800], // Texto del contenido en gris oscuro
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.green, // Color verde menta para el botón
              ),
              child: Text(
                'OK',
                style: TextStyle(
                  fontFamily: 'Poppins', // Tipografía del botón
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }


  static void showErrorDialogUNAUTHORIZED({
    required BuildContext context,
    required String title,
    required String content,
  })  {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static void showLoadingDialog({required BuildContext context}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  static void showInfoDialog({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info, color: Colors.blue),
              SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  static bool isValidEmail(String email) {
    // Expresión regular para validar un correo electrónico
    // Esta expresión regular es bastante básica y podría ajustarse según tus necesidades específicas
    final RegExp emailRegex =
    RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    return emailRegex.hasMatch(email);
  }

  static ImageProvider getDefaultImageForSpecies(String especie) {
    switch (especie) {
      case 'Perro': // Especie es perro
        return AssetImage('lib/assets/perro_patica.png');
      case 'Gato': // Especie es gato
        return AssetImage('lib/assets/gato_patica.png');
      case 'robot': // Especie es gato
        return AssetImage('lib/assets/robot_avatar.png');
    // Puedes agregar más casos para otras especies
      default:
        return AssetImage('lib/assets/sin_imagen.png'); // Imagen predeterminada si no es perro ni gato
    }
  }

  static ImageProvider buildImageBase64(String base64String, String especie) {
    try {
      if(base64String==""){
        if(especie=='Perro'){
          return AssetImage('lib/assets/perro_patica.png');
        }else if(especie=='Gato'){
          return AssetImage('lib/assets/gato_patica.png');
        }
        else{
          return AssetImage('lib/assets/sin_imagen.png');
        }
      }else{
        // Decodificar la cadena base64
        return MemoryImage(base64Decode(base64String));
      }


    } catch (e) {
      // Si ocurre un error, usar una imagen por defecto
      print('Error al decodificar la imagen base64: $e');
      if(especie=='Perro'){
        return AssetImage('lib/assets/perro_patica.png');
      }else if(especie=='Gato'){
        return AssetImage('lib/assets/gato_patica.png');
      }
      else{
        return AssetImage('lib/assets/sin_imagen.png');
      }
    }
  }


  static Future<String> imageToBase64(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        return base64Encode(bytes);
      } else {
        Uint8List defaultImageBytes;
        print('Error al descargar la imagen: ${response.statusCode}');
        defaultImageBytes = (await rootBundle.load('lib/assets/sin_imagen.png')).buffer.asUint8List();
        return base64Encode(defaultImageBytes);
      }
    } catch (e) {
      Uint8List defaultImageBytes;
      defaultImageBytes = (await rootBundle.load('lib/assets/sin_imagen.png')).buffer.asUint8List();
      return base64Encode(defaultImageBytes);
    }
  }

  static Future<MemoryImage> buildMemoryImageBase64(String base64String, String especie) async {
    try {
      if (base64String.isEmpty) {
        // Si base64String está vacío, usar una imagen predeterminada
        Uint8List defaultImageBytes;

        // Dependiendo de la especie, cargar la imagen predeterminada en bytes
        if (especie == 'Perro') {
          defaultImageBytes = (await rootBundle.load('lib/assets/perro_patica.png')).buffer.asUint8List();
    } else if (especie == 'Gato') {
    defaultImageBytes = (await rootBundle.load('lib/assets/gato_patica.png')).buffer.asUint8List();
    } else {
    defaultImageBytes = (await rootBundle.load('lib/assets/sin_imagen.png')).buffer.asUint8List();
    }

    return MemoryImage(defaultImageBytes);
    } else {
    // Decodificar la cadena base64
    Uint8List decodedBytes = base64Decode(base64String);
    return MemoryImage(decodedBytes);
    }
    } catch (e) {
    // Si ocurre un error, usar una imagen predeterminada
    print('Error al decodificar la imagen base64: $e');
    Uint8List errorImageBytes;

    if (especie == 'Perro') {
    errorImageBytes = (await rootBundle.load('lib/assets/perro_patica.png')).buffer.asUint8List();
    } else if (especie == 'Gato') {
    errorImageBytes = (await rootBundle.load('lib/assets/gato_patica.png')).buffer.asUint8List();
    } else {
    errorImageBytes = (await rootBundle.load('lib/assets/sin_imagen.png')).buffer.asUint8List();
    }

    return MemoryImage(errorImageBytes);
    }
  }


  static void logUserInteraction(String userId, String action, {Map<String, dynamic>? additionalData}) {
    UserInteraction interaction = UserInteraction(
      userId: userId,
      action: action,
      timestamp: DateTime.now(),
      additionalData: additionalData,
    );

    // Guarda la interacción en la base de datos
    saveInteractionToDatabase(interaction);
  }

 static void saveInteractionToDatabase(UserInteraction interaction) async {
    await FirebaseFirestore.instance.collection('user_interactions').add(interaction.toJson());
  }

  static String getId(){
    final Uuid uuid = Uuid();
    return  uuid.v4();

  }

}
