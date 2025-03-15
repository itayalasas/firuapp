import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img;
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:ui' as ui;

import 'package:path_provider/path_provider.dart';

class StorageService {

  /// 📌 Subir una foto de mascota validando que contenga un animal
  static Future<String> uploadPetPicture(String uid, File file) async {
    try {
      // 🔍 Validar si la imagen contiene una mascota antes de subirla
      bool hasPet = await containsPet(file);

      if (!hasPet) {
        print("❌ La imagen no contiene una mascota. Selecciona otra.");
        throw Exception("La imagen no contiene una mascota. Selecciona otra.");
      }

      // 📌 Leer la imagen desde el archivo
      Uint8List imageBytes = await file.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception("No se pudo procesar la imagen");
      }

      File compressedFile = await StorageService.compressImage(file);

      // 📌 Subir la imagen a Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child('album_photos/$uid.jpg');
      UploadTask uploadTask = storageRef.putFile(compressedFile);



      // 🔹 Escuchar el progreso de la subida
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = (snapshot.bytesTransferred.toDouble() / snapshot.totalBytes.toDouble()) * 100;
        print("Progreso de la subida: $progress%");
      });

      // 📌 Esperar a que se complete la carga
      TaskSnapshot snapshot = await uploadTask;

      // 📌 Obtener la URL de descarga pública de la imagen
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("❌ Error al subir la imagen: $e");
      return "";
    }
  }

  /// 🔍 Función para detectar si hay una mascota en la imagen
  static Future<bool> containsPet(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final imageLabeler = GoogleMlKit.vision.imageLabeler(
      ImageLabelerOptions(confidenceThreshold: 0.6),
    );

    final labels = await imageLabeler.processImage(inputImage);
    imageLabeler.close();

    for (var label in labels) {
      if (label.label.toLowerCase().contains('dog') ||
          label.label.toLowerCase().contains('cat')) {
        return true; // 🐶🐱 Se detectó una mascota
      }
    }
    return false; // ❌ No se detectó una mascota
  }


  static Future<bool> deleteFileFromFirebase(String fileUrl) async {
   try {
     // 🔹 Extraer el path real del archivo desde la URL pública
     Uri uri = Uri.parse(fileUrl);

     if (!uri.path.contains("/o/")) {
       print("❌ Error: La URL proporcionada no es válida.");
       return false;
     }

     // 🔹 Extraer la parte del path después de "/o/"
     String fullPath = uri.path.split("/o/").last.split("?").first;

     // 🔹 Decodificar el path (porque Firebase usa %2F en lugar de /)
     fullPath = Uri.decodeComponent(fullPath);

     print("📌 Path a eliminar en Firebase Storage: $fullPath");

     // 🔹 Referencia al archivo en Firebase Storage
     Reference fileRef = FirebaseStorage.instance.ref().child(fullPath);

     // 🔹 Eliminar el archivo
     await fileRef.delete();

     print("✅ Archivo eliminado correctamente de Firebase Storage");
     return true; // ✅ Eliminación exitosa
   } catch (e) {
     print("❌ Error al eliminar el archivo: $e");
     return false; // ❌ Error en la eliminación
   }
 }



// 🔹 Método para subir archivos a Firebase Storage
  static Future<String> uploadPetPictureAlbum(String uid, File file) async {
    try {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.${file.path.split('.').last}';
      Reference storageRef = FirebaseStorage.instance.ref().child('album/$fileName');

      UploadTask uploadTask = storageRef.putFile(file);
      await uploadTask;

      return await storageRef.getDownloadURL(); // 🔹 Retorna la URL pública
    } catch (e) {
      throw Exception("Error al subir la imagen: $e");
    }
  }


  // Método para asignar la imagen, ya sea seleccionada o generada
  static Future<File?> setProfileImage(String name) async {
    File? _imageFile;
    if (name.isNotEmpty) {
      // Esperar a que la imagen sea generada antes de asignarla
      _imageFile = await _generateImageFromInitial(name.substring(0, 1).toUpperCase());

    }
    return _imageFile;
  }

  // Método para generar una imagen con la inicial del nombre
  static Future<File> _generateImageFromInitial(String initial) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = Colors.blue;

    final size = 100.0; // Tamaño de la imagen
    final textPainter = TextPainter(
      text: TextSpan(
        text: initial,
        style: TextStyle(fontSize: 40, color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Dibujar el fondo circular
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);

    // Dibujar la letra en el centro del círculo
    textPainter.paint(
        canvas,
        Offset(
          (size - textPainter.width) / 2,
          (size - textPainter.height) / 2,
        ));

    // Crear la imagen en memoria
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());

    // Convertir la imagen a bytes PNG
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    // Guardar la imagen en el sistema de archivos local
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$initial.png';
    final file = File(filePath);
    await file.writeAsBytes(buffer);

    return file; // Retornar el archivo generado
  }
// 📌 Método para comprimir la imagen
  static Future<File> compressImage(File file) async {
    Uint8List imageBytes = await file.readAsBytes(); // Leer la imagen en bytes
    img.Image? image = img.decodeImage(imageBytes); // Decodificar la imagen

    if (image == null) {
      throw Exception("No se pudo procesar la imagen.");
    }

    // 📌 Reducir la calidad y el tamaño al 50%
    Uint8List compressedBytes = Uint8List.fromList(img.encodeJpg(image, quality: 50));

    // 📌 Guardar la imagen comprimida en un archivo temporal
    final tempDir = await getTemporaryDirectory();
    File compressedFile = File('${tempDir.path}/compressed_${file.uri.pathSegments.last}');
    await compressedFile.writeAsBytes(compressedBytes);

    return compressedFile;
  }

}