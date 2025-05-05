import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'dart:typed_data'; // Asegúrate de que esta importación esté presente
import 'package:image/image.dart' as img;

import '../class/Album.dart';
import '../class/Mascota.dart';
import '../class/SessionProvider.dart';
import '../services/storage_service.dart';
import 'Config.dart';
import 'Utiles.dart';

import 'package:http/http.dart' as http;

import 'package:photo_view/photo_view.dart';


class AmigosPerrunosPage extends StatefulWidget {
  final Mascota mascota;

  AmigosPerrunosPage({required this.mascota});

  @override
  _AmigosPerrunosPageState createState() => _AmigosPerrunosPageState();
}

class _AmigosPerrunosPageState extends State<AmigosPerrunosPage> with SingleTickerProviderStateMixin{
  List<Album> albums = [];
  bool isLoading = false; // Controlador del loader para álbumes
  bool isSavingPhoto = false; // Controlador del loader para guardar fotos
  bool isExpanded = false; // Controlador para el abanico de botones
  late AnimationController _animationController;
  bool isLoadingAlbums = true; // Variable para mostrar el mensaje de carga

  bool isUploading = false; // Para el loader de carga
  double uploadProgress = 0.0; // Progreso de carga

  bool isDownloading = false; // Activa el estado de carga
  double downloadProgress = 0.0; // Reinicia el progreso

  /// Aquí guardaremos la lista de nombres de raza disponibles.
  List<String> _razasDisponibles = [];

  double _uploadProgress = 0.0;  // 0.0 … 100.0
  bool   _isUploading   = false;


