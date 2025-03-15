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

  @override
  void initState() {
    super.initState();
    _cargarPesos();
  }

  void _cargarPesos() {
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    final mascotaActualizada = sessionProvider.user?.mascotas
        ?.firstWhere((m) => m.mascotaid == widget.mascota.mascotaid, orElse: () => widget.mascota);

    if (mascotaActualizada == null) return;

    List<PesoMascota> pesos = mascotaActualizada.peso ?? [];
    DateTime ahora = DateTime.now();
    DateTime inicioFiltro;
    DateTime finFiltro;

    switch (_filtroSeleccionado) {
      case 'Última semana':
        inicioFiltro = ahora.subtract(Duration(days: 7));
        finFiltro = ahora; // 🔹 Desde hace 7 días hasta hoy
        break;
      case 'Último mes':
        inicioFiltro = ahora.subtract(Duration(days: 30));
        finFiltro = ahora; // 🔹 Desde hace 30 días hasta hoy
        break;
      default: // 🔹 "Seleccionar mes"
        inicioFiltro = _fechaFiltro;
        finFiltro = DateTime(_fechaFiltro.year, _fechaFiltro.month + 1, _fechaFiltro.day);
        break;
    }

    setState(() {
      _listaPesos = pesos.where((peso) => peso.fecha.isAfter(inicioFiltro) && peso.fecha.isBefore(finFiltro)).toList();
    });
  }


  void _seleccionarMes() async {
    DateTime now = DateTime.now(); // 🔹 Fecha actual
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaFiltro,
      firstDate: DateTime(2020), // 🔹 No puede seleccionar antes de 2020
      lastDate: now, // 🔹 No puede seleccionar una fecha futura
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked.isBefore(now)) {
      setState(() {
        _fechaFiltro = picked;
        _filtroSeleccionado = 'Seleccionar mes';
        _cargarPesos();
      });
    } else if (picked != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No puedes seleccionar una fecha futura."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {

    // Asegurarse de que el color de la barra de estado no sea cubierto
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      // Hace la barra de estado transparente
      statusBarIconBrightness: Brightness
          .dark, // Cambia el color de los íconos en la barra de estado
    ));

    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        // Tamaño estándar de AppBar
        child: SafeArea(
          child: AppBar(
            title: Text(
              'Histórico de Pesos de ${widget.mascota.nombre}',
              style: TextStyle(
                fontFamily: 'Poppins', // Fuente personalizada
                fontSize: 20,
              ),
            ),
            backgroundColor: const Color(0xFFA0E3A7),
            // Color verde menta de la marca
            elevation: 0, // Sin sombra
          ),
        ),
      ),
      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: _filtroSeleccionado,
                  items: ['Última semana', 'Último mes', 'Seleccionar mes'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue == 'Seleccionar mes') {
                      _seleccionarMes();
                    } else {
                      setState(() {
                        _filtroSeleccionado = newValue!;
                        _cargarPesos();
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _listaPesos.isEmpty
                ? Center(
              child: Text(
                'No hay datos disponibles para este filtro.',
                style: TextStyle(fontSize: 16, fontFamily: 'Poppins', color: Colors.grey),
              ),
            )
                : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 🔹 Contenedor para la gráfica con altura fija
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4, // 🔹 Reduce el tamaño de la gráfica
                    child: BarChart(
                      BarChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                int index = value.toInt();
                                if (index < _listaPesos.length) {
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    child: Text(
                                      DateFormat('dd/MM').format(_listaPesos[index].fecha),
                                      style: TextStyle(fontSize: 12, color: Colors.black),
                                    ),
                                  );
                                }
                                return SizedBox.shrink();
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                if (value % 5 == 0 && _listaPesos.isNotEmpty) {
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    child: Text(
                                      '${value.toInt()} ${_listaPesos[0].um}',
                                      style: TextStyle(fontSize: 12, color: Colors.black),
                                    ),
                                  );
                                }
                                return SideTitleWidget(axisSide: meta.axisSide, child: Text(""));
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        barGroups: _listaPesos.map((peso) {
                          return BarChartGroupData(
                            x: _listaPesos.indexOf(peso),
                            barRods: [
                              BarChartRodData(
                                toY: peso.peso,
                                color: Colors.blue,
                                width: 15,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ],
                          );
                        }).toList(),
                        alignment: BarChartAlignment.spaceAround,
                        minY: 0,
                        maxY: _listaPesos.isNotEmpty
                            ? _listaPesos.map((p) => p.peso).reduce((a, b) => a > b ? a : b) + 2
                            : 10,
                      ),
                    ),
                  ),

                  // 🔹 Espaciado para que el botón flotante no bloquee la vista
                  SizedBox(height: 20),
                ],
              ),
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
    _cargarPesos();
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