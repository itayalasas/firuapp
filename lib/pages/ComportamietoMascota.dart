import 'package:PetCare/class/SessionProvider.dart';
import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EvaluacionMascota extends StatefulWidget {
  final String mascotaId;

  const EvaluacionMascota({Key? key, required this.mascotaId}) : super(key: key);

  @override
  _EvaluacionMascotaState createState() => _EvaluacionMascotaState();
}

class _EvaluacionMascotaState extends State<EvaluacionMascota> {
  Interpreter? _interpreter;
  String _resultado = "Cargando...";
  List<double> entradaModelo = [];


  Map<String, int> tokenMapping = { };


  @override
  void initState() {
    super.initState();
    //insertarTokensEnFirebase();
   //insertarComportamientosEnFirebase();
   //insertarNecesidadesEspecialesEnFirebase();
    _inicializarEvaluacion();
  }

  Future<void> insertarTokensEnFirebase() async {
    CollectionReference tokensRef = FirebaseFirestore.instance.collection('tokens_palabras');

    // 🔹 Lista de palabras clave y frases compuestas
    List<String> palabrasClave = [
      // 🐶 Comportamientos de perros
      "Ladrido", "Meneado de cola", "Postura de juego", "Salto excesivo",
      "Lamer excesivamente", "Morder objetos", "Orinar en casa",
      "Escarbar en el suelo", "Jalar la correa", "Dar la pata",

      // 🐱 Comportamientos de gatos
      "Ronronear", "Maullidos excesivos", "Frotarse contra personas",
      "Cazar y traer regalos", "Saltos inesperados", "Bufar o gruñir",

      // 🔹 Necesidades especiales
      "Dieta Hipoalergénica", "Epilepsia", "Ceguera", "Ansiedad por Separación",
      "Problemas de Articulaciones", "Hipotiroidismo", "Problemas Digestivos",
      "Dermatitis Alérgica", "Dieta para Enfermedad Renal", "FIV (Sida Felino)",
      "Dieta para Problemas Urinarios", "Problemas de Socialización",
      "Problemas de Incontinencia", "Dieta para Insuficiencia Renal",
      "Ansiedad en Ambientes Nuevos", "Marcaje con Orina por Estrés",
      "Problemas de Reactividad", "Pérdida de Peso",
      "Movilidad Reducida", "Sordera", "Enfermedad Crónica"
    ];

    // 🔹 Generar un código único basado en el índice
    List<Map<String, dynamic>> tokens = palabrasClave.asMap().entries.map((entry) {
      int index = entry.key + 1; // 🔹 Empezar desde 1
      return {"palabra": entry.value.toLowerCase().trim(), "codigoModelo": index};
    }).toList();

    // 🔹 Insertar cada palabra en Firestore
    for (var token in tokens) {
      await tokensRef.doc(token["palabra"]).set(token);
    }

    print("✅ Tokens insertados correctamente en Firebase.");
  }



