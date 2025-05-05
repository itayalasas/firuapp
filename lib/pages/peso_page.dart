import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../class/Mascota.dart';
import '../class/PesoMascota.dart';
import '../class/SessionProvider.dart';
import 'Utiles.dart';

class PesoPage extends StatefulWidget {
  final Mascota mascota;

  PesoPage({required this.mascota});

  @override
  _PesoPageState createState() => _PesoPageState();
}

class _PesoPageState extends State<PesoPage> {
  String _filtroSeleccionado = 'Último mes';
  DateTime _fechaFiltro = DateTime.now();
  List<PesoMascota> _listaPesos = [];

  // Rango obtenido desde Firestore según la raza
  double _pesoMax = 0.0;
  double _pesoMin = 0.0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    // 1️⃣ Consultar Firestore para obtener pesoMax_kg y pesoMin_kg
    try {
      final razaNombre = widget.mascota.raza; // Asegúrate de que tu clase Mascota tenga este campo
      final query = await FirebaseFirestore.instance
          .collection('tipo_raza')
          .where('nombre', isEqualTo: razaNombre)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        _pesoMax = (data['pesoMax_kg'] as num).toDouble();
        _pesoMin = (data['pesoMin_kg'] as num).toDouble();
      }
    } catch (e) {
      print('Error al cargar rango de tipo_raza: $e');
    }

    // 2️⃣ Cargar pesos con el filtro por defecto
    _cargarPesos();

    setState(() => _isLoading = false);
  }

  void _cargarPesos() {
    final sessionProvider =
    Provider.of<SessionProvider>(context, listen: false);
    final mascotaActualizada = sessionProvider.user?.mascotas
        ?.firstWhere((m) => m.mascotaid == widget.mascota.mascotaid,
        orElse: () => widget.mascota);

    if (mascotaActualizada == null) return;

    List<PesoMascota> pesos = mascotaActualizada.peso ?? [];
    DateTime ahora = DateTime.now();
    DateTime inicioFiltro;
    DateTime finFiltro;

    switch (_filtroSeleccionado) {
      case 'Última semana':
        inicioFiltro = ahora.subtract(Duration(days: 7));
        finFiltro = ahora;
        break;
      case 'Último mes':
        inicioFiltro = ahora.subtract(Duration(days: 30));
        finFiltro = ahora;
        break;
      default: // "Seleccionar mes"
        inicioFiltro = DateTime(_fechaFiltro.year, _fechaFiltro.month, 1);
        finFiltro = DateTime(
            _fechaFiltro.year, _fechaFiltro.month + 1, 1)
            .subtract(Duration(milliseconds: 1));
        break;
    }

    setState(() {
      _listaPesos = pesos
          .where((p) =>
      p.fecha.isAfter(inicioFiltro) && p.fecha.isBefore(finFiltro))
          .toList();
    });
  }

  Future<void> _seleccionarMes() async {
    DateTime now = DateTime.now();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaFiltro,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
              primary: Colors.green, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked.isBefore(now)) {
      setState(() {
        _fechaFiltro = picked;
        _filtroSeleccionado = 'Seleccionar mes';
        _cargarPesos();
      });
    } else if (picked != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("No puedes seleccionar una fecha futura."),
        backgroundColor: Colors.red,
      ));
    }
  }




  @override
  Widget build(BuildContext context) {
    // Barra de estado transparente
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    // Indicador de carga mientras obtenemos datos
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Preparamos los spots (x = índice + 1, y = peso)
    final spots = _listaPesos
        .asMap()
        .entries
        .map((e) => FlSpot((e.key + 1).toDouble(), e.value.peso))
        .toList();

    // Límites Y: de 0 al siguiente múltiplo de 5 sobre _pesoMax, con 10% de margen extra
    final rawMaxY = ((_pesoMax / 5).ceil() * 5).toDouble();
    final minY = 0.0;
    final maxY = rawMaxY + rawMaxY * 0.1;

    // Límites X: de 0.5 a length + 0.5 para centrar
    final minX = 0.5;
    final maxX = spots.isNotEmpty ? spots.length + 0.5 : 1.5;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: SafeArea(
          child: AppBar(
            title: Text(
              'Histórico de Pesos de ${widget.mascota.nombre}',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 20),
            ),
            backgroundColor: const Color(0xFFA0E3A7),
            elevation: 0,
          ),
        ),
      ),
      body: Column(
        children: [
          // ───────── FILTRO ─────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: _filtroSeleccionado,
                  items: ['Última semana', 'Último mes', 'Seleccionar mes']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) {
                    if (v == 'Seleccionar mes') {
                      _seleccionarMes();
                    } else {
                      setState(() {
                        _filtroSeleccionado = v!;
                        _cargarPesos();
                      });
                    }
                  },
                ),
              ],
            ),
          ),

          // ───────── GRÁFICA O MENSAJE ─────────
          Expanded(
            child: spots.isEmpty
                ? Center(
              child: Text(
                'No hay datos disponibles para este filtro.',
                style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    color: Colors.grey),
              ),
            )
                : Padding(
              padding: const EdgeInsets.all(16.0),
              child: LayoutBuilder(builder: (ctx, constraints) {
                final chartW = constraints.maxWidth;
                final chartH = constraints.maxHeight;

                return InteractiveViewer(
                  boundaryMargin: EdgeInsets.all(20),
                  minScale: 1,
                  maxScale: 2,
                  child: SizedBox(
                    width: chartW,
                    height: chartH,
                    child: Stack(
                      children: [
                        // ① El LineChart
                        LineChart(
                          LineChartData(
                            clipData: FlClipData.none(),
                            gridData: FlGridData(
                              show: true,
                              drawHorizontalLine: true,
                              drawVerticalLine: true,
                              horizontalInterval: 5,
                              verticalInterval: 1,
                              getDrawingHorizontalLine: (v) => FlLine(
                                color: Colors.grey[300],
                                strokeWidth: 1,
                                dashArray: [5, 5],
                              ),
                              getDrawingVerticalLine: (v) => FlLine(
                                color: Colors.grey[300],
                                strokeWidth: 1,
                                dashArray: [5, 5],
                              ),
                            ),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                axisNameWidget: Text('Peso mascota',
                                    style: TextStyle(fontSize: 14)),
                                axisNameSize: 20,
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    if (value % 1 == 0) {
                                      final idx = value.toInt() - 1;
                                      if (idx >= 0 &&
                                          idx < _listaPesos.length) {
                                        final fecha =
                                            _listaPesos[idx].fecha;
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              top: 4.0),
                                          child: Text(
                                            DateFormat('dd/MM')
                                                .format(fecha),
                                            style:
                                            TextStyle(fontSize: 11),
                                          ),
                                        );
                                      }
                                    }
                                    return SizedBox.shrink();
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                axisNameWidget: Text('Peso (kg)',
                                    style: TextStyle(fontSize: 14)),
                                axisNameSize: 20,
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 5,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    if (value % 5 == 0) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: TextStyle(fontSize: 12),
                                      );
                                    }
                                    return SizedBox.shrink();
                                  },
                                ),
                              ),
                              topTitles: AxisTitles(
                                  sideTitles:
                                  SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(
                                  sideTitles:
                                  SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border.all(color: Colors.black),
                            ),
                            minX: minX,
                            maxX: maxX,
                            minY: minY,
                            maxY: maxY,
                            lineBarsData: [
                              // Línea peso máximo (roja)
                              LineChartBarData(
                                spots: [
                                  FlSpot(minX, _pesoMax),
                                  FlSpot(maxX, _pesoMax),
                                ],
                                isCurved: false,
                                color: Colors.red,
                                barWidth: 2,
                                dotData: FlDotData(show: false),
                              ),
                              // Línea peso mínimo (azul)
                              LineChartBarData(
                                spots: [
                                  FlSpot(minX, _pesoMin),
                                  FlSpot(maxX, _pesoMin),
                                ],
                                isCurved: false,
                                color: Colors.blue,
                                barWidth: 2,
                                dotData: FlDotData(show: false),
                              ),
                              // Puntos de peso coloreados
                              LineChartBarData(
                                spots: spots,
                                isCurved: false,
                                color: Colors.transparent,
                                barWidth: 0,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter:
                                      (FlSpot spot, _, __, ___) {
                                    final ratio = (_pesoMax - _pesoMin)
                                        .abs() <
                                        1e-6
                                        ? 0.0
                                        : (spot.y - _pesoMin) /
                                        (_pesoMax - _pesoMin);
                                    return FlDotCirclePainter(
                                      radius: 6,
                                      color: Color.lerp(Colors.blue,
                                          Colors.red, ratio)!,
                                      strokeWidth: 0,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ② Etiquetas sobre cada punto que ahora también se mueven
                        for (var i = 0; i < spots.length; i++)
                          Positioned(
                            left: ((spots[i].x - minX) / (maxX - minX)) *
                                chartW -
                                12,
                            top: ((maxY - spots[i].y) / (maxY - minY)) *
                                chartH -
                                20,
                            child: Text(
                              spots[i].y.toStringAsFixed(1),
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          // ───────── LEYENDA ─────────
          if (spots.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 24, height: 2, color: Colors.red),
                  SizedBox(width: 4),
                  Text('Peso Máximo'),
                  SizedBox(width: 16),
                  Container(width: 24, height: 2, color: Colors.blue),
                  SizedBox(width: 4),
                  Text('Peso Mínimo'),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPesoModal(context),
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: const Color(0xFF67C8F1),
      ),
    );
  }





  void _showAddPesoModal(BuildContext context) async {
    await showModalBottomSheet<PesoMascota>(
      context: context,
      builder: (_) => AddPesoModal(widget.mascota),
    );
    _initData();
  }
}


class AddPesoModal extends StatefulWidget {
  final Mascota mascota;
  AddPesoModal(this.mascota);

  @override
  _AddPesoModalModalState createState() => _AddPesoModalModalState();
}

class _AddPesoModalModalState extends State<AddPesoModal> {
  final _formKey = GlobalKey<FormState>();
  final _pesoController = TextEditingController();
  String _unidadSeleccionada = 'kg'; // Unidad predeterminada
  bool _isLoading=false;

  Future<void> _agregarPeso() async {
    setState(() {
      _isLoading = true;
    });

    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    final double? peso = double.tryParse(_pesoController.text);

    if (peso == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, ingrese un peso válido')),
      );
      setState(() => _isLoading = false);
      return;
    }

    final String? userId = sessionProvider.user?.userId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: No se encontró el usuario autenticado')),
      );
      setState(() => _isLoading = false);
      return;
    }

    final String mascotaId = widget.mascota.mascotaid;
    final String pesoId = Utiles.getId();

    // **Clonamos la lista de pesos para evitar duplicados en la UI**
    List<PesoMascota> nuevaListaPesos = List.from(widget.mascota.peso ?? []);

    PesoMascota nuevoPeso = PesoMascota(
      pesoid: pesoId,
      fecha: DateTime.now(),
      peso: peso,
      um: _unidadSeleccionada,
    );

    nuevaListaPesos.add(nuevoPeso);

    // **Actualizar la lista clonada en la mascota**
    widget.mascota.peso = nuevaListaPesos;

    try {
      // **Referencia en Firestore**
      DocumentReference mascotaRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('mascotas')
          .doc(mascotaId);

      // **Convertimos la mascota en JSON**
      Map<String, dynamic> mascotaData = widget.mascota.toJson();

      // **Actualizar en Firestore**
      await mascotaRef.update(mascotaData);

      // **Actualizar en `SessionProvider` correctamente**
      sessionProvider.user?.mascotas?.removeWhere((m) => m.mascotaid == mascotaId);
      sessionProvider.user?.mascotas?.add(widget.mascota);
      sessionProvider.notifyListeners(); // 🔹 Notificar cambios

      // **Limpiar campo de texto y cerrar modal**
      setState(() {
        _pesoController.clear();
        _isLoading = false;
      });

      Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      Utiles.showErrorDialog(context: context, title: "Error", content: 'Error al guardar el peso: $e');

    }
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
              'Agregar Peso',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: const Color(0xFFA0E3A7),
            elevation: 0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20),
              TextFormField(
                controller: _pesoController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Peso',
                  labelStyle: TextStyle(fontFamily: 'Poppins'),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.monitor_weight, color: const Color(0xFFA0E3A7)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un peso válido';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                value: _unidadSeleccionada,
                items: <String>['kg', 'lbs'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
                        Icon(
                          value == 'kg' ? Icons.scale : Icons.line_weight,
                          color: const Color(0xFFA0E3A7),
                        ),
                        SizedBox(width: 10),
                        Text(value, style: TextStyle(fontFamily: 'Poppins')),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _unidadSeleccionada = newValue!;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Unidad',
                  labelStyle: TextStyle(fontFamily: 'Poppins'),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 30),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _agregarPeso();
                  }
                },
                child: Text(
                  'Guardar Peso',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: const Color(0xFFFFFFFF)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}