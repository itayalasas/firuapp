import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../class/Comportamientos.dart';
import '../class/Mascota.dart';
import '../class/NecesidadEspecial.dart';
import '../class/NecesidadesEspecialesMascota.dart';
import '../class/SessionProvider.dart';
import 'Config.dart';

class CompletarMascotaPage extends StatefulWidget {
  final Mascota selectedMascota;

  CompletarMascotaPage({required this.selectedMascota});

  @override
  _CompletarMascotaPageState createState() => _CompletarMascotaPageState();
}

class _CompletarMascotaPageState extends State<CompletarMascotaPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  String? _castradoSeleccionado; // Variable para guardar el estado de "Castrado"
  late String _fechaNacimiento = '';
  List<Comportamientos> _comportamientosDisponibles = [];
  List<Comportamientos> _comportamientosSeleccionados = [];
  List<NecesidadEspecial> _necesidadesEspecialesSeleccionados = [];
  List<NecesidadEspecial> _necesidadesEspecialesDisponibles = [];
  bool isLoading = true;
  bool isLoadingNecesidades = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _fetchComportamientos();
    _fetchNecesidadesEspeciales();

  }

  void _initializeControllers() {
    if (widget.selectedMascota.nombre.isEmpty) {
      _controllers['nombre'] = TextEditingController();
    }
    if (widget.selectedMascota.raza.isEmpty) {
      _controllers['raza'] = TextEditingController();
    }
    if (widget.selectedMascota.genero == "") {
      _controllers['genero'] = TextEditingController();
    }
    if (widget.selectedMascota.color == "") {
      _controllers['color'] = TextEditingController();
    }
    if (widget.selectedMascota.tamano == "") {
      _controllers['tamano'] = TextEditingController();
    }
    if (widget.selectedMascota.personalidad == "") {
      _controllers['personalidad'] = TextEditingController();
    }
    if (widget.selectedMascota.historialMedico == null) {
      _controllers['historialMedico'] = TextEditingController();
    }

    if (widget.selectedMascota.fechaNacimiento == "") {
      _controllers['fechaNacimiento'] = TextEditingController();
    }
    if (widget.selectedMascota.microchip == "") {
      _controllers['microchip'] = TextEditingController();
    }
    if (widget.selectedMascota.fechaRegistroChip == "") {
      _controllers['fechaRegistroChip'] = TextEditingController();
    }


    if (widget.selectedMascota.castrado == "" ||
        widget.selectedMascota.castrado!.isEmpty ||
        (widget.selectedMascota.castrado != "Sí" &&
            widget.selectedMascota.castrado != "No")) {
      _castradoSeleccionado =
      "No"; // Valor predeterminado en caso de datos inválidos
    } else {
      _castradoSeleccionado = widget.selectedMascota.castrado;
    }
  }

  // **Cargar comportamientos desde la API**
  Future<void> _fetchComportamientos() async {
    try {
      String especie = widget.selectedMascota.especie; // Tipo de mascota (Ej: "perro", "gato")

      // 🔹 Acceder a la colección de Firestore
      CollectionReference collection =
      FirebaseFirestore.instance.collection('comportamientos_mascotas');

      // 🔹 Filtrar por tipo de mascota
      QuerySnapshot querySnapshot = await collection.where('tipoMascota', isEqualTo: especie).get();

      if (querySnapshot.docs.isNotEmpty) {
        List<Comportamientos> comportamientos = querySnapshot.docs.map((doc) {
          return Comportamientos.fromJson(doc.data() as Map<String, dynamic>);
        }).toList();

        // 🔹 Guardar en la lista de comportamientos disponibles
        setState(() {
          _comportamientosDisponibles = comportamientos;
          isLoading = false;
        });
      } else {
        // Si no hay comportamientos para esa especie, limpiar la lista
        setState(() {
          _comportamientosDisponibles = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('❌ Error al obtener comportamientos de Firebase: $e');
    }
  }

  // **Cargar necesidades especiales desde la API**
  Future<void> _fetchNecesidadesEspeciales() async {
    try {
      String especie = widget.selectedMascota.especie; // Tipo de mascota (Ej: "perro", "gato")

      // 🔹 Acceder a la colección de Firestore
      CollectionReference collection =
      FirebaseFirestore.instance.collection('necesidades_especiales');

      // 🔹 Filtrar por tipo de mascota
      QuerySnapshot querySnapshot = await collection.where('tipoMascota', isEqualTo: especie).get();

      if (querySnapshot.docs.isNotEmpty) {
        List<NecesidadEspecial> necesidades = querySnapshot.docs.map((doc) {
          return NecesidadEspecial.fromJson(doc.data() as Map<String, dynamic>);
        }).toList();

        // 🔹 Guardar en la lista de necesidades especiales disponibles
        setState(() {
          _necesidadesEspecialesDisponibles = necesidades;
          isLoadingNecesidades = false;
        });
      } else {
        // Si no hay necesidades para esa especie, limpiar la lista
        setState(() {
          _necesidadesEspecialesDisponibles = [];
          isLoadingNecesidades = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingNecesidades = false;
      });
      print('❌ Error al obtener necesidades especiales de Firebase: $e');
    }
  }

  Future<void> _guardarDatos() async {
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);

    if (!sessionProvider.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Debe iniciar sesión para guardar la mascota')),
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

    final String mascotaId = widget.selectedMascota.mascotaid;

    // **Actualizar los valores en la mascota con los datos de los campos**
    _controllers.forEach((key, controller) {
      if (controller.text.isNotEmpty) {
        switch (key) {
          case 'nombre':
            widget.selectedMascota.nombre = controller.text;
            break;
          case 'raza':
            widget.selectedMascota.raza = controller.text;
            break;
          case 'genero':
            widget.selectedMascota.genero = controller.text;
            break;
          case 'color':
            widget.selectedMascota.color = controller.text;
            break;
          case 'tamano':
            widget.selectedMascota.tamano = controller.text;
            break;
          case 'personalidad':
            widget.selectedMascota.personalidad = controller.text;
            break;
          case 'historialMedico':
            widget.selectedMascota.historialMedico = controller.text;
            break;
          case 'fechaNacimiento':
            widget.selectedMascota.fechaNacimiento = controller.text;
            break;
          case 'microchip':
            widget.selectedMascota.microchip = controller.text;
            break;
          case 'fechaRegistroChip':
            widget.selectedMascota.fechaRegistroChip = controller.text.isNotEmpty
                ? DateTime.tryParse(controller.text)
                : null;
            break;
          default:
            print("Campo no reconocido: $key");
            break;
        }
      }
    });

    try {
      // **Actualizar datos en el objeto local**
      widget.selectedMascota.castrado = _castradoSeleccionado;
      widget.selectedMascota.necesidadMascota = _necesidadesEspecialesSeleccionados;
      widget.selectedMascota.comportamientosMascota = _comportamientosSeleccionados;

      // **Calcular edad si se ingresó fecha de nacimiento**
      if (_fechaNacimiento.isNotEmpty) {
        widget.selectedMascota.edad= calcularEdad(_fechaNacimiento);
      }

      // **Referencia a la mascota en Firestore**
      DocumentReference mascotaRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('mascotas')
          .doc(mascotaId);

      // **Convertir la mascota a JSON**
      Map<String, dynamic> mascotaData = widget.selectedMascota.toJson();

      // **Actualizar la mascota en Firestore**
      await mascotaRef.update(mascotaData);

      // **Actualizar subcolecciones en Firestore**
      WriteBatch batch = FirebaseFirestore.instance.batch();


      // **Ejecutar batch para escribir todo junto**
      await batch.commit();

      // **Actualizar la lista de mascotas en `SessionProvider`**
      sessionProvider.user?.mascotas?.removeWhere((m) => m.mascotaid == mascotaId);
      sessionProvider.user?.mascotas?.add(widget.selectedMascota);
      sessionProvider.notifyListeners();

      // **Mostrar mensaje de éxito**
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mascota actualizada con éxito')),
      );

      Navigator.pop(context, widget.selectedMascota.toJson());
    } catch (e) {
      print('❌ Error al actualizar la mascota en Firestore: $e');
    }

  }

  int calcularEdad(String fechaNacimiento) {
    DateTime fechaNacimientoDT = DateTime.parse(fechaNacimiento);
    DateTime fechaActual = DateTime.now();

    int edad = fechaActual.year - fechaNacimientoDT.year;

    // Comprueba si el cumpleaños aún no ha ocurrido este año
    if (fechaActual.month < fechaNacimientoDT.month ||
        (fechaActual.month == fechaNacimientoDT.month &&
            fechaActual.day < fechaNacimientoDT.day)) {
      edad--;
    }

    return edad;
  }

  //**Mostrar diálogo para selección de comportamientos**
  void _mostrarDialogoSeleccion() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<Comportamientos> seleccionTemporal = List.from(_comportamientosSeleccionados);

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // Bordes redondeados
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8, // 🔹 Limita la altura del modal al 80% de la pantalla
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100], // Fondo gris claro
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🔹 Encabezado estilo AppBar
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFA0E3A7), // Verde menta
                        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                      ),
                      padding: EdgeInsets.all(15),
                      child: Center(
                        child: Text(
                          'Selecciona Comportamientos',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),

                    // 🔹 Contenido desplazable
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(15),
                        child: Column(
                          children: _comportamientosDisponibles.map((comportamiento) {
                            // 🔹 Verifica si el comportamiento ya está seleccionado
                            bool isSelected = seleccionTemporal.any((c) => c.comportamiento == comportamiento.comportamiento);

                            return CheckboxListTile(
                              title: Text(
                                comportamiento.comportamiento, // ✅ Muestra el nombre del comportamiento
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.black),
                              ),
                              subtitle: Text(
                                comportamiento.descripcion, // ✅ Muestra la descripción debajo del título
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.grey),
                              ),
                              value: isSelected,
                              activeColor: Colors.green, // ✅ Color cuando está seleccionado
                              checkColor: Colors.white,
                              onChanged: (bool? value) {
                                setStateDialog(() { // 🔹 Actualiza el estado dentro del modal
                                  if (value == true) {
                                    if (!seleccionTemporal.any((c) => c.comportamiento == comportamiento.comportamiento)) {
                                      seleccionTemporal.add(comportamiento);
                                    }
                                  } else {
                                    seleccionTemporal.removeWhere((c) => c.comportamiento == comportamiento.comportamiento);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    )
                    ,

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

                          // 🔹 Botón de aceptar con estilo personalizado
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _comportamientosSeleccionados = List.from(seleccionTemporal);
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green, // Verde menta
                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Aceptar',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }





  // **Mostrar diálogo para selección de necesidades especiales**
  void _mostrarDialogoSeleccionNecesidadesEspeciales() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<NecesidadEspecial> seleccionTemporal = List.from(_necesidadesEspecialesSeleccionados);

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // Bordes redondeados
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8, // 🔹 Limita la altura del modal al 80% de la pantalla
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100], // Fondo gris claro
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🔹 Encabezado estilo AppBar
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFA0E3A7), // Verde menta
                        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                      ),
                      padding: EdgeInsets.all(15),
                      child: Center(
                        child: Text(
                          'Selecciona necesidad especial',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),

                    // 🔹 Contenido desplazable
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(15),
                        child: Column(
                          children: _necesidadesEspecialesDisponibles.map((necesidad) {
                            // Verifica si la necesidad ya está seleccionada
                            bool isSelected = seleccionTemporal.any((n) => n.necesidadEspecial == necesidad.necesidadEspecial);

                            return CheckboxListTile(
                              title: Text(
                                necesidad.necesidadEspecial, // 🔹 Muestra el nombre de la necesidad especial
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.black),
                              ),
                              subtitle: Text(
                                necesidad.descripcion, // 🔹 Muestra la descripción de la necesidad especial
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.grey),
                              ),
                              value: isSelected,
                              activeColor: Colors.green, // ✅ Color verde cuando está seleccionado
                              checkColor: Colors.white,
                              onChanged: (bool? value) {
                                setStateDialog(() { // 🔹 Actualiza el estado dentro del modal
                                  if (value == true) {
                                    if (!seleccionTemporal.any((n) => n.necesidadEspecial == necesidad.necesidadEspecial)) {
                                      seleccionTemporal.add(necesidad);
                                    }
                                  } else {
                                    seleccionTemporal.removeWhere((n) => n.necesidadEspecial == necesidad.necesidadEspecial);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
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

                          // 🔹 Botón de aceptar con estilo personalizado
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _necesidadesEspecialesSeleccionados = List.from(seleccionTemporal);
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green, // Verde menta
                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Aceptar',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
              'Completar Datos de ${widget.selectedMascota.nombre}',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: const Color(0xFFA0E3A7), // Color verde menta de la marca
            elevation: 0,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ..._buildFormFields(),
              if (widget.selectedMascota.castrado != null)
              _buildCastradoDropdown(),
              if (widget.selectedMascota.edad ==0)
                _buildFechaNacimiento(),
              if ( widget.selectedMascota.necesidadMascota!.isEmpty)
                _buildNecesidadEspecialSelector(),

              if ( widget.selectedMascota.comportamientosMascota!.isEmpty)
                _buildComportamientoSelector(),
              SizedBox(height: 20),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                child: Text(
                  'Guardar',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 16,
                      color: const Color(0xFFFFFFFF)),

                ),
                onPressed: _guardarDatos,
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

  // **Selector de comportamiento con botón de selección múltiple**
  Widget _buildComportamientoSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Comportamiento", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),

            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _mostrarDialogoSeleccion,
              child: Text(
                _comportamientosSeleccionados.isEmpty
                    ? 'Seleccionar comportamientos'
                    : 'Seleccionados: ${_comportamientosSeleccionados.map((e) => e.comportamiento).join(", ")}',
              ),
            ),
          ],
      ),
    );
  }


  // **Selector de comportamiento con botón de selección múltiple**
  Widget _buildNecesidadEspecialSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Necesidad Especial", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),

            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _mostrarDialogoSeleccionNecesidadesEspeciales,
              child: Text(
                _necesidadesEspecialesSeleccionados.isEmpty
                    ? 'Seleccionar necesidad especial'
                    : 'Seleccionados: ${_necesidadesEspecialesSeleccionados.map((e) => e.necesidadEspecial).join(", ")}',
              ),
            ),
          ],
      ),
    );
  }

  List<Widget> _buildFormFields() {
    List<Widget> fields = [];

    _controllers.forEach((key, controller) {
      fields.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: key.toUpperCase(),
              prefixIcon: Icon(Icons.edit, color: Colors.green), // Ícono genérico
              filled: true,
              fillColor: Colors.white, // Fondo blanco
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), // Bordes redondeados
              ),
            ),
            style: TextStyle(color: Colors.black),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese ${key.toLowerCase()}';
              }
              return null;
            },
          ),
        ),
      );
    });

    return fields;
  }


  // Widget para el Dropdown de "Castrado"
  Widget _buildCastradoDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: DropdownButtonFormField<String>(
        value: _castradoSeleccionado,
        decoration: InputDecoration(
          labelText: "¿Está castrado?",
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), // Bordes redondeados
          ),
        ),
        icon: Icon(Icons.arrow_drop_down, color: Colors.green), // Ícono de flecha verde
        dropdownColor: Colors.white, // Color del menú desplegable
        isExpanded: true, // Asegura que el combo se expanda bien dentro del diseño
        menuMaxHeight: 200, // Altura máxima del menú desplegable

        items: ['Sí', 'No'].map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Row(
              children: [
                Icon(value == 'Sí' ? Icons.check_circle : Icons.cancel, color: Colors.green),
                SizedBox(width: 10),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }).toList(),

        onChanged: (newValue) {
          setState(() {
            _castradoSeleccionado = newValue!;
          });
        },

        validator: (value) => value == null ? 'Seleccione una opción' : null,
      ),
    );
  }


  Widget _buildFechaNacimiento() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 20),

          // Botón moderno con icono de calendario
          ElevatedButton.icon(
            onPressed: () => _selectFechaNacimiento(context),
            icon: Icon(Icons.calendar_today, color: Colors.white), // Icono de calendario
            label: Text(
              'Seleccionar Fecha de Nacimiento',
              style: TextStyle(fontSize: 16, fontFamily: 'Poppins', color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey, // Color verde menta
              padding: EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          SizedBox(height: 20),

          // Mostrar la fecha seleccionada
          Text(
            _fechaNacimiento.isEmpty
                ? 'No se ha seleccionado ninguna fecha'
                : 'Fecha seleccionada: $_fechaNacimiento',
            style: TextStyle(fontSize: 16, fontFamily: 'Poppins'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectFechaNacimiento(BuildContext context) async {
    Locale myLocale = Localizations.localeOf(context); // Obtener el idioma del sistema

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: myLocale, // Configura el idioma del calendario
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.green, // Color principal
            colorScheme: ColorScheme.light(primary: Colors.green), // Botones en verde
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != DateTime.now()) {
      setState(() {
        _fechaNacimiento = DateFormat('yyyy-MM-dd', myLocale.toString()).format(picked); // Formato en español
      });
    }
  }

}
