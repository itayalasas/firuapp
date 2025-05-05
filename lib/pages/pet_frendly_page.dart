import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'map_screen.dart';

class PetFriendlyScreen extends StatefulWidget {
  @override
  _PetFriendlyScreenState createState() => _PetFriendlyScreenState();
}

class _PetFriendlyScreenState extends State<PetFriendlyScreen> {
  String selectedCategory = 'Cafés';
  Position? _currentPosition;
  //final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _places = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  final int _limit = 3; // Mostramos 3 lugares por pantalla
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> categories = [];

  bool _isInitialized = false;


  /*@override
  void initState() {
    super.initState();
    if (!_isInitialized) {
      _isInitialized = true;
      _getCurrentLocation();
      _fetchPlaces();
      _scrollController.addListener(_scrollListener);
      fetchCategories();
    }
  }*/





  bool _hasLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      _getCurrentLocation();
      _fetchPlaces();
      _scrollController.addListener(_scrollListener);
      fetchCategories();
    }
  }


  Future<void> insertCategoriesToFirestore() async {
    CollectionReference categoriesCollection = FirebaseFirestore.instance.collection('categories');

    List<Map<String, dynamic>> categories = [
      {'name': 'Cafés', 'icon': 'local_cafe'},
      {'name': 'Restaurantes', 'icon': 'restaurant'},
      {'name': 'Hoteles', 'icon': 'hotel'},
      {'name': 'Mercados', 'icon': 'storefront'},
      {'name': 'Shopping', 'icon': 'shopping_bag'},
    ];

    for (var category in categories) {
      await categoriesCollection.add(category);
    }

    print("✅ Categorías insertadas correctamente en Firestore");
  }



  Future<void> fetchCategories() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('categories').get();

    List<Map<String, dynamic>> loadedCategories = snapshot.docs.map((doc) {
      return {
        'name': doc['name'],
        'icon': _getIconFromName(doc['icon']),
      };
    }).toList();

    if (mounted) {
      setState(() {
        categories = loadedCategories;
      });
    }
  }

  /// 🔹 Convierte el nombre del ícono en un `IconData`
  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'local_cafe':
        return Icons.local_cafe;
      case 'restaurant':
        return Icons.restaurant;
      case 'hotel':
        return Icons.hotel;
      case 'storefront':
        return Icons.storefront;
      case 'shopping_bag':
        return Icons.shopping_bag;
      default:
        return Icons.category; // Icono por defecto
    }
  }



  /// 📌 Obtiene la ubicación actual del usuario
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("GPS desactivado");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        print("Permiso de ubicación denegado permanentemente.");
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
    });

    _fetchPlaces(reset: true);
  }

  /// 📌 Obtiene lugares desde Firebase con paginación y filtrado
  Future<void> _fetchPlaces({bool reset = false}) async {
    if (_isLoading || !_hasMore) return; // ❌ Evitar múltiples llamadas si ya está cargando o no hay más datos

    setState(() {
      _isLoading = true; // 🔄 Indicamos que estamos cargando datos
    });

    if (reset) {
      setState(() {
        _places.clear();
        _lastDocument = null;
        _hasMore = true; // ✅ Permitimos más consultas al resetear
      });
    }

    Query query = FirebaseFirestore.instance
        .collection('places')
        .where('category', isEqualTo: selectedCategory)
        .orderBy('rating', descending: true)
        .limit(_limit);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    QuerySnapshot snapshot = await query.get();

    if (snapshot.docs.isEmpty) {
      setState(() {
        _hasMore = false; // ❌ No hay más datos, detener futuras cargas
      });
    } else {
      _lastDocument = snapshot.docs.last;

      List<Map<String, dynamic>> newPlaces = snapshot.docs.map((doc) {
        return {
          'name': doc['name'],
          'phone': doc['phone'],
          'address': doc['address'],
          'rating': doc['rating'],
          'image': doc['image'],
          'latitude': doc['latitude'],
          'longitude': doc['longitude'],
          'category': doc['category'],
        };
      }).toList();

      setState(() {
        _places.addAll(newPlaces);
        _hasMore = newPlaces.length >= _limit; // ✅ Solo permite más carga si trajo la cantidad esperada
      });
    }

    setState(() {
      _isLoading = false; // ✅ Marcamos como completada la carga
    });
  }



  Future<void> insertTestData() async {

    CollectionReference placesCollection = FirebaseFirestore.instance.collection('places');

    List<Map<String, dynamic>> testPlaces = [
      {
        'name': 'Desmadre pan y café',
        'phone': '+59891201846',
        'address': 'Itapebí 2108, Montevideo',
        'rating': 4.6,
        'image': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTqjLJKrIFpQSY2stnGvUsJ7VvTy86emnUb-Q&s',
        'latitude': -34.87449464177033,
        'longitude': -56.170209341642256,
        'category': 'Cafés',
      },
      {
        'name': 'Camila s Roti-Café',
        'phone': '22017004',
        'address': 'Av. Gral. San Martín 2909, Montevideo',
        'rating': 4.6,
        'image': 'https://lh3.googleusercontent.com/p/AF1QipPNZNRHVK8Y0a07cV55GIocApBpeu--uWh4fe2D=s1360-w1360-h1020',
        'latitude': -34.87126495821726,
        'longitude':  -56.18345848462236,
        'category': 'Cafés',
      },
      {
        'name': 'La Peña Parrilla',
        'phone': '22030311',
        'address': 'Pedernal 2151, Montevideo',
        'rating': 4.6,
        'image': 'https://lh5.googleusercontent.com/p/AF1QipMZMb9dO8crq60sgU44QdjIUjPj_NSrLgoKMsB6=w408-h306-k-no',
        'latitude': -34.87152966342606,
        'longitude':  -56.17083101662163,
        'category': 'Restaurantes',
      },
      {
        'name': 'Cane B&B',
        'phone': '+598 456 123 789',
        'address': 'Miguel Cané 3636, Montevideo',
        'rating': 4.7,
        'image': 'https://images.trvl-media.com/lodging/20000000/19970000/19967000/19966943/d51372b7.jpg?impolicy=resizecrop&rw=1200&ra=fit',
        'latitude': -34.853622500861455,
        'longitude':  -56.19116009593926,
        'category': 'Hoteles',
      }
    ];



    for (var place in testPlaces) {
      await placesCollection.add(place);
     /* FirebaseFirestore.instance.collection('places').add({
        'name': 'Hotel Pet Paradise',
        'phone': '+598 456 123 789',
        'address': 'Playa Brava, Punta del Este',
        'rating': 4.0,
        'image': 'https://source.unsplash.com/200x200/?hotel,pet',
        'latitude': -34.910000,
        'longitude': -56.150000,
        'category': 'Hoteles',
      });*/
    }

    print("✅ Datos de prueba insertados en Firebase Firestore.");
  }


  /// 📌 Detecta el scroll y carga más datos automáticamente
  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && _hasMore) {
      _fetchPlaces();
    }
  }

  /// 📌 Calcula la distancia entre el usuario y cada lugar
  double _calculateDistance(double lat, double lng) {
    if (_currentPosition == null) return double.infinity;
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat,
      lng,
    );
  }

  /// 📌 Muestra el mapa en un modal
  void _showMap(double lat, double lng) {
    Completer<GoogleMapController> _controller = Completer();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ubicación en el mapa'),
          content: Container(
            width: 300,
            height: 300,
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(lat, lng),
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: MarkerId('selectedPlace'),
                  position: LatLng(lat, lng),
                ),
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  /// 📌 Construye la UI de cada lugar con la distancia
  Widget _buildPlaceCard(Map<String, dynamic> place) {
    double distance = _calculateDistance(place['latitude'], place['longitude']);
    String distanceText = distance >= 1000
        ? '${(distance / 1000).toStringAsFixed(1)} km'
        : '${distance.toStringAsFixed(0)} m';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MapScreen(
              latitude: place['latitude'],
              longitude: place['longitude'],
              placeName: place['name'],
            ),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              child: Image.network(
                place['image'],
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place['name'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text('📞 ${place['phone']}'),
                  Text('📍 ${place['address']}'),
                  Text('📏 Distancia: $distanceText'),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      Text('Calificación: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      _buildRatingStars((place['rating'] as num).toDouble()),
                    ],
                  ),
                  SizedBox(height: 5),
                  Text(
                    '🗺️ Toca para ver en el mapa',
                    style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  // 🔹 Función para mostrar la calificación con icon de paticas de perro 🐾
  Widget _buildRatingStars(double rating) {
    int fullPaws = rating.floor();
    bool hasHalfPaw = (rating - fullPaws) >= 0.5;

    return Row(
      children: List.generate(
        5,
            (index) {
          if (index < fullPaws) {
            return Icon(Icons.pets, color: Colors.amber, size: 20);
          } else if (index == fullPaws && hasHalfPaw) {
            return Icon(Icons.pets, color: Colors.amber.withOpacity(0.5), size: 20);
          } else {
            return Icon(Icons.pets, color: Colors.grey, size: 20);
          }
        },
      ),
    );
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
              'Pet Friendly',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: const Color(0xFFA0E3A7),
            elevation: 0,
          ),
        ),
      ),
      body: Column(
        children: [
          // 🔹 Barra de categorías
          Container(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: categories.map((category) {
                bool isSelected = selectedCategory == category['name'];
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: ChoiceChip(
                    label: Text(category['name']),
                    selected: isSelected,
                    selectedColor: Colors.green,
                    backgroundColor: Colors.grey[200],
                    onSelected: (bool selected) {
                      if (selectedCategory != category['name']) {
                        setState(() {
                          selectedCategory = category['name'];
                          _places.clear(); // ✅ Asegurar que la lista se vacíe antes
                          _lastDocument = null; // ✅ Resetear la paginación
                          _hasMore = true; // ✅ Permitir nuevas consultas
                        });

                          _fetchPlaces(reset: true); // ✅ Llamar con un pequeño retraso para que el estado se actualice

                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: _isLoading && _places.isEmpty // ✅ Mostrar cargando si es la primera carga
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
              controller: _scrollController,
              itemCount: _places.length + 1,
              itemBuilder: (context, index) {
                if (index < _places.length) {
                  return _buildPlaceCard(_places[index]);
                } else {
                  return _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : SizedBox();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

}