  @override
  void initState() {
    super.initState();
    _loadAlbumsFromDatabase();
    _loadRazasDisponibles();  // Cargamos las razas desde Firestore
    if (context.mounted) {
      final session = Provider.of<SessionProvider>(context, listen: false);
      session.notifyListeners();
    }

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 250),
    );

  }

  /// Consulta la colección `tipo_raza` filtrando
  /// por la especie de la mascota y extrae el campo `nombre`.
  Future<void> _loadRazasDisponibles() async {
    try {
      final especie = widget.mascota.especie;
      final snap = await FirebaseFirestore.instance
          .collection('tipo_raza')
          .where('tipo', isEqualTo: especie)
          .get();
      final razas = snap.docs
          .map((d) => (d.data()['nombre'] as String))
          .toList()
        ..sort();
      setState(() => _razasDisponibles = razas);
    } catch (e) {
      print('Error cargando razas: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      isExpanded = !isExpanded;
      isExpanded ? _animationController.forward() : _animationController.reverse();
    });
  }

  /// 🔹 Cargar álbumes desde Firebase Firestore
  Future<void> _loadAlbumsFromDatabase() async {
    setState(() {
      isLoadingAlbums = true;
    });

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    QuerySnapshot querySnapshot = await firestore
        .collection('albums')
        .where('mascotaId', isEqualTo: widget.mascota.mascotaid)
        .get();

    setState(() {
      albums = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['albumId'] = doc.id; // Asegurar que el ID del documento se incluya
        return Album.fromJson(data); // Convertimos a objeto Album
      }).toList();
      isLoadingAlbums = false;
    });
  }


  Future<List<Album>> fetchAlbumsFromDatabase(String mascotaId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('albums')
          .where('mascotaId', isEqualTo: mascotaId)
          .get();

      return snapshot.docs.map((doc) {
        return Album.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print("❌ Error al obtener álbumes: $e");
      return [];
    }
  }

  Future<int> getPhotoLikeCount(String photoId) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('photos').doc(photoId).get();
      if (snapshot.exists) {
        return (snapshot.data() as Map<String, dynamic>)['likeCount'] ?? 0;
      }
      return 0;
    } catch (e) {
      print("❌ Error al obtener el conteo de likes: $e");
      return 0;
    }
  }




  Future<void> addPhotoToDatabase(File file, String albumId, String mediaType) async {
    try {
      final photoId = Uuid().v4(); // Generar un UUID único para la foto
      final userId = "ID_DEL_USUARIO"; // Deberás obtener esto de la sesión

      // 📌 Subir la imagen a Firebase Storage
      String photoUrl = await StorageService.uploadPetPictureAlbum(userId, file);

      // 📌 Guardar la referencia en Firestore
      await FirebaseFirestore.instance.collection('photos').doc(photoId).set({
        'photoId': photoId,
        'albumId': albumId,
        'photo': photoUrl,
        'mediaType': mediaType,
        'likeCount': 0, // Inicialmente la foto tiene 0 likes
      });

      print("✅ Foto guardada con éxito en Firebase Firestore.");
    } catch (e) {
      print("❌ Error al guardar la foto en Firebase: $e");
    }
  }


  Future<void> addLikeToPhoto(String photoId, String userId) async {
    try {
      // Verificar si el usuario ya dio like
      QuerySnapshot likeSnapshot = await FirebaseFirestore.instance
          .collection('likes')
          .where('userId', isEqualTo: userId)
          .where('photoId', isEqualTo: photoId)
          .get();

      if (likeSnapshot.docs.isNotEmpty) {
        print("⚠️ El usuario ya ha dado like a esta foto.");
        return;
      }

      // Generar un UUID único para el like
      String likeId = Uuid().v4();

      // Guardar el like en Firestore
      await FirebaseFirestore.instance.collection('likes').doc(likeId).set({
        'likeId': likeId,
        'userId': userId,
        'photoId': photoId,
      });

      // Incrementar el contador de likes en la foto
      DocumentReference photoRef =
      FirebaseFirestore.instance.collection('photos').doc(photoId);

      FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(photoRef);

        if (snapshot.exists) {
          int currentLikes = (snapshot.data() as Map<String, dynamic>)['likeCount'] ?? 0;
          transaction.update(photoRef, {'likeCount': currentLikes + 1});
        }
      });

      print("✅ Like agregado correctamente.");
    } catch (e) {
      print("❌ Error al agregar like: $e");
    }
  }

  Future<void> deletePhotoFromDatabase(String photoId, String albumId) async {
    try {
      // Referencia a Firestore y Storage
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      FirebaseStorage storage = FirebaseStorage.instance;

      // Obtener la referencia de la foto desde Firestore
      DocumentSnapshot photoSnapshot = await firestore.collection('photos').doc(photoId).get();

      if (photoSnapshot.exists) {
        Map<String, dynamic> photoData = photoSnapshot.data() as Map<String, dynamic>;
        String photoUrl = photoData['photo'];

        // Eliminar la imagen de Firebase Storage
        Reference storageRef = storage.refFromURL(photoUrl);
        await storageRef.delete();

        // Eliminar la foto del álbum en Firestore
        await firestore.collection('photos').doc(photoId).delete();

        // Eliminar todos los likes relacionados con esta foto
        QuerySnapshot likesSnapshot = await firestore
            .collection('photo_likes')
            .where('photoId', isEqualTo: photoId)
            .get();

        for (QueryDocumentSnapshot doc in likesSnapshot.docs) {
          await doc.reference.delete();
        }

        print('✅ Foto eliminada con éxito de Firestore y Storage.');
      } else {
        print('⚠️ La foto no existe en Firestore.');
      }
    } catch (e) {
      print('❌ Error al eliminar la foto: $e');
    }
  }

  Future<void> _deleteAlbum(String albumId) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      FirebaseStorage storage = FirebaseStorage.instance;

      // Obtener todas las fotos del álbum
      QuerySnapshot photoSnapshots = await firestore
          .collection('photos')
          .where('albumId', isEqualTo: albumId)
          .get();

      // Eliminar todas las fotos asociadas en Firestore y Storage
      for (QueryDocumentSnapshot photoDoc in photoSnapshots.docs) {
        Map<String, dynamic> photoData = photoDoc.data() as Map<String, dynamic>;
        String photoId = photoDoc.id;
        String? photoUrl = photoData['photo']; // 🔹 Puede ser null

        // Si photoUrl no es null, eliminar la foto de Firebase Storage
        if (photoUrl != null && photoUrl.isNotEmpty) {
          try {
            Reference storageRef = storage.refFromURL(photoUrl);
            await storageRef.delete();
          } catch (e) {
            print("⚠️ No se pudo eliminar la imagen de Firebase Storage: $e");
          }
        } else {
          print("⚠️ La foto con ID $photoId no tiene una URL válida.");
        }

        // Eliminar la foto en Firestore
        await photoDoc.reference.delete();

        // Eliminar los likes de la foto
        QuerySnapshot likesSnapshot = await firestore
            .collection('photo_likes')
            .where('photoId', isEqualTo: photoId)
            .get();

        for (QueryDocumentSnapshot likeDoc in likesSnapshot.docs) {
          await likeDoc.reference.delete();
        }
      }

      // Eliminar el álbum en Firestore
      await firestore.collection('albums').doc(albumId).delete();

      // 🔹 Actualizar la UI eliminando el álbum de la lista y refrescando la pantalla
      setState(() {
        albums.removeWhere((album) => album.albumId == albumId);
      });

      print('✅ Álbum eliminado con éxito.');
    } catch (e) {
      print('❌ Error al eliminar el álbum: $e');
    }
  }



  Future<bool> _updateSharedAlbums(List<Album> sharedAlbums) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      for (var album in sharedAlbums) {
        final albumRef = FirebaseFirestore.instance.collection('albums').doc(album.albumId);
        batch.update(albumRef, {'isCompartido': true});
      }

      await batch.commit(); // Ejecutar la actualización en lote

      setState(() {
        for (var album in sharedAlbums) {
          album.isCompartido = true; // Actualizar localmente el estado
          album.isCompartido = false; // Desmarcar la selección
        }
      });

      print('✅ Álbumes compartidos exitosamente en Firebase.');
      return true; // Indicar que la actualización fue exitosa
    } catch (e) {
      print('❌ Error al compartir los álbumes en Firebase: $e');
      Utiles.showInfoDialog(
        context: context,
        title: 'Error',
        message: 'Hubo un problema al compartir los álbumes. Intenta de nuevo.',
      );
      return false; // Indicar que la actualización falló
    }
  }


  Future<void> _shareAlbum(String albumId) async {
    try {
      List<String> imagePaths = [];
      int totalPhotos = 0;
      int downloadedPhotos = 0;
      double downloadProgress = 0.0;

      // 🔹 Obtener todas las fotos del álbum desde Firebase
      QuerySnapshot photoSnapshot = await FirebaseFirestore.instance
          .collection('photos')
          .where('albumId', isEqualTo: albumId)
          .get();

      if (photoSnapshot.docs.isEmpty) {
        print("⚠ No hay fotos en este álbum.");
        Utiles.showInfoDialog(
          context: context,
          title: 'Álbum vacío',
          message: 'No hay fotos en este álbum para compartir.',
        );
        return;
      }

      totalPhotos = photoSnapshot.docs.length;

      // 🔵 Mostrar el diálogo de progreso
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                title: Text("Descargando fotos..."),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(value: downloadProgress),
                    SizedBox(height: 10),
                    Text("${(downloadProgress * 100).toStringAsFixed(0)}% completado"),
                  ],
                ),
              );
            },
          );
        },
      );

      // 🔄 Descargar todas las imágenes y actualizar el progreso en tiempo real
      for (var doc in photoSnapshot.docs) {
        if (doc.data() is Map<String, dynamic>) {
          Map<String, dynamic> photoData = doc.data() as Map<String, dynamic>;

          if (photoData.containsKey('photoUrl') && photoData['photoUrl'] is String) {
            String photoUrl = photoData['photoUrl'];

            // ✅ Descargar la imagen y actualizar progreso en el diálogo
            File imageFile = await _downloadImage(photoUrl, (progress) {
              setState(() {
                downloadProgress = (downloadedPhotos + progress) / totalPhotos;
              });
            });

            if (await imageFile.exists()) { // 🔥 Usa exists() en lugar de existsSync()
              imagePaths.add(imageFile.path);
            }

            downloadedPhotos++;
          }
        }
      }

      Navigator.pop(context); // 🔴 Cerrar el diálogo cuando finaliza la descarga

      if (imagePaths.isEmpty) {
        print("⚠ No se pudieron descargar las fotos.");
        Utiles.showInfoDialog(
          context: context,
          title: 'Error',
          message: 'No se pudieron descargar las fotos.',
        );
        return;
      }

      // ✅ Compartir imágenes descargadas

      List<XFile> files = imagePaths.map((path) => XFile(path)).toList();


      await Share.shareXFiles(
        files,
        text: "📸 ¡Mira el álbum de mi mascota! 🐶🐱",
      );

      print("✅ Álbum compartido con fotos.");
    } catch (e) {
      Navigator.pop(context); // 🔴 Cerrar el diálogo si hay un error
      print("❌ Error al compartir el álbum con fotos: $e");
      Utiles.showInfoDialog(
        context: context,
        title: 'Error',
        message: 'Hubo un problema al compartir el álbum. Inténtalo nuevamente.',
      );
    }
  }

  Future<File> _downloadImage(String url, Function(double) onProgress) async {
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw Exception("No se pudo descargar la imagen");
      }

      final contentLength = response.contentLength ?? 0;
      int downloadedBytes = 0;
      final List<int> bytes = [];

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(filePath);

      response.stream.listen((List<int> chunk) {
        bytes.addAll(chunk);
        downloadedBytes += chunk.length;

        // 🔄 Calcular y actualizar el progreso
        double progress = (contentLength > 0) ? (downloadedBytes / contentLength) : 0;
        onProgress(progress);

      }, onDone: () async {
        await file.writeAsBytes(bytes);
        print("✅ Imagen descargada: ${file.path}");
      }, onError: (e) {
        print("❌ Error al descargar la imagen: $e");
      });

      return file;
    } catch (e) {
      print("❌ Error al descargar la imagen: $e");
      return File('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Mascota mascota = widget.mascota;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: SafeArea(
          child: AppBar(
            title: Text(
              'Recuerdos de ${mascota.nombre}',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 20),
            ),
            backgroundColor: const Color(0xFFA0E3A7),
            elevation: 0,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 20),

                // 📌 Tarjeta de datos con avatar + progreso + edición
                Stack(
                  children: [
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF67C8F1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Avatar + loader anular
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundImage: mascota.fotos.isNotEmpty
                                    ? NetworkImage(mascota.fotos)
                                    : Utiles.getDefaultImageForSpecies(mascota.especie),
                              ),

                              // ← Mostramos el anillo mientras _isUploading sea true
                              if (_isUploading)
                                SizedBox(
                                  width: 110,
                                  height: 110,
                                  child: CircularProgressIndicator(
                                    value: _uploadProgress / 100,
                                    strokeWidth: 6,
                                    backgroundColor: Colors.white.withOpacity(0.6),
                                    valueColor: AlwaysStoppedAnimation(Colors.green),
                                  ),
                                ),

                              // Ícono de cámara
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _updatePhoto,
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.white,
                                    child: Icon(
                                      Icons.camera_alt,
                                      size: 18,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(width: 20),

                          // Datos de la mascota
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mascota.nombre,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Sexo: ${mascota.genero ?? "-"}',
                                  style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Especie: ${mascota.especie}',
                                  style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Raza: ${mascota.raza}',
                                  style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                ),
                                if (mascota.edad != null) ...[
                                  SizedBox(height: 8),
                                  Text(
                                    'Edad: ${mascota.edad}',
                                    style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Botón de editar datos
                    Positioned(
                      right: 32,
                      top: 8,
                      child: IconButton(
                        icon: Icon(Icons.edit, color: Colors.grey[700]),
                        onPressed: _showEditPetDialog,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // 📌 Mensaje de carga de álbumes
                if (isLoadingAlbums)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      "Cargando álbumes...",
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ),

                // 📌 Grid de álbumes
                if (!isLoadingAlbums)
                  GridView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: albums.length,
                    itemBuilder: (context, index) {
                      final album = albums[index];
                      return FutureBuilder<List<Map<String, dynamic>>>(
                        future: _loadPhotosForAlbum(album.albumId),
                        builder: (context, snapshot) {
                          final photos = snapshot.data ?? [];
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF67C8F1)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF67C8F1).withOpacity(0.2),
                                    borderRadius:
                                    BorderRadius.vertical(top: Radius.circular(10)),
                                  ),
                                  child: Text(
                                    album.name,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Expanded(
                                  child: GridView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      mainAxisSpacing: 4,
                                      crossAxisSpacing: 4,
                                      childAspectRatio: 1,
                                    ),
                                    itemCount: photos.length,
                                    itemBuilder: (context, photoIndex) {
                                      final photo = photos[photoIndex];
                                      return GestureDetector(
                                        onTap: () => _viewPhoto(photo['photoUrl']),
                                        child: Image.network(photo['photoUrl'],
                                            fit: BoxFit.cover),
                                      );
                                    },
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.add_a_photo,
                                          color: const Color(0xFF67C8F1)),
                                      onPressed: () => _addPhotoToAlbum(album.albumId),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteAlbum(album.albumId),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.share,
                                          color: const Color(0xFF67C8F1)),
                                      onPressed: () => _shareAlbum(album.albumId),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          ),

          // 📌 Overlay de progreso global al subir fotos de álbum
          if (_isUploading)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _uploadProgress / 100,
                    color: Colors.green,
                  ),
                  SizedBox(height: 10),
                  Text("Subiendo: ${_uploadProgress.toStringAsFixed(0)}%"),
                ],
              ),
            ),
        ],
      ),

      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isExpanded)
            FloatingActionButton(
              heroTag: "btnCompartir",
              onPressed: _showShareAlbumDialog,
              backgroundColor: const Color(0xFF67C8F1),
              child: Icon(Icons.share, color: Colors.white),
            ),
          if (isExpanded) SizedBox(height: 10),
          if (isExpanded)
            FloatingActionButton(
              heroTag: "btnCrear",
              onPressed: () => _showCreateAlbumModal(context),
              backgroundColor: const Color(0xFFA0E3A7),
              child: Icon(Icons.add, color: Colors.white),
            ),
          SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "btnExpandir",
            onPressed: _toggleExpand,
            backgroundColor: const Color(0xFF67C8F1),
            child:
            Icon(isExpanded ? Icons.close : Icons.menu, color: Colors.white),
          ),
        ],
      ),
    );
  }


