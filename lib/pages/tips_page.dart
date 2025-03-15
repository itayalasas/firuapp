import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'Utiles.dart';



class PetTipsPage extends StatefulWidget {
  @override
  _PetTipsPageState createState() => _PetTipsPageState();
}

class _PetTipsPageState extends State<PetTipsPage> {
  late Future<List<PetTip>> _futureTips;

  final List<PetTip> sampleTips = [
    PetTip(
      title: 'Cuidado de la raza Golden Retriever',
      description: 'El Golden Retriever necesita mucho ejercicio y una dieta equilibrada.',
      details: 'Asegúrate de cepillar su pelaje regularmente. Requiere actividad física diaria y visitas frecuentes al veterinario para mantener su salud.',
      base64Image: 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/wcAAwAB/29wAAAAASUVORK5CYII=', // Imagen de ejemplo en base64
    ),
    PetTip(
      title: 'Comida recomendada para gatos',
      description: 'Los gatos requieren una dieta alta en proteínas.',
      details: 'Considera alimentos con carne fresca y evita el exceso de carbohidratos. Ofrece comida húmeda y seca en proporciones adecuadas.',
      base64Image: 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/wcAAwAB/29wAAAAASUVORK5CYII=', // Imagen de ejemplo en base64
    ),
    // Agrega más tips de ejemplo aquí
  ];

  @override
  void initState() {
    super.initState();
    _futureTips = _fetchTips();
  }

  Future<List<PetTip>> _fetchTips() async {
    final apiUrl = 'https://example.com/api/pet_tips'; // Reemplaza con la URL de tu API
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => PetTip.fromJson(item)).toList();
      } else {
        // Si la solicitud falla, retorna los datos de ejemplo
        return sampleTips;
      }
    } catch (e) {
      // En caso de error (API no disponible, etc.), usa los datos de ejemplo
      return sampleTips;
    }
  }

  void _showTipDetails(BuildContext context, PetTip tip) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(tip.title),
          content: Text(tip.details),
          actions: [
            TextButton(
              child: Text('Cerrar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  List<PetTip> _getRandomTips(List<PetTip> tips, int count) {
    final random = Random();
    List<PetTip> randomTips = [];
    List<int> usedIndexes = [];

    while (randomTips.length < count && randomTips.length < tips.length) {
      int index = random.nextInt(tips.length);
      if (!usedIndexes.contains(index)) {
        randomTips.add(tips[index]);
        usedIndexes.add(index);
      }
    }

    return randomTips;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Consejos para Mascotas'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<PetTip>>(
        future: _futureTips,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error al cargar los tips'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No hay tips disponibles'));
          } else {
            final tips = snapshot.data!;
            final randomTips = _getRandomTips(tips, 3); // Cambia '3' por el número deseado de tips

            return ListView.builder(
              itemCount: randomTips.length,
              itemBuilder: (context, index) {
                final tip = randomTips[index];
                return GestureDetector(
                  onTap: () => _showTipDetails(context, tip),
                  child: PetTipCard(tip: tip),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class PetTip {
  final String title;
  final String description;
  final String details;
  final String base64Image;

  PetTip({
    required this.title,
    required this.description,
    required this.details,
    required this.base64Image,
  });

  factory PetTip.fromJson(Map<String, dynamic> json) {
    return PetTip(
      title: json['title'],
      description: json['description'],
      details: json['details'],
      base64Image: json['base64Image'],
    );
  }
}

class PetTipCard extends StatelessWidget {
  final PetTip tip;

  PetTipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            child: Image(
              image: Utiles.buildImageBase64(tip.base64Image, tip.title),
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  tip.description,
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
