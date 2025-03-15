import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../class/User.dart' as usuario;
import '../pages/Config.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<int> registerWithEmailAndPassword(String password, usuario.User us, File _imageFile) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: us.username,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        String imageUrl = await uploadProfilePicture(user.uid, _imageFile);
        await user.updateProfile(displayName: us.phone, photoURL: imageUrl);
        await user.reload();

        us.photo = imageUrl;
        us.firebaseUid = user.uid;

        return await _saveUserToDatabase(us);
      }
    } on FirebaseAuthException catch (e) {
      return _manejarErroresFirebase(e);
    }

    return 0;
  }

// Función auxiliar para manejar errores de Firebase
  static int _manejarErroresFirebase(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 301;
      case 'wrong-password':
        return 302;
      case 'network-request-failed':
        return 303;
      case 'weak-password':
        return 304;
      case 'firebase_auth':
        return 305;
      default:
        return 500; // Código para error desconocido
    }
  }


//      _auth.currentUser!.delete();
  // Método para subir la imagen a Firebase Storage
  static Future<String> uploadProfilePicture(String uid, File file) async {
    try {
      // Leer la imagen desde el archivo
      Uint8List imageBytes = await file.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception("No se pudo procesar la imagen");
      }

      // Redimensionar la imagen para optimizarla (similar a WhatsApp)
      img.Image resizedImage = img.copyResize(
        image,
        width: 1600, // Resolución similar a WhatsApp
        height: (1600 * image.height ~/ image.width), // Mantener relación de aspecto
      );

      // Convertir la imagen a JPEG comprimido (calidad 80%)
      Uint8List compressedImage = Uint8List.fromList(
        img.encodeJpg(resizedImage, quality: 80),
      );

      // Subir la imagen optimizada a Firebase Storage
      Reference ref = _storage.ref().child('profile_pictures/$uid.jpg');
      UploadTask uploadTask = ref.putData(compressedImage, SettableMetadata(contentType: 'image/jpeg'));

      // Escuchar el progreso de la subida
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = (snapshot.bytesTransferred.toDouble() / snapshot.totalBytes.toDouble()) * 100;
        print("Progreso de la subida: $progress%");
      }, onError: (e) {
        print("Error durante la subida: $e");
      });

      // Esperar a que se complete la carga
      TaskSnapshot snapshot = await uploadTask;

      // Obtener la URL de descarga pública de la imagen
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error al subir la imagen: $e");
      return "";
    }

  }

  static Future<int> registerWithGoogle( usuario.User persona, File _imageFile) async {
    try {

      String imageUrl = await uploadProfilePicture(persona.userId, _imageFile);
      persona.photo=imageUrl;

        return  await _saveUserToDatabase( persona);


    } catch (e) {
      return 0;
    }
  }

  static Future<int> _saveUserToDatabase(  usuario.User persona) async {
    final baseUrl = Config.get('api_base_url');
    final response = await http.post(
      Uri.parse('$baseUrl/api/user/create-user'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: jsonEncode(persona.toFirestore()),
    );

    return response.statusCode;
  }




}

extension on Object {
  get code => null;
}