// 1️⃣ Lanza ImagePicker para seleccionar/capturar foto
  Future<void> _updatePhoto() async {
    try {
      // 0️⃣ Antes de todo, arrancamos el loader:
      setState(() {
        _isUploading   = true;
        _uploadProgress = 0.0;
      });

      // 1️⃣ Pedir nueva imagen
      final picker = ImagePicker();
      final XFile? pick = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (pick == null) {
        // usuario canceló: detenemos loader
        setState(() => _isUploading = false);
        return;
      }
      final file = File(pick.path);

      // 2️⃣ Validar mascota
      bool hasPet = await StorageService.containsPet(file);
      if (!hasPet) {
        Utiles.showErrorDialog(
          context: context,
          title: 'Error',
          content: 'La imagen no contiene una mascota. Selecciona otra.',
        );
        setState(() => _isUploading = false);
        return;
      }

      // 3️⃣ Borrar foto vieja (ignoramos errores)
      final oldUrl = widget.mascota.fotos;
      if (oldUrl.isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(oldUrl).delete();
        } catch (_) { /* lo ignoramos */ }
      }

      // 4️⃣ Subir la nueva y escuchar progreso
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('pet_photos/${widget.mascota.mascotaid}.jpg');
      final uploadTask = storageRef.putFile(file);

      uploadTask.snapshotEvents.listen((snap) {
        final transferred = snap.bytesTransferred.toDouble();
        final total       = snap.totalBytes.toDouble();
        if (total > 0) {
          setState(() {
            _uploadProgress = transferred / total * 100;
          });
        }
      });

      final snapshot = await uploadTask;
      final newUrl   = await snapshot.ref.getDownloadURL();

      // 5️⃣ Actualizar modelo local
      setState(() {
        widget.mascota.fotos = newUrl;
      });

      // 6️⃣ Persistir en Firestore y provider
      final session = Provider.of<SessionProvider>(context, listen: false);
      final userId  = session.user?.userId;
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('mascotas')
            .doc(widget.mascota.mascotaid)
            .update({'fotos': newUrl});
        final lista = session.user?.mascotas;
        if (lista != null) {
          final idx = lista.indexWhere((m) => m.mascotaid == widget.mascota.mascotaid);
          if (idx != -1) lista[idx].fotos = newUrl;
        }
        session.notifyListeners();
      }

      // 7️⃣ Éxito: apagamos loader y reseteamos progreso
      setState(() {
        _isUploading    = false;
        _uploadProgress = 0.0;
      });
      /*ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Foto actualizada correctamente')),
      );*/

    } catch (e) {
      // en error apagamos loader
      setState(() {
        _isUploading    = false;
        _uploadProgress = 0.0;
      });
      Utiles.showErrorDialog(
        context: context,
        title: "Error",
        content: "No se pudo actualizar la foto: $e",
      );
    }
  }