  Future<void> insertarComportamientosEnFirebase() async {
    CollectionReference comportamientosRef =
    FirebaseFirestore.instance.collection('comportamientos_mascotas');

    // 🔹 Obtener tokens actualizados antes de insertar datos
    Map<String, int> tokenMapping = await obtenerTokensDesdeFirebase();

    // 🔹 Lista de comportamientos ampliada
    List<Map<String, dynamic>> comportamientos = [
      {"tipoMascota": "Perro", "comportamiento": "Ladrido", "descripcion": "Puede ser por alerta, ansiedad, emoción o aburrimiento."},
      {"tipoMascota": "Perro", "comportamiento": "Meneado de cola", "descripcion": "Indica felicidad, aunque si es rígido puede significar tensión."},
      {"tipoMascota": "Perro", "comportamiento": "Postura de juego", "descripcion": "Agachan el pecho y levantan la cola para invitar a jugar."},
      {"tipoMascota": "Perro", "comportamiento": "Salto excesivo", "descripcion": "Puede significar emoción extrema o falta de entrenamiento."},
      {"tipoMascota": "Perro", "comportamiento": "Lamer excesivamente", "descripcion": "Puede ser afecto, ansiedad o problemas en la piel."},
      {"tipoMascota": "Perro", "comportamiento": "Morder objetos", "descripcion": "Ansiedad, exploración o dentición en cachorros."},
      {"tipoMascota": "Perro", "comportamiento": "Orinar en casa", "descripcion": "Puede ser falta de entrenamiento, marcaje o ansiedad."},
      {"tipoMascota": "Perro", "comportamiento": "Escarbar en el suelo", "descripcion": "Comportamiento instintivo de búsqueda o enfriamiento."},
      {"tipoMascota": "Gato", "comportamiento": "Ronronear", "descripcion": "Expresión de relajación, satisfacción o incluso dolor."},
      {"tipoMascota": "Gato", "comportamiento": "Maullidos excesivos", "descripcion": "Puede indicar hambre, estrés o problemas de salud."},
      {"tipoMascota": "Gato", "comportamiento": "Frotarse contra personas", "descripcion": "Marcaje de territorio con feromonas."},
      {"tipoMascota": "Gato", "comportamiento": "Cazar y traer regalos", "descripcion": "Comportamiento instintivo de caza."},
      {"tipoMascota": "Gato", "comportamiento": "Orinar fuera del arenero", "descripcion": "Puede deberse a estrés, enfermedad o problemas de marcaje."},
      {"tipoMascota": "Gato", "comportamiento": "Saltos inesperados", "descripcion": "Liberación de energía o juego."},
    ];

    for (var comportamiento in comportamientos) {
      String palabraClave = comportamiento["comportamiento"].toString().toLowerCase().trim();
      int codigoModelo = tokenMapping[palabraClave] ?? 0;

      await comportamientosRef.add({
        ...comportamiento,
        "codigoModelo": codigoModelo,
      });
    }

    print("✅ Comportamientos insertados en Firebase.");
  }


  Future<void> insertarNecesidadesEspecialesEnFirebase() async {
    CollectionReference necesidadesRef =
    FirebaseFirestore.instance.collection('necesidades_especiales');

    // 🔹 Obtener tokens actualizados antes de insertar datos
    Map<String, int> tokenMapping = await obtenerTokensDesdeFirebase();

    // 🔹 Lista ampliada de necesidades
    List<Map<String, dynamic>> necesidadesEspeciales = [
      {"tipoMascota": "Perro", "necesidadEspecial": "Dieta Hipoalergénica", "descripcion": "Alimentación especial para perros con alergias alimentarias."},
      {"tipoMascota": "Perro", "necesidadEspecial": "Epilepsia", "descripcion": "Tratamiento con medicación para controlar convulsiones."},
      {"tipoMascota": "Perro", "necesidadEspecial": "Ceguera", "descripcion": "Necesita adaptación en casa y entrenamiento especial."},
      {"tipoMascota": "Perro", "necesidadEspecial": "Ansiedad por Separación", "descripcion": "Requiere terapia conductual y posible medicación."},
      {"tipoMascota": "Perro", "necesidadEspecial": "Problemas de Articulaciones", "descripcion": "Requiere suplementos y cuidados especiales."},
      {"tipoMascota": "Perro", "necesidadEspecial": "Hipotiroidismo", "descripcion": "Desequilibrio hormonal tratado con medicación."},
      {"tipoMascota": "Gato", "necesidadEspecial": "Dieta para Enfermedad Renal", "descripcion": "Alimento bajo en fósforo para gatos con enfermedad renal."},
      {"tipoMascota": "Gato", "necesidadEspecial": "FIV (Sida Felino)", "descripcion": "Sistema inmune debilitado, necesita cuidados regulares."},
      {"tipoMascota": "Gato", "necesidadEspecial": "Dermatitis Alérgica", "descripcion": "Alergias en la piel por factores ambientales o alimentos."},
      {"tipoMascota": "Gato", "necesidadEspecial": "Problemas de Socialización", "descripcion": "Miedo o agresividad con otros gatos o personas."},
      {"tipoMascota": "Gato", "necesidadEspecial": "Problemas Digestivos", "descripcion": "Dieta especial para intolerancias alimentarias."},
    ];

    for (var necesidad in necesidadesEspeciales) {
      String palabraClave = necesidad["necesidadEspecial"].toString().toLowerCase().trim();
      int codigoModelo = tokenMapping[palabraClave] ?? 0;

      await necesidadesRef.add({
        ...necesidad,
        "codigoModelo": codigoModelo,
      });
    }

    print("✅ Necesidades especiales insertadas en Firebase.");
  }


