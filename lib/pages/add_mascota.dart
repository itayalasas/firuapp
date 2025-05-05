import 'dart:io';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../class/Mascota.dart';
import '../class/PesoMascota.dart';
import '../class/SessionProvider.dart';
import '../class/User.dart';
import '../services/MascotaService.dart';
import '../services/login_service.dart';
import '../services/storage_service.dart';
import 'Utiles.dart';

class AddMascotaPage extends StatefulWidget {
   final User user;
   final String? token;
  AddMascotaPage({required this.user,required this.token});

  @override
  _AgregarMascotaPageState createState() => _AgregarMascotaPageState();
}

class _AgregarMascotaPageState extends State<AddMascotaPage> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();

  TextEditingController _nombreController = TextEditingController();
  TextEditingController _razaController = TextEditingController();
  String _tipoMascotaSeleccionado = 'Perro';
  bool _siguienteHabilitado = false; // Estado para habilitar/deshabilitar el botón de siguiente
  String _colorSeleccionado = '';
  String _pesoSeleccionado = '';
  File? _imagenMascota;
  bool _isLoading = false;
  String _unidadSeleccionada = 'kg';
  List<String> _tamanosDisponibles = [];


  late String _nombreMascota='';
  late String _raza = '';
  late String _sexo = '';
  late String _fechaNacimiento = '';
  late int _edad = 0;
  late String _tamano = '';
  late double _peso = 0;
  String _imagenBase64 = '';


  int _currentPage = 0;

  File? _imageFile;
  final mascotaService = MascotaService();

  List<String> coloresDisponibles = [
    'Blanco',
    'Negro',
    'Gris',
    'Marrón',
    'Rojo',
    'Amarillo',
    'Verde',
    'Azul',
    'Naranja',
    'Rosa',
    'Morado',
    'Beige',
    'Otro',
  ];

  Future<List<String>>? _razasFuture;

  @override
  void initState() {
    super.initState();
    //insertDataToFirestore();

    _tipoMascotaSeleccionado = 'Perro'; // Valor por defecto
    _siguienteHabilitado = true; // Permitir continuar por defecto

    _razasFuture = mascotaService.fetchRazas(_tipoMascotaSeleccionado); // Ejecutar solo una vez
    _fetchTamanos(); // 🔹 Carga los tamaños al iniciar la pantalla

    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    });
  }


  // 🔹 Obtener los tamaños desde Firestore solo si aún no se han cargado
  Future<void> _fetchTamanos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1) Obtenemos todos los documentos de 'tipo_raza'
      final snapshot = await FirebaseFirestore.instance
          .collection('tipo_raza')
          .get();

      // 2) Extraemos el campo 'tamanio' y eliminamos duplicados con un Set
      final tamanosSet = snapshot.docs
          .map((doc) => doc['tamanio']?.toString() ?? '')
          .where((t) => t.isNotEmpty)
          .toSet();

      // 3) Convertimos a lista (y opcionalmente ordenamos)
      final List<String> tamanos = tamanosSet.toList()..sort();

      // 4) Actualizamos el estado
      setState(() {
        _tamanosDisponibles = tamanos;
        _isLoading = false;
      });
    } catch (e) {
      print("❌ Error al obtener tamaños de Firestore: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }


  Future<void> insertDataToFirestore() async {
    try {
      // Inicializar Firebase


      // Lista de datos a insertar
      List<Map<String, dynamic>> dataList = [
        {'id': 1, 'nombre': 'Labrador', 'tipo': 'Perro'},
        {'id': 2, 'nombre': 'Persa', 'tipo': 'Gato'},
        {'id': 3, 'nombre': 'Bulldog', 'tipo': 'Perro'},
        {'id': 4, 'nombre': 'Siames', 'tipo': 'Gato'},
        {'id': 5, 'nombre': 'Golden Retriever', 'tipo': 'Perro'},
      ];

      // Conectar con la colección en Firestore
      CollectionReference collectionRef = FirebaseFirestore.instance.collection('tipo_raza');

      // Recorrer la lista y subir los datos
      for (var data in dataList) {
        await collectionRef.add(data);
        print('✅ Registro insertado: $data');
      }

      print('🔥 Todos los datos han sido insertados correctamente.');

    } catch (e) {
      print('❌ Error insertando los datos en Firestore: $e');
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _razaController.dispose();
    super.dispose();
  }

  void _updateRazas(String tipoMascota) {
    setState(() {

      _tipoMascotaSeleccionado = tipoMascota;
      _razasFuture = mascotaService.fetchRazas(tipoMascota); // Actualiza la Future
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imagenMascota = File(pickedFile.path);

        // Convertir la imagen a base64
       /* final bytes = File(pickedFile.path).readAsBytesSync();
        _imagenBase64 = base64Encode(bytes);*/
      });
    }
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,   //
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight), // Tamaño del AppBar estándar
        child: SafeArea(
          child: AppBar(
            title: Text(
              'Agregar nueva mascota',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: const Color(0xFFA0E3A7), // Color verde menta de la marca
            elevation: 0,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: PageView(
          controller: _pageController,
          physics: NeverScrollableScrollPhysics(),
          children: [
            _buildNombrePage(),
            _buildTipoPage(),
            _buildRazaPage(),
            _buildSexoPage(),
            _buildFechaNacimientoPage(),
            //_buildEdadPage(),
            _buildColorPage(),
            _buildTamanoPage(),
            _buildPesoPage(),
            _buildFotoPage(),
          ],
        ),
      ),
    );
  }

  Widget _buildNombrePage() {
    return _buildPage(
      title: 'Nombre de la Mascota',
      onNext: () {
        if (_formKey.currentState!.validate()) {
          _goToPage(1);
        }
      },
      body: TextFormField(
        controller: _nombreController, // Asignar el TextEditingController
        decoration: InputDecoration(
          labelText: 'Nombre de la Mascota',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value!.isEmpty) {
            return 'Por favor ingrese el nombre de la mascota';
          }
          return null;
        },
        onSaved: (value) {
          _nombreMascota = value!;
        },
      ),
    );
  }


  Widget _buildRazaPage() {
    return _buildPage(
      title: 'Seleccione la raza',
      onBack: () => _goToPage(1),
      onNext: () {
        if (_formKey.currentState!.validate()) {
          _goToPage(3);
        }
      },
      body: FutureBuilder<List<String>>(
        future: _razasFuture, // Usar la variable en lugar de llamar a la función
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error al cargar las razas'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No se encontraron razas'));
          } else {
            List<String> razas = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 20),
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    return razas.where((raza) =>
                        raza.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (String selectedRaza) {
                    setState(() {
                      _raza = selectedRaza;
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
                        labelText: 'Raza',
                        border: OutlineInputBorder(),
                      ),
                      validator: (String? value) {
                        if (value!.isEmpty) {
                          return 'Por favor ingrese la raza';
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
    );
  }


  Widget _buildTipoPage() {
    return _buildPage(
      title: 'Seleccione el tipo de mascota',
      onBack: () =>_goToPage(_currentPage - 1),
      onNext: () {
        if (_siguienteHabilitado) {
          _goToPage(2);
        }
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 20),
      DropdownButtonFormField<String>(
        value: _tipoMascotaSeleccionado, // Se mantiene el valor por defecto
        items: [
          DropdownMenuItem(
            value: 'Perro',
            child: Row(
              children: [
                Image.asset(
                  'lib/assets/perro.png',
                  width: 30,
                  height: 30,
                ),
                SizedBox(width: 10),
                Text('Perro'),
              ],
            ),
          ),
          DropdownMenuItem(
            value: 'Gato',
            child: Row(
              children: [
                Image.asset(
                  'lib/assets/gato.png',
                  width: 30,
                  height: 30,
                ),
                SizedBox(width: 10),
                Text('Gato'),
              ],
            ),
          ),
          DropdownMenuItem(
            value: 'Ave',
            child: Row(
              children: [
                Image.asset(
                  'lib/assets/ave.png',
                  width: 30,
                  height: 30,
                ),
                SizedBox(width: 10),
                Text('Ave'),
              ],
            ),
          ),
          DropdownMenuItem(
            value: 'Otro',
            child: Row(
              children: [
                Image.asset(
                  'lib/assets/otro.png',
                  width: 30,
                  height: 30,
                ),
                SizedBox(width: 10),
                Text('Otro'),
              ],
            ),
          ),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _tipoMascotaSeleccionado = value;
              _siguienteHabilitado = true;
              _updateRazas(value);
            });
          }
        },
        decoration: InputDecoration(
          labelText: 'Tipo de mascota',
          border: OutlineInputBorder(),
        ),
      ),
      ],
      ),
    );
  }


  Widget _buildSexoPage() {
    return _buildPage(
      title: 'Seleccione el sexo',
      onBack: () => _goToPage(_currentPage - 1),
      onNext: () {
        if (_sexo.isEmpty) {
          // Mostrar mensaje de error si no se ha seleccionado un sexo
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Debe seleccionar un sexo'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          _goToPage(4); // Avanzar a la siguiente página si se ha seleccionado un sexo
        }
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 20),

          // Botón para Macho
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _sexo = 'Macho'; // Establece el sexo seleccionado
              });
            },
            icon: Icon(Icons.male, color: Colors.white), // Icono de varón
            label: Text(
              'Macho',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _sexo == 'Macho' ? Colors.blue : Colors.grey,
              padding: EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          SizedBox(height: 10),

          // Botón para Hembra
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _sexo = 'Hembra'; // Establece el sexo seleccionado
              });
            },
            icon: Icon(Icons.female, color: Colors.white), // Icono de hembra
            label: Text(
              'Hembra',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _sexo == 'Hembra' ? Colors.pink : Colors.grey,
              padding: EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
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




bool _isAgeUnknown = false;
  final TextEditingController _ageController = TextEditingController();

  Widget _buildFechaNacimientoPage() {
    return _buildPage(
      title: 'Fecha de Nacimiento',
      onBack: () => _goToPage(_currentPage - 1),
      onNext: () {
        final hasDate = _fechaNacimiento.isNotEmpty;
        final hasAge = _isAgeUnknown && _edad > 0;
        if (hasDate || hasAge) {
          // si es necesario, convertí _edad a string o lo que uses más adelante
          _goToPage(5);
        } else {
          Utiles.showErrorDialog(
            context: context,
            title: 'Datos incompletos',
            content: 'Debes seleccionar una fecha o ingresar la edad (> 0).',
          );
        }
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: _isAgeUnknown ? null : () => _selectFechaNacimiento(context),
            icon: Icon(Icons.calendar_today, color: Colors.white),
            label: Text('Seleccionar Fecha de Nacimiento'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),

          SizedBox(height: 10),

          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Fecha desconocida'),
            value: _isAgeUnknown,
            onChanged: (val) => setState(() {
              _isAgeUnknown = val ?? false;
              if (_isAgeUnknown) {
                _fechaNacimiento = '';
                _edad = 0;
                _ageController.clear();
              }
            }),
          ),

          if (_isAgeUnknown) ...[
            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Edad de la mascota (años)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (val) {
                final parsed = int.tryParse(val) ?? 0;
                setState(() => _edad = parsed);
              },
            ),
            SizedBox(height: 20),
          ] else
            SizedBox(height: 20),

          if (!_isAgeUnknown)
            Text(
              _fechaNacimiento.isEmpty
                  ? 'No se ha seleccionado ninguna fecha'
                  : 'Fecha seleccionada: $_fechaNacimiento',
            ),
        ],
      ),
    );
  }


  Widget _buildColorPage() {
    return _buildPage(
      title: 'Escriba color',
      onBack: () => _goToPage(_currentPage - 1),
      onNext: () {
        // Guardar el color antes de ir a la siguiente página
        //if (_colorSeleccionado.isNotEmpty) { opcional
          setState(() {
            _currentPage = 6;
          });
          _goToPage(6);
       // }
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          SizedBox(height: 10),
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<String>.empty();
              }
              return coloresDisponibles.where((String color) {
                return color.toLowerCase().contains(
                    textEditingValue.text.toLowerCase());
              });
            },
            onSelected: (String selection) {
              setState(() {
                _colorSeleccionado = selection;
              });
            },
            fieldViewBuilder: (BuildContext context,
                TextEditingController textEditingController,
                FocusNode focusNode, VoidCallback onFieldSubmitted) {
              textEditingController.text = _colorSeleccionado;

              return TextField(
                controller: textEditingController,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: 'Escribe un color',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _colorSeleccionado = value;
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTamanoPage() {
    return _buildPage(
      title: 'Escriba un tamaño',
      onBack: () => _goToPage(_currentPage - 1),
      onNext: () {
        setState(() {
          _currentPage = 7;
        });
        _goToPage(7);
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 10),

          if (_isLoading)
            Center(child: CircularProgressIndicator()) // ✅ Loader solo al inicio
          else
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return _tamanosDisponibles;
                }
                return _tamanosDisponibles.where((String tamano) {
                  return tamano.toLowerCase().contains(
                      textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (String selection) {
                setState(() {
                  _tamano = selection;
                });
              },
              fieldViewBuilder: (BuildContext context,
                  TextEditingController textEditingController,
                  FocusNode focusNode,
                  VoidCallback onFieldSubmitted) {
                textEditingController.text = _tamano;

                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Escribe o selecciona un tamaño',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _tamano = value;
                    });
                  },
                );
              },
            ),
        ],
      ),
    );
  }




  Widget _buildPesoPage() {
    return _buildPage(
      title: 'Ingrese el peso de su mascota',
      onBack: () => _goToPage(_currentPage - 1),
      onNext: () => _goToPage(8),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          SizedBox(height: 20),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Peso',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _pesoSeleccionado = value;  // Actualiza el peso seleccionado
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese un valor de peso';
              }
              return null;
            },
          ),
          SizedBox(height: 20),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Unidad',
              border: OutlineInputBorder(),
            ),
            value: _unidadSeleccionada,
            items: ['kg', 'lb'].map((String unidad) {
              return DropdownMenuItem<String>(
                value: unidad,
                child: Text(unidad),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _unidadSeleccionada = newValue!;
              });
            },
          ),
        ],
      ),
    );
  }
  Widget _buildFotoPage() {
    return _buildPage(
      title: 'Foto de la Mascota',
      onBack: () => _goToPage(_currentPage - 1), // Ir a la página anterior
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _imagenMascota == null
              ? IconButton(
            icon: Icon(Icons.camera_alt),
            iconSize: 50,
            onPressed: _pickImage,
          )
              : CircleAvatar(
            radius: 80,
            backgroundImage: FileImage(
              File(_imagenMascota!.path),
            ),
          ),
          SizedBox(height: 20),

          // Row para alinear los botones "Atrás" y "Guardar"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Botón "Atrás"
              ElevatedButton(
                onPressed: () => _goToPage(7), // Ir a la página anterior
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey, // Color del botón "Atrás"
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Atrás',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),

              // Botón "Guardar"
              SizedBox(
                width: 120, // Ancho fijo para evitar cambios de tamaño
                height: 50,  // Altura fija
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm, // Deshabilitado si está cargando
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Mismo color que "Siguiente"
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                    width: 24, // Mantiene el tamaño del botón
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    'Guardar',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildPage({
    required String title,
    VoidCallback? onBack,
    VoidCallback? onNext,
    required Widget body,
  }) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.all(20),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: bottomInset + 20),  // <— añade espacio extra cuando el teclado está abierto
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              margin: EdgeInsets.only(bottom: 20),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.2,
              decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: AssetImage('lib/assets/banner-add-mascota.jpg'),
                ),
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            body,
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Si no estamos en la última página, mostrar "Atrás"
                if (onBack != null && _currentPage != 8)
                  ElevatedButton(
                    onPressed: onBack,
                    child: Text(
                      'Atrás',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey, // Color actual del botón "Atrás"
                      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                if (onNext != null)
                  ElevatedButton(
                    onPressed: onNext,
                    child: Text(
                      'Siguiente',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // Color verde menta para el botón "Siguiente"
                      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
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
  // Método para asignar la imagen, ya sea seleccionada o generada
  Future<void> _setMascotaImage(String mascotaId) async {
    if (_imagenMascota != null) {
      // Esperar a que la imagen sea generada antes de asignarla
      _imagenBase64= await StorageService.uploadPetPicture(mascotaId, _imagenMascota!);
    }
  }

  // Método para asignar la imagen, ya sea seleccionada o generada
  Future<void> _setProfileImage(String name) async {
    if (_imageFile == null && name.isNotEmpty) {
      // Esperar a que la imagen sea generada antes de asignarla
      _imageFile = await _generateImageFromInitial(name.substring(0, 1).toUpperCase());
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => _isLoading = true); // Activa loader

    try {
      final session = Provider.of<SessionProvider>(context, listen: false);
      final userId = session.user?.userId;

      if (userId == null) {
        throw Exception("No se encontró el ID del usuario autenticado.");
      }

      final Uuid uuid = Uuid();
      String mascotaId = uuid.v4();
      _peso = double.tryParse(_pesoSeleccionado) ?? 0.0;

      // **Calcular edad si se ingresó fecha de nacimiento**
      if (_fechaNacimiento.isNotEmpty) {
        _edad = calcularEdad(_fechaNacimiento);
      }

      // **Subir imagen de mascota si hay una seleccionada**
      if (_imagenMascota != null && _imagenBase64.isEmpty) {
        await _setMascotaImage(mascotaId);
      } else {
        _imageFile= await StorageService.setProfileImage(_nombreController.text);
        _imagenBase64 = await StorageService.uploadPetPicture(mascotaId, _imageFile!);
      }

      // **Si el usuario ingresó peso, guardarlo como subdocumento**
      late  List<PesoMascota>? peso= [];
      late PesoMascota  nuevoPeso;
      if (_peso > 0) {
        nuevoPeso = PesoMascota(
          pesoid: Utiles.getId(),
          fecha: DateTime.now(),
          peso: _peso,
          um: _unidadSeleccionada,
        );
        peso.add(nuevoPeso);
      }
      // **Crear la nueva mascota sin peso**
      Mascota mascotaNew = Mascota(
        mascotaid: mascotaId,
        nombre: _nombreController.text,
        especie: _tipoMascotaSeleccionado,
        raza: _raza,
        edad: _edad,
        genero: _sexo,
        color: _colorSeleccionado,
        tamano: '',
        peso: peso,
        personalidad: '',
        historialMedico: '',
        fechaNacimiento: _fechaNacimiento,
        fotos: _imagenBase64,
        isSelected: false,
        reservedTime: false,
      );

      final mascotaService = MascotaService();

      // **Guardar mascota en Firestore usando `MascotaService`**
      //await mascotaService.addMascota(userId, mascotaNew);

      // **Referencia en Firestore**
      // **Referencia en Firestore**
      DocumentReference mascotaRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('mascotas')
          .doc(mascotaId);

      // **Convertimos la mascota en JSON**
      Map<String, dynamic> mascotaData = mascotaNew.toJson();


// **Crear nueva mascota en Firestore (si no existe)** ✅
      await mascotaRef.set(mascotaData, SetOptions(merge: true));

      // **Actualizar en `SessionProvider` correctamente**
      //session.user?.mascotas?.removeWhere((m) => m.mascotaid == mascotaId);
      session.user?.mascotas?.add(mascotaNew);
      session.notifyListeners(); // 🔹 Notificar cambios

      // 🔹 **Forzar la recarga de mascotas desde Firebase**
      await session.updateMascotaSession(userId);

      // **Esperar la actualización antes de redirigir**
      Future.delayed(Duration(milliseconds: 500), () {
        Navigator.pushReplacementNamed(context, '/home_inicio');
      });

      // **Mostrar mensaje de éxito**
     /* Utiles.showConfirmationDialog(
        context: context,
        title: 'Registro exitoso',
        content: 'Mascota registrada exitosamente.',
        onConfirm: () {
          Navigator.pushReplacementNamed(context, '/home_inicio');
        },
      );*/
    } catch (e) {
      Utiles.showErrorDialog(
        context: context,
        title: 'Error',
        content: 'Ocurrió un error inesperado. Intente nuevamente.',
      );
    } finally {
      setState(() => _isLoading = false); // Desactiva loader
    }
  }

  // Método para generar una imagen con la inicial del nombre
  Future<File> _generateImageFromInitial(String initial) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = Colors.blue;

    final size = 100.0; // Tamaño de la imagen
    final textPainter = TextPainter(
      text: TextSpan(
        text: initial,
        style: TextStyle(fontSize: 40, color: Colors.white),
      ),
      textDirection: ui.TextDirection.ltr, // Usa la importación corregida
    );
    textPainter.layout();

    // Dibujar el fondo circular
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);

    // Dibujar la letra en el centro del círculo
    textPainter.paint(
        canvas,
        Offset(
          (size - textPainter.width) / 2,
          (size - textPainter.height) / 2,
        ));

    // Crear la imagen en memoria
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());

    // Convertir la imagen a bytes PNG
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    // Guardar la imagen en el sistema de archivos local
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$initial.png';
    final file = File(filePath);
    await file.writeAsBytes(buffer);

    return file; // Retornar el archivo generado
  }


}