// 2️⃣ Muestra un BottomSheet con un Form para editar nombre, género y raza
  /// Ejemplo de cómo usar `_razasDisponibles` en tu BottomSheet:
  void _showEditPetDialog() {
    final _nameC = TextEditingController(text: widget.mascota.nombre);
    String _gen = widget.mascota.genero ?? '';
    String _raz = widget.mascota.raza;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Wrap(children: [
          ListTile(
            title: Text('Editar ${widget.mascota.nombre}',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              // Nombre
              TextField(
                controller: _nameC,
                decoration: InputDecoration(labelText: 'Nombre'),
              ),
              SizedBox(height: 12),
              // Sexo
              DropdownButtonFormField<String>(
                value: _gen.isNotEmpty ? _gen : null,
                items: ['Macho', 'Hembra']
                    .map((g) =>
                    DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => _gen = v ?? _gen,
                decoration: InputDecoration(labelText: 'Sexo'),
              ),
              SizedBox(height: 12),
              // Raza
              DropdownButtonFormField<String>(
                value: _razasDisponibles.contains(_raz) ? _raz : null,
                items: _razasDisponibles
                    .map((r) =>
                    DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => _raz = v ?? _raz,
                decoration: InputDecoration(labelText: 'Raza'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  // Actualiza el modelo local
                  setState(() {
                    widget.mascota.nombre = _nameC.text;
                    widget.mascota.genero = _gen;
                    widget.mascota.raza = _raz;
                  });
                  // Actualiza en Firestore
                  final session = Provider.of<SessionProvider>(
                      context,
                      listen: false);
                  final userId = session.user?.userId;
                  if (userId != null) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('mascotas')
                        .doc(widget.mascota.mascotaid)
                        .update(widget.mascota.toJson());
                    // Refresca el provider
                    session.notifyListeners();
                  }
                  Navigator.pop(context);
                },
                child: Text('Guardar cambios'),
              )
            ]),
          ),
        ]),
      ),
    );
  }


  Future<List<Map<String, dynamic>>> _loadPhotosForAlbum(String albumId) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('photos')
        .where('albumId', isEqualTo: albumId)
        .get();

    return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }



  Future<void> _addPhotoToAlbum(String albumId) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return; // Si el usuario cancela la selección

    File file = File(pickedFile.path);
    // 🔍 Validar si la imagen contiene una mascota antes de subirla
    bool hasPet = await StorageService.containsPet(file);

    if (!hasPet) {
      // ❌ Mostrar un mensaje si no contiene una mascota
      Utiles.showErrorDialog(context: context, title: 'Error', content: "La imagen no contiene una mascota. Selecciona otra.");
      print("❌ La imagen no contiene una mascota. Selecciona otra.");
      return;
    }


    // 📌 Reducir la calidad de la imagen (50%)
    File compressedFile = await StorageService.compressImage(file);

    // ✅ Proceder con la subida
    final String photoId = Uuid().v4();

    setState(() {
      isUploading = true;
      uploadProgress = 0.0;
    });

    try {
      // 📌 Subir la imagen a Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child('album_photos/$photoId.jpg');
      UploadTask uploadTask = storageRef.putFile(compressedFile);

      // 🔹 Escuchar el progreso de carga
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          uploadProgress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        });
      });

      // 📌 Obtener la URL de descarga después de la carga
      TaskSnapshot storageTaskSnapshot = await uploadTask;
      String downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();

      // 📌 Guardar la foto en Firestore
      await FirebaseFirestore.instance.collection('photos').doc(photoId).set({
        'photoId': photoId,
        'albumId': albumId,
        'photoUrl': downloadUrl,
        'uploadedAt': Timestamp.now(),
      });

      setState(() {
        isUploading = false;
      });

      print('✅ Foto subida y guardada correctamente.');
    } catch (e) {
      setState(() {
        isUploading = false;
      });
      Utiles.showErrorDialog(context: context, title: 'Error', content: "Error al subir la foto.");
      print('❌ Error al subir la foto: $e');
    }
  }


  void _viewPhoto(String photoUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(photoUrl),
              SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cerrar", style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        );
      },
    );
  }
  void _showCreateAlbumModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // ✅ Permite que el modal ocupe solo el espacio necesario
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)), // ✅ Bordes redondeados arriba
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, // ✅ Ajuste para evitar que el teclado tape el formulario
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5, // ✅ Limita la altura al 50% de la pantalla
            ),
            child: CreateAlbumDialog(
              mascota: widget.mascota,
              onClose: () {
                setState(() {}); // ✅ Refresca la pantalla después de cerrar el modal
              },
              onAlbumCreated: (Album newAlbum) {
                setState(() {
                  albums.add(newAlbum); // ✅ Agregar el nuevo álbum a la lista
                });
              },
            ),
          ),
        );
      },
    );
  }




  void _showShareAlbumDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            bool isSharing = false; // Estado para controlar el loader

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 🔹 Encabezado del modal
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFA0E3A7),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                        ),
                        padding: EdgeInsets.all(15),
                        child: Center(
                          child: Text(
                            'Seleccionar Álbumes para Compartir',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),

                      // 🔹 Lista de álbumes desplazable
                      Flexible(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(15),
                          child: Column(
                            children: albums.map((album) {
                              return CheckboxListTile(
                                title: Text(
                                  album.name,
                                  style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.black),
                                ),
                                value: album.isSelected,
                                onChanged: (bool? value) {
                                  if (album.isCompartido) {
                                    Utiles.showInfoDialog(
                                      context: context,
                                      title: 'Información',
                                      message: 'Este álbum ya ha sido compartido.',
                                    );
                                    return;
                                  }
                                  setStateDialog(() {
                                    album.isSelected = value ?? false;
                                  });
                                },
                                controlAffinity: ListTileControlAffinity.leading,
                                activeColor: Colors.green,
                                checkColor: Colors.white,
                                enabled: !album.isCompartido,
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      if (_isUploading)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: _uploadProgress / 100,
                                color: Colors.green,
                              ),
                              SizedBox(height: 10),
                              Text("Subiendo: ${_uploadProgress.toStringAsFixed(0)}%"),
                            ],
                          ),
                        ),
                      // 🔹 Botones en la parte inferior
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 🔹 Botón de cancelar
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Cancelar',
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.red),
                              ),
                            ),

                            // 🔹 Botón compartir con loader
                            ElevatedButton(
                              onPressed: isSharing || !albums.any((album) => album.isSelected)
                                  ? null
                                  : () async {
                                setStateDialog(() {
                                  isSharing = true;
                                });

                                bool success = await _navigateToSharedAlbumsPage();

                                setStateDialog(() {
                                  isSharing = false;
                                });

                                if (success) {
                                  Navigator.of(context).pop(); // Cierra el modal
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: isSharing
                                  ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : Text(
                                'Compartir',
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }




  Future<bool> _navigateToSharedAlbumsPage() async {
    final List<Album> sharedAlbums = albums.where((album) => album.isSelected == true).toList().cast<Album>();

    if (sharedAlbums.isEmpty) {
      Utiles.showInfoDialog(
        context: context,
        title: 'Información',
        message: 'Por favor selecciona al menos un álbum para compartir.',
      );
      return false;
    }

    // Actualizar el estado de los álbumes compartidos en la base de datos
    bool success = await _updateSharedAlbums(sharedAlbums);

    if (success) {
      // Actualizar localmente el estado de los álbumes compartidos
      setState(() {
        for (var album in sharedAlbums) {
          album.isCompartido = true; // Marcar como compartido
          album.isSelected = false; // Desmarcar la selección
        }
      });

      // Navegar a la página de álbumes compartidos
     /* Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SharedAlbumsPage(),
        ),
      );*/
      return true;
    } else {
      // Manejar el error de la actualización
      Utiles.showInfoDialog(
        context: context,
        title: 'Error',
        message: 'No se pudieron compartir los álbumes. Intente de nuevo.',
      );
      return false;
    }
  }



  /*void _showDeletePhotoDialog(Album album, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Eliminar Foto'),
          content: Text('¿Estás seguro de que quieres eliminar esta foto del álbum?'),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Eliminar'),
              onPressed: () async {
                final Photo photoToDelete = album.photos[index];

                // Eliminar foto de la base de datos
                await deletePhotoFromDatabase(album.id, photoToDelete.photoId);

                setState(() {
                  album.photos.removeAt(index);
                });

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }*/
}

class MediaItem {
  final String data; // URL de la imagen o video
  final String mediaType; // 'image' o 'video'

  MediaItem({required this.data, required this.mediaType});
}

class PhotoViewGalleryScreen extends StatefulWidget {
  final List<MediaItem> mediaItems;
  final int initialIndex;

  PhotoViewGalleryScreen({required this.mediaItems, required this.initialIndex});

  @override
  _PhotoViewGalleryScreenState createState() => _PhotoViewGalleryScreenState();
}

class _PhotoViewGalleryScreenState extends State<PhotoViewGalleryScreen> {
  VideoPlayerController? _videoPlayerController;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _initializeMedia();
    if (context.mounted) {
      final session = Provider.of<SessionProvider>(context, listen: false);
      session.notifyListeners();
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _initializeMedia() async {
    if (widget.mediaItems[currentIndex].mediaType == 'video') {
      await _initializeVideo(currentIndex);
    }
  }

  Future<void> _initializeVideo(int index) async {
    // Inicializar el video desde la URL
    _videoPlayerController?.dispose(); // Liberar el controlador anterior

    _videoPlayerController = VideoPlayerController.network(widget.mediaItems[index].data)
      ..initialize().then((_) {
        setState(() {}); // Redibujar el widget cuando el video esté inicializado
        _videoPlayerController?.play(); // Reproducir el video automáticamente
      });
  }

  void _onPageChanged(int index) async {
    setState(() {
      currentIndex = index;
    });

    // Si el nuevo medio es un video, inicializar el controlador del video
    if (widget.mediaItems[currentIndex].mediaType == 'video') {
      await _initializeVideo(currentIndex);
    } else {
      _videoPlayerController?.dispose(); // Si es una imagen, liberar el controlador del video
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Galería de Fotos y Videos'),
      ),
      body: PageView.builder(
        itemCount: widget.mediaItems.length,
        scrollDirection: Axis.vertical, // Estilo TikTok, scroll vertical
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          final mediaItem = widget.mediaItems[index];

          // Si es una imagen, mostrarla con Image.network
          if (mediaItem.mediaType == 'image') {
            return PhotoView(
              imageProvider: NetworkImage(mediaItem.data), // Cargar imagen desde la URL
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
            );
          }
          // Si es un video, mostrarlo con VideoPlayer
          else if (mediaItem.mediaType == 'video' && _videoPlayerController != null && _videoPlayerController!.value.isInitialized) {
            return AspectRatio(
              aspectRatio: _videoPlayerController!.value.aspectRatio,
              child: VideoPlayer(_videoPlayerController!),
            );
          } else {
            return Center(child: CircularProgressIndicator()); // Mostrar indicador de carga mientras se inicializa el video
          }
        },
      ),
    );
  }
}




class CreateAlbumDialog extends StatefulWidget {
  final Mascota mascota;
  final VoidCallback onClose;
  final Function(Album) onAlbumCreated; // Callback para actualizar la lista

  CreateAlbumDialog({
    required this.mascota,
    required this.onClose,
    required this.onAlbumCreated,
  });

  @override
  _CreateAlbumDialogState createState() => _CreateAlbumDialogState();
}

class _CreateAlbumDialogState extends State<CreateAlbumDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController albumNameController = TextEditingController();
  bool _isLoading = false; // Controlador del loader para el botón

  /// 🔹 Método para crear el álbum y actualizar la lista en pantalla
  Future<void> _createAlbum() async {
    setState(() {
      _isLoading = true;
    });

    final albumId = Uuid().v4(); // Generar un UUID único
    final newAlbum = Album(
      albumId: albumId,
      name: albumNameController.text,
      mascotaId: widget.mascota.mascotaid,
      createdTo: Timestamp.now(),
      isCompartido: false,
    );

    bool success = await saveAlbumToDatabase(newAlbum);

    if (success) {
      widget.onAlbumCreated(newAlbum); // Agregar el álbum a la lista correctamente
      widget.onClose(); // Cierra el modal
      Navigator.pop(context); // Cierra el modal después de crear el álbum
    }

    setState(() {
      _isLoading = false;
    });
  }

  /// 🔹 Método para guardar el álbum en Firebase Firestore
  Future<bool> saveAlbumToDatabase(Album album) async {
    try {
      await FirebaseFirestore.instance.collection('albums').doc(album.albumId).set(album.toJson());
      print('✅ Álbum guardado en Firebase con éxito.');
      return true;
    } catch (e) {
      print('❌ Error al guardar el álbum en Firebase: $e');
      return false;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, // ✅ Asegura un fondo blanco en el modal
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min, // ✅ Ajusta el tamaño al contenido
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Crear Álbum',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: albumNameController,
              decoration: InputDecoration(
                labelText: 'Nombre del Álbum',
                labelStyle: TextStyle(fontFamily: 'Poppins'),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese el nombre del álbum';
                }
                return null;
              },
            ),
            SizedBox(height: 30),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  _createAlbum();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Crear Álbum',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/*class ShareAlbumScreen extends StatefulWidget {
  final Album album;
  ShareAlbumScreen(this.album);

  @override
  _ShareAlbumScreen createState() => _ShareAlbumScreen();
}