  Future<Map<String, int>> obtenerTokensDesdeFirebase() async {
    CollectionReference tokensRef = FirebaseFirestore.instance.collection('tokens_palabras');
    QuerySnapshot querySnapshot = await tokensRef.get();

    // 🔹 Convertir la lista en un mapa { palabra: codigoModelo }
    Map<String, int> tokenMapping = {
      for (var doc in querySnapshot.docs)
        doc["palabra"]: doc["codigoModelo"]
    };

    print("📌 Tokens cargados desde Firebase: $tokenMapping");
    return tokenMapping;
  }


  /// 🔹 Inicializa la Evaluación cargando modelo + datos
  Future<void> _inicializarEvaluacion() async {
    await _loadModel();
    await obtenerDatosMascota();
  }

  /// ✅ Cargar modelo TFLite
  Future<void> _loadModel() async {
    await Firebase.initializeApp();
    final model = await FirebaseModelDownloader.instance.getModel(
      "comportamiento_necesidad",
      FirebaseModelDownloadType.latestModel,
      FirebaseModelDownloadConditions(),
    );

    _interpreter = Interpreter.fromFile(model.file);
    print("✅ Modelo cargado correctamente.");
  }

  /// 🔹 Obtener datos de Firebase y prepararlos para el modelo
  Future<void> obtenerDatosMascota() async {
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(sessionProvider.user!.userId)
          .collection('mascotas')
          .doc(widget.mascotaId)
          .get();

      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;

        List<dynamic> comportamientos = data["comportamientosMascota"] ?? [];
        List<dynamic> necesidadesEspeciales = data["necesidadMascota"] ?? [];

        // 🔥 Convertimos cada lista de palabras en secuencias numéricas
        List<int> secuenciaComportamientos =
        tokenizarTexto(comportamientos.map((c) => c["comportamiento"] as String).toList());

        List<int> secuenciaNecesidades =
        tokenizarTexto(necesidadesEspeciales.map((n) => n["necesidadEspecial"] as String).toList());

        // 🔹 Construimos la entrada para el modelo
        entradaModelo = [
          data["tipoMascota"] == "Perro" ? 1.0 : 0.0,
          comportamientos.length.toDouble(),
          necesidadesEspeciales.length.toDouble(),
        ];

        print("🐾 Entrada al modelo (después de obtener datos): $entradaModelo");

        if (_interpreter != null) {
          ejecutarPrediccion();
        }
      } else {
        setState(() {
          _resultado = "⚠️ No se encontraron datos para esta mascota.";
        });
      }
    } catch (e) {
      setState(() {
        _resultado = "❌ Error al obtener datos.";
      });
    }
  }

  List<int> tokenizarTexto(List<String> palabras) {
    return palabras
        .map((palabra) => tokenMapping[palabra.toLowerCase()] ?? 0) // 🔥 Si la palabra no existe, asigna 0
        .toList();
  }




  /// 🔹 Ejecutar predicción
  void ejecutarPrediccion() {
    if (_interpreter == null) return;
    var salida = List.filled(1, 0.0).reshape([1, 1]);
    _interpreter!.run(entradaModelo, salida);
    setState(() {
      _resultado = "Nivel de cuidado: ${(salida[0][0] * 100).toInt()}%";
    });
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Evaluación de la Mascota")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Resultado:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text(_resultado, style: TextStyle(fontSize: 20, color: Colors.blue)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: obtenerDatosMascota,
              child: Text("Actualizar Evaluación"),
            ),
          ],
        ),
      ),
    );
  }
}
