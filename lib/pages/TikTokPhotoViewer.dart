import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' as fire;
import 'package:firebase_database/firebase_database.dart' as rtdb;
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';

import '../class/SessionProvider.dart';

class TikTokPhotoViewer extends StatefulWidget {
  @override
  _TikTokPhotoViewerState createState() => _TikTokPhotoViewerState();
}

class _TikTokPhotoViewerState extends State<TikTokPhotoViewer> {
  final fire.FirebaseFirestore firestore = fire.FirebaseFirestore.instance;
  final rtdb.FirebaseDatabase realtimeDB = rtdb.FirebaseDatabase.instance;

  List<Map<String, dynamic>> photos = [];
  bool isLoading = false;
  bool hasMorePhotos = true;
  PageController _pageController = PageController();
  List<String> sharedAlbumIds = []; // Lista de álbumes compartidos cargados dinámicamente
  Set<String> loadedPhotoIds = {}; // Fotos ya cargadas
  Map<String, bool> likedPhotos = {};
  Map<String, int> likeCounts = {};
  fire.DocumentSnapshot? lastPhotoDoc;
  fire.DocumentSnapshot? lastAlbumDoc; // Para paginar álbumes
  Map<String, StreamSubscription<rtdb.DatabaseEvent>> likeSubscriptions = {}; // Subscripciones de likes

  @override
  void initState() {
    super.initState();
    _fetchSharedAlbums(); // 🔹 Cargar el primer álbum
    _pageController.addListener(_onScroll);
  }

  @override
  void dispose() {
    for (var sub in likeSubscriptions.values) {
      sub.cancel();
    }
    likeSubscriptions.clear();
    super.dispose();
  }

  /// 🔹 Detecta el scroll y carga más álbumes y fotos cuando es necesario
  void _onScroll() {
    if (_pageController.position.pixels >= _pageController.position.maxScrollExtent * 0.8) {
      _fetchNextAlbum(); // 🔹 Cargar más álbumes
    }
  }

