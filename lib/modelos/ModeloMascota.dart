import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class ModeloMascota  {
  Interpreter? _interpreter;

  Future<void> cargarModelo() async {
    await Firebase.initializeApp(); // Inicializa Firebase
    final model = await FirebaseModelDownloader.instance.getModel(
      "comportamiento_necesidad", // Nombre del modelo en Firebase
      FirebaseModelDownloadType.latestModel,
      FirebaseModelDownloadConditions(),
    );

    _interpreter = Interpreter.fromFile(model.file);
  }



  List<double> predecir(List<double> entrada) {
    if (_interpreter == null) {
      throw Exception("El modelo no ha sido cargado.");
    }

    var salida = List.filled(1, 0).reshape([1, 1]); // Salida esperada
    _interpreter!.run(entrada, salida);
    return salida[0]; // Devuelve el resultado de la predicción
  }
}
