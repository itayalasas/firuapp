import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:uuid/v4.dart';
import '../class/Mascota.dart';
import '../class/SessionProvider.dart';
import '../class/Vacunas.dart';
import '../class/VacunasFrecuencia.dart';
import '../services/MascotaService.dart';
import 'Config.dart';
import 'Utiles.dart';

class VaccinationPage extends StatefulWidget {
  final Mascota mascota;

  VaccinationPage({required this.mascota});

  @override
  _VaccinationPageState createState() => _VaccinationPageState();
}

class _VaccinationPageState extends State<VaccinationPage> {

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
      final mascotaActualizada = sessionProvider.user?.mascotas?.firstWhere(
            (m) => m.mascotaid == widget.mascota.mascotaid,
        orElse: () => widget.mascota,
      );
      if (mascotaActualizada != null) {
        setState(() {
          widget.mascota.vacunas = mascotaActualizada.vacunas ?? [];
        });
      }
    });
  }


  bool _isNearExpiry(DateTime nextDate) {
    return nextDate.isBefore(DateTime.now().add(Duration(days: 7)));
  }

  void _showAddVaccinationModal(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      builder: (_) => AddVaccinationModal(widget.mascota),
    );

    // 🔹 **Obtener la mascota actualizada desde `SessionProvider`**
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    final mascotaActualizada = sessionProvider.user?.mascotas?.firstWhere(
          (m) => m.mascotaid == widget.mascota.mascotaid,
      orElse: () => widget.mascota,
    );

    if (mascotaActualizada != null) {
      setState(() {
        widget.mascota.vacunas = mascotaActualizada.vacunas ?? [];
      });
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
      backgroundColor: Colors.grey[100], // Fondo gris claro
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        // Tamaño estándar de AppBar
        child: SafeArea(
          child: AppBar(
            title: Text(
              'Vacunas de ${widget.mascota.nombre}',
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.asset('lib/assets/logos/nueva_vacuna.webp'),
            // Cambia a la ruta de tu imagen
            SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 20.0, // Espaciado entre las columnas
                  columns: [
                    DataColumn(
                      label: Text(
                        'Nombre',
                        style: TextStyle(
                          fontFamily: 'Poppins', // Fuente personalizada
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Administración',
                        style: TextStyle(
                          fontFamily: 'Poppins', // Fuente personalizada
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Próxima',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                  rows: widget.mascota.vacunas!.map((vac) {
                    final nextDate = vac.proximaFechaVacunacion;
                    return DataRow(
                      cells: [
                        DataCell(Text(
                          vac.nombreVacuna,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                          ),
                        )),
                        DataCell(Text(
                          DateFormat.yMd().format(vac.fechaAdministracion),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                          ),
                        )),
                        DataCell(Text(
                          DateFormat.yMd().format(vac.proximaFechaVacunacion),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                          ),
                        )),
                      ],
                      color: MaterialStateProperty.resolveWith<Color>((states) {
                        if (_isNearExpiry(nextDate)) {
                          return Colors.yellow.withOpacity(
                              0.3); // Color para las fechas cercanas
                        }
                        return Colors.white; // Fondo blanco por defecto
                      }),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: const Color(0xFF67C8F1),
        // Color verde menta de la marca
        onPressed: () => _showAddVaccinationModal(context),
      ),
    );
  }
}


class AddVaccinationModal extends StatefulWidget {

  final Mascota mascota;

  AddVaccinationModal(this.mascota);

  @override
  _AddVaccinationModalState createState() => _AddVaccinationModalState();


}

class _AddVaccinationModalState extends State<AddVaccinationModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _batchController = TextEditingController();
  late DateTime _selectedDate=DateTime.now();  // Inicializamos a null
  late Future<List<VacunaFrecuencia>> _vaccinesFuture;

  late String _nombreVacuna="";
  late String _lote="";
  bool _isLoading = false;  // Variable para mostrar el loader



  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now(); // Inicializamos la fecha aquí

  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _vaccinesFuture =  fetchVacunasFrecuencia(widget.mascota.especie);

  }

  /// **🔹 Método para obtener la lista de `VacunaFrecuencia` desde Firestore**
  Future<List<VacunaFrecuencia>> fetchVacunasFrecuencia(String especie) async {
    try {
      QuerySnapshot vacunasSnapshot =
      await FirebaseFirestore.instance.collection('vacunas_frecuencia')
        .where('tipoRaza', isEqualTo: especie).get();

      List<VacunaFrecuencia> vacunas = vacunasSnapshot.docs
          .map((doc) => VacunaFrecuencia.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      return vacunas;
    } catch (e) {
      print("Error al obtener vacunas de frecuencia: $e");
      return [];
    }
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    ).then((pickedDate) {
      if (pickedDate == null) {
        return;
      }
      setState(() {
        _selectedDate = pickedDate;
      });
    });
  }




  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    final String enteredBatch = _batchController.text.trim();

    if (_nombreVacuna.isEmpty || enteredBatch.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, complete todos los campos')),
      );
      return;
    }

    final String? userId = sessionProvider.user?.userId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: No se encontró el usuario autenticado')),
      );
      return;
    }

    final String mascotaId = widget.mascota.mascotaid;
    final String vacunaId = Utiles.getId(); // Genera un ID único para la vacuna
    late  List<Vacunas>? vacunas= List.from(widget.mascota.vacunas ?? []);

    Vacunas nuevaVacuna = Vacunas(
      vacunaid: vacunaId,
      mascotaid: mascotaId,
      nombreVacuna: _nombreVacuna,
      fechaAdministracion: DateTime.now(),
      proximaFechaVacunacion: _selectedDate,
      loteVacuna: enteredBatch,
    );

     vacunas.add(nuevaVacuna);

    widget.mascota.vacunas=vacunas;

    setState(() => _isLoading = true);

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
        _nameController.clear();
        _batchController.clear();
        _isLoading = false;
      });

      Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);

      Utiles.showErrorDialog(context: context, title: "Error", content: 'Error al guardar la vacuna: $e');

    } finally {
      setState(() => _isLoading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight), // Tamaño del AppBar estándar
        child: SafeArea(
          child: AppBar(
            title: Text(
              'Registro de Vacunas',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: const Color(0xFFA0E3A7), // Color verde menta de la marca
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
              FutureBuilder<List<VacunaFrecuencia>>(
                future: fetchVacunasFrecuencia(widget.mascota.especie),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error al cargar listado de vacunas.'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No se encontraron vacunas.'));
                  } else {
                    List<String> nombresVacunas = snapshot.data!.map((vacuna) => vacuna.nombreVacuna).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 20),
                        Autocomplete<String>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            return nombresVacunas.where((nombre) =>
                                nombre.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                          },
                          onSelected: (String selectedVacuna) {
                            setState(() {
                              _nombreVacuna = selectedVacuna;

                              // Encontrar la vacuna seleccionada para calcular la próxima fecha
                              VacunaFrecuencia? vacunaSeleccionada = snapshot.data!.firstWhere(
                                      (vacuna) => vacuna.nombreVacuna == selectedVacuna);

                              if (vacunaSeleccionada != null) {
                                int edadMascotaSemanas = widget.mascota.edad! * 52; // Convertir años a semanas
                                if (edadMascotaSemanas >= vacunaSeleccionada.edadInicioSemanas) {
                                  // Calcular la próxima fecha
                                  setState(() {
                                    _selectedDate = DateTime.now().add(Duration(
                                      days: vacunaSeleccionada.frecuenciaRefuerzo * 30,
                                    ));
                                  });
                                }
                              }
                            });
                          },
                          fieldViewBuilder: (BuildContext context,
                              TextEditingController fieldTextEditingController,
                              FocusNode fieldFocusNode,
                              VoidCallback onFieldSubmitted) {
                            return TextFormField(
                              controller: fieldTextEditingController,
                              focusNode: fieldFocusNode,
                              onFieldSubmitted: (String value) {
                                onFieldSubmitted();
                              },
                              decoration: InputDecoration(
                                labelText: 'Nombre de la vacuna',
                                labelStyle: TextStyle(fontFamily: 'Poppins'),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: Icon(Icons.vaccines, color: const Color(0xFFA0E3A7)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              validator: (String? value) {
                                if (value!.isEmpty) {
                                  return 'Por favor, ingrese el nombre de la vacuna';
                                }
                                return null;
                              },
                            );
                          },
                        ),
                      ],
                    );
                  }
                },
              ),
              SizedBox(height: 30),
              TextFormField(
                controller: _batchController,
                decoration: InputDecoration(
                  labelText: 'Lote',
                  labelStyle: TextStyle(fontFamily: 'Poppins'),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: Icon(Icons.numbers, color: const Color(0xFFA0E3A7)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Por favor ingrese un número de lote.';
                  }
                  return null;
                },
                onSaved: (value) {
                  _lote = _batchController.text;
                },
              ),
              SizedBox(height: 30),
              Container(
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Próxima Fecha: ${DateFormat.yMd().format(_selectedDate)}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    TextButton(
                      child: Text(
                        'Elige fecha',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                          color: const Color(0xFFA0E3A7),
                        ),
                      ),
                      onPressed: _presentDatePicker,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                child: Text(
                  'Guardar Vacuna',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 16,
                      color: const Color(0xFFFFFFFF)),

                ),
                onPressed: _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Verde menta de la marca
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