class _ShareAlbumScreen extends State<AddPesoModal> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _shareSelectedAlbums() async {
    final sharedAlbums = albums.where((album) => album.isSelected == true).toList();
    setState(() {
      _isLoading = true;
    });

    bool success = await _updateSharedAlbums(sharedAlbums);

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SharedAlbumsPage()),
      );
    } else {
      Utiles.showInfoDialog(
        context: context,
        title: 'Error',
        message: 'No se pudieron compartir los álbumes. Intente de nuevo.',
      );
    }

    setState(() {
      _isLoading = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: SafeArea(
          child: AppBar(
            title: Text(
              'Seleccionar Álbumes para Compartir',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: const Color(0xFFA0E3A7),
            elevation: 0,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: albums.length,
                itemBuilder: (context, index) {
                  final album = albums[index];
                  return CheckboxListTile(
                    title: Text(
                      album.name,
                      style: TextStyle(fontFamily: 'Poppins'),
                    ),
                    value: album.isSelected,
                    onChanged: (bool? value) {
                      if (album.isShared) {
                        Utiles.showInfoDialog(
                          context: context,
                          title: 'Información',
                          message: 'Este álbum ya ha sido compartido.',
                        );
                        return;
                      }
                      setState(() {
                        album.isSelected = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: const Color(0xFF67C8F1),
                    selected: album.isSelected,
                    enabled: !album.isShared,
                  );
                },
              ),
            ),
            SizedBox(height: 30),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _shareSelectedAlbums,
              child: Text(
                'Compartir Álbumes',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF67C8F1),
                padding: EdgeInsets.symmetric(vertical: 15),
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
}*/