  /// 🔹 Buscar el primer álbum compartido y cargar sus fotos
  Future<void> _fetchSharedAlbums() async {
    if (isLoading) return;
    setState(() => isLoading = true);

    try {
      fire.QuerySnapshot albumSnapshot = await firestore
          .collection('albums')
          .where('isCompartido', isEqualTo: true)
          .orderBy('createdTo', descending: true) // Ajustar campo según Firestore
          .limit(1) // Solo cargar un álbum
          .get();

      if (albumSnapshot.docs.isEmpty) {
        print("⚠ No hay álbumes compartidos.");
        setState(() {
          hasMorePhotos = false;
        });
        return;
      }

      String albumId = albumSnapshot.docs.first.id;
      if (!sharedAlbumIds.contains(albumId)) {
        setState(() {
          sharedAlbumIds.add(albumId);
          lastAlbumDoc = albumSnapshot.docs.last;
        });

        await _fetchPhotos();
      }

    } catch (e) {
      print("❌ Error al obtener álbumes compartidos: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }


  /// 🔹 Buscar el siguiente álbum compartido cuando el usuario haga scroll
  Future<void> _fetchNextAlbum() async {
    if (isLoading || lastAlbumDoc == null) return;
    setState(() => isLoading = true);

    try {
      fire.QuerySnapshot albumSnapshot = await firestore
          .collection('albums')
          .where('isCompartido', isEqualTo: true)
          .orderBy('createdTo', descending: true)
          .startAfterDocument(lastAlbumDoc!) // Cargar después del último
          .limit(1) // Solo un álbum a la vez
          .get();

      if (albumSnapshot.docs.isNotEmpty) {
        String albumId = albumSnapshot.docs.first.id;
        if (!sharedAlbumIds.contains(albumId)) {
          setState(() {
            sharedAlbumIds.add(albumId);
            lastAlbumDoc = albumSnapshot.docs.last;
          });

          await _fetchPhotos();
        }
      } else {
        setState(() => hasMorePhotos = false);
      }
    } catch (e) {
      print("❌ Error al cargar siguiente álbum: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// 🔹 Cargar fotos de los álbumes compartidos dinámicamente con paginación
  Future<void> _fetchPhotos({bool clearExisting = false}) async {
    //if (isLoading || sharedAlbumIds.isEmpty) return;
    setState(() => isLoading = true);

    try {
      fire.Query query = firestore
          .collection('photos')
          .where('albumId', whereIn: sharedAlbumIds)
          .orderBy('uploadedAt', descending: true)
          .limit(5); // ✅ Paginación, carga 5 fotos por vez

      if (!clearExisting && lastPhotoDoc != null) {
        query = query.startAfterDocument(lastPhotoDoc!);
      }

      fire.QuerySnapshot photoSnapshot = await query.get();

      if (photoSnapshot.docs.isEmpty) {
        setState(() => hasMorePhotos = false);
      } else {
        List<Map<String, dynamic>> newPhotos = [];

        for (var doc in photoSnapshot.docs) {
          String photoId = doc.id;
          if (!loadedPhotoIds.contains(photoId)) {
            newPhotos.add({
              'photoId': photoId,
              'photoUrl': doc['photoUrl'],
              'uploadedAt': doc['uploadedAt']
            });

            loadedPhotoIds.add(photoId);
            _listenForLikeUpdates(photoId);
            await _fetchLikeStatus(photoId);
          }
        }

        if (newPhotos.isNotEmpty) {
          setState(() {
            photos.addAll(newPhotos);
            lastPhotoDoc = photoSnapshot.docs.last;
            hasMorePhotos = true;
          });
        }
      }
    } catch (e) {
      print("❌ Error al obtener fotos: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// 🔹 Escuchar cambios de likes en tiempo real desde Realtime Database
  void _listenForLikeUpdates(String photoId) {
    rtdb.DatabaseReference likeRef = realtimeDB.ref("/likes/$photoId");

    likeSubscriptions[photoId]?.cancel();
    likeSubscriptions[photoId] = likeRef.onValue.listen((event) {
      if (!mounted) return;

      if (event.snapshot.exists) {
        setState(() {
          likeCounts[photoId] = event.snapshot.children.length;
        });
      }
    });
  }

  /// 🔹 Verificar si el usuario ha dado like y obtener el conteo de likes
  Future<void> _fetchLikeStatus(String photoId) async {
    final session = Provider.of<SessionProvider>(context, listen: false);
    String userId = session.user!.userId ?? '';

    fire.QuerySnapshot likeSnapshot = await firestore
        .collection('user_album_likes')
        .where('userId', isEqualTo: userId)
        .where('photoId', isEqualTo: photoId)
        .get();

    fire.QuerySnapshot likesCountSnapshot = await firestore
        .collection('user_album_likes')
        .where('photoId', isEqualTo: photoId)
        .get();

    setState(() {
      likedPhotos[photoId] = likeSnapshot.docs.isNotEmpty;
      likeCounts[photoId] = likesCountSnapshot.docs.length;
    });
  }


  /// 🔹 Método para dar o quitar like y actualizar Firebase en tiempo real
  Future<void> _toggleLike(String photoId) async {
    final session = Provider.of<SessionProvider>(context, listen: false);
    String userId = session.user!.userId ?? '';

    if (likedPhotos[photoId] == true) {
      // Si ya tiene like, eliminarlo
      fire.QuerySnapshot likeSnapshot = await firestore
          .collection('user_album_likes')
          .where('userId', isEqualTo: userId)
          .where('photoId', isEqualTo: photoId)
          .get();

      for (var doc in likeSnapshot.docs) {
        await doc.reference.delete();
      }

      // 🔹 Eliminar en Realtime Database
      await realtimeDB.ref("/likes/$photoId/$userId").remove();

      // 🔹 Recuperar cantidad actualizada de likes desde Firestore
      fire.QuerySnapshot updatedLikesCount = await firestore
          .collection('user_album_likes')
          .where('photoId', isEqualTo: photoId)
          .get();

      setState(() {
        likedPhotos[photoId] = false;
        likeCounts[photoId] = updatedLikesCount.docs.length; // 🔥 Actualización precisa
      });

    } else {
      // Si no tiene like, agregarlo
      String likeId = Uuid().v4();

      await firestore.collection('user_album_likes').doc(likeId).set({
        'id': likeId,
        'userId': userId,
        'photoId': photoId,
      });

      // 🔹 Agregar en Realtime Database
      await realtimeDB.ref("/likes/$photoId/$userId").set(true);

      // 🔹 Recuperar cantidad actualizada de likes desde Firestore
      fire.QuerySnapshot updatedLikesCount = await firestore
          .collection('user_album_likes')
          .where('photoId', isEqualTo: photoId)
          .get();

      setState(() {
        likedPhotos[photoId] = true;
        likeCounts[photoId] = updatedLikesCount.docs.length; // 🔥 Actualización precisa
      });
    }
  }

  String _getCompressedImageUrl(String originalUrl) {
    if (originalUrl.contains("firebasestorage.googleapis.com")) {
      return "$originalUrl=w300"; // ✅ Forzar un ancho máximo de 600px en Firebase
    } else if (originalUrl.contains("cloudinary")) {
      return originalUrl.replaceAll("/upload/", "/upload/w_600,q_70/"); // ✅ Ajustar resolución en Cloudinary
    } else if (originalUrl.contains("imgix")) {
      return "$originalUrl?w=600&auto=format,compress"; // ✅ Usar imgix para optimización
    }
    return originalUrl; // 🔹 Si no se reconoce el servicio, devolver la URL normal
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: hasMorePhotos ? photos.length + 1 : photos.length,
        onPageChanged: (index) {
          if (index == photos.length - 1 && hasMorePhotos) {
            _fetchPhotos();
          }
        },
        itemBuilder: (context, index) {
          if (index == photos.length) {
            return hasMorePhotos
                ? Center(child: CircularProgressIndicator())
                : Center(
              child: Text(
                "No hay más fotos",
                style: TextStyle(color: Colors.black),
              ),
            );
          }

          final photo = photos[index];
          bool isLiked = likedPhotos[photo['photoId']] ?? false;
          int likeCount = likeCounts[photo['photoId']] ?? 0;

          return Stack(
            children: [
              // 📌 Imagen de fondo (foto principal)
              Positioned.fill(
                child: Image.network(
                  _getCompressedImageUrl(photo['photoUrl']), // ✅ Cargar imagen optimizada
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(child: CircularProgressIndicator());
                  },
                ),
              ),


              // ❤️ Botón de Like con animación
              Positioned(
                top: MediaQuery.of(context).size.height / 2 - 50, // 🔹 Siempre centrado a la derecha
                right: 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _toggleLike(photo['photoId']),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.favorite,
                          size: 60,
                          color: isLiked ? Colors.red : Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),

                    // 🔥 Contador de likes con animación
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                      child: Container(
                        key: ValueKey<int>(likeCount), // 🔹 Evita que desaparezca el contador
                        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$likeCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }


}
