import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../class/Mascota.dart';
import '../class/PesoMascota.dart';

class EvaluationResult {
  final String value;
  final bool success;
  EvaluationResult(this.value, {this.success = true});
}

class EvaluacionPage extends StatefulWidget {
  final Mascota mascota;
  EvaluacionPage({required this.mascota});

  @override
  _EvaluacionPageState createState() => _EvaluacionPageState();
}

class _EvaluacionPageState extends State<EvaluacionPage> {
  double _progress = 0.0;
  String _currentMessage = '';
  bool _done = false;

  // Resultados de cada etapa
  final Map<String, EvaluationResult> _results = {};

  // Rango nutricional
  double _pesoMin = 0.0;
  double _pesoMax = 0.0;

  // Aquí guardaremos la recomendación de cuidado
  String? _recomendacion;

  @override
  void initState() {
    super.initState();
    _runEvaluation();
  }

  Future<void> _runEvaluation() async {
    final steps = [
      {
        'message': 'Obteniendo rango de raza…',
        'action': () async {
          final raza = widget.mascota.raza;
          final query = await FirebaseFirestore.instance
              .collection('tipo_raza')
              .where('nombre', isEqualTo: raza)
              .limit(1)
              .get();
          if (query.docs.isNotEmpty) {
            final data = query.docs.first.data();
            _pesoMin = (data['pesoMin_kg'] as num).toDouble();
            _pesoMax = (data['pesoMax_kg'] as num).toDouble();
            _results['Rango nutricional'] = EvaluationResult(
              'Min: ${_pesoMin.toStringAsFixed(1)}kg, '
                  'Max: ${_pesoMax.toStringAsFixed(1)}kg',
            );
          } else {
            _results['Rango nutricional'] = EvaluationResult(
              'No encontrado',
              success: false,
            );
          }
        }
      },
      {
        'message': 'Evaluando estado nutricional…',
        'action': () async {
          final pesos = widget.mascota.peso ?? [];
          if (pesos.isEmpty) {
            _results['Estado nutricional'] = EvaluationResult(
              'Sin datos',
              success: false,
            );
          } else {
            final ultimo = pesos.last.peso;
            final estado = _evaluarEstado(ultimo);
            _results['Estado nutricional'] =
                EvaluationResult(estado, success: true);
          }
        }
      },
      {
        'message': 'Calculando edad…',
        'action': () async {
          final edad = _calcularEdad();
          _results['Edad'] = EvaluationResult('$edad años');
        }
      },
      {
        'message': 'Sugiriendo posibles enfermedades…',
        'action': () async {
          final pesos = widget.mascota.peso ?? [];
          if (pesos.isEmpty) {
            _results['Enfermedad sugerida'] = EvaluationResult(
              'Sin datos de peso',
              success: false,
            );
            _recomendacion = null;
          } else {
            final ultimoPeso = pesos.last.peso;
            final edad = _calcularEdad();
            // Consultamos Firestore para enfermedad + recomendaciones
            final pesoEstado = _evaluarEstado(ultimoPeso);
            final snap = await FirebaseFirestore.instance
                .collection('enfermedades_mascota')
                .where('especie', isEqualTo: widget.mascota.especie)
                .where('raza', isEqualTo: widget.mascota.raza)
                .where('pesoEstado', isEqualTo: pesoEstado)
                .get();
            String enfermedad = 'Sin sugerencias';
            String? rec;
            for (final doc in snap.docs) {
              final data = doc.data();
              final min = (data['edadMin'] as num).toInt();
              final max = (data['edadMax'] as num).toInt();
              if (edad >= min && edad <= max) {
                enfermedad = data['enfermedad'] as String;
                rec = data['recomendaciones'] as String?;
                break;
              }
            }
            _results['Enfermedad sugerida'] =
                EvaluationResult(enfermedad, success: true);
            _recomendacion = rec;
          }
        }
      },
    ];

    for (var i = 0; i < steps.length; i++) {
      setState(() {
        _currentMessage = steps[i]['message'] as String;
        _progress = i / steps.length;
      });
      try {
        await (steps[i]['action'] as Future<void> Function())();
      } catch (_) {
        _results[steps[i]['message'] as String] = EvaluationResult(
          'Error al ejecutar',
          success: false,
        );
      }
    }

    setState(() {
      _currentMessage = 'Evaluación completada';
      _progress = 1.0;
      _done = true;
    });
  }

  int _calcularEdad() {
    if (widget.mascota.fechaNacimiento != null &&
        widget.mascota.fechaNacimiento!.isNotEmpty) {
      try {
        final nacimiento = DateFormat('yyyy-MM-dd')
            .parse(widget.mascota.fechaNacimiento!);
        final now = DateTime.now();
        int years = now.year - nacimiento.year;
        if (now.month < nacimiento.month ||
            (now.month == nacimiento.month && now.day < nacimiento.day)) {
          years--;
        }
        return years;
      } catch (e) {}
    }
    return widget.mascota.edad ?? 0;
  }

  String _evaluarEstado(double peso) {
    if (peso < _pesoMin) return 'Bajo peso';
    if (peso > _pesoMax) return 'Sobrepeso';
    return 'Normal';
  }

  @override
  Widget build(BuildContext context) {
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
              'Evaluación de ${widget.mascota.nombre}',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 20),
            ),
            backgroundColor: const Color(0xFFA0E3A7),
            elevation: 0,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _done
            ? SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._results.entries.map((e) => ListTile(
                title: Text(e.key),
                trailing: Icon(
                  e.value.success
                      ? Icons.check_circle
                      : Icons.error_outline,
                  color: e.value.success ? Colors.green : Colors.red,
                ),
                subtitle: Text(e.value.value),
              )),
              if (_recomendacion != null && _recomendacion!.isNotEmpty)
                Card(
                  margin: EdgeInsets.only(top: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.blueAccent),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _recomendacion!,
                            style: TextStyle(fontSize: 14),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
            ],
          ),
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${(_progress * 100).toInt()}%',
              style: TextStyle(
                  fontSize: 48, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(value: _progress),
            SizedBox(height: 16),
            Text(_currentMessage),
          ],
        ),
      ),
    );
  }
}
