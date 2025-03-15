import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';


import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../class/SessionProvider.dart';


class PerfilActividadesScreen extends StatefulWidget {
  @override
  _PerfilActividadesScreenState createState() => _PerfilActividadesScreenState();
}

class _PerfilActividadesScreenState extends State<PerfilActividadesScreen> {
  final List<Map<String, dynamic>> _perfilesBase = [
    {'name': 'PROPIETARIO', 'image': 'lib/assets/paseador.png'},
    {'name': 'ESTILISTA', 'image': 'lib/assets/peluqueria.png'},
    {'name': 'VETERINARIO', 'image': 'lib/assets/iconos/veterinario.png'},
    {'name': 'TIENDA', 'image': 'lib/assets/tienda.png'},
    {'name': 'PASEADOR', 'image': 'lib/assets/paseador.png'},
    {'name': 'GUARDERIA', 'image': 'lib/assets/cuidador.png'},
    {'name': 'ALBERGUES', 'image': 'lib/assets/refugio-de-animales.png'},
    {'name': 'OTROS', 'image': 'lib/assets/otro.png'},
  ];

  final Map<String, List<Map<String, dynamic>>> _actividades = {
    'PROPIETARIO': [
      {'name': 'Perfil Mascota', 'image': 'lib/assets/inicio/calendario.png'},
      {'name': 'Calendario', 'image': 'lib/assets/inicio/calendario.png'},
      {'name': 'Pagos Online', 'image': 'lib/assets/iconos/tarjeta-de-credito.png'},
    ],
  };

  String? _perfilSeleccionado;
  Set<String> _actividadesSeleccionadas = {};
  bool _isLoading = false;
  Map<String, List<String>> _actividadesPersonalizadas = {};
  TextEditingController _actividadController = TextEditingController();

  TextEditingController _perfilController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  List<Map<String, dynamic>> _perfiles = [];

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedPerfiles = prefs.getStringList('perfiles');

    setState(() {
      _perfiles = List.from(_perfilesBase);
      if (savedPerfiles != null) {
        for (var perfil in savedPerfiles) {
          _perfiles.add({'name': perfil, 'image': 'lib/assets/iconos/custom.png'});
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Selecciona perfil y actividades', style: TextStyle(fontFamily: 'Poppins')),
        backgroundColor: const Color(0xFFA0E3A7),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildPerfilesSection(),
                  Divider(color: Colors.grey),
                  _buildActividadesSection(),
                ],
              ),
            ),
          ),
          _buildGuardarButton(),
        ],
      ),
    );
  }

  Widget _buildPerfilesSection() {
    return Container(
      padding: EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text('Perfiles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 5.0,
              mainAxisSpacing: 5.0,
            ),
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _perfiles.length,
            itemBuilder: (context, index) {
              final perfil = _perfiles[index];
              final isSelected = _perfilSeleccionado == perfil['name'];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _perfilSeleccionado = perfil['name'];
                    _actividadesSeleccionadas.clear();
                    _actividadesPersonalizadas[_perfilSeleccionado!] = _actividadesPersonalizadas[_perfilSeleccionado!] ?? [];
                  });


                  if (_perfilSeleccionado == "OTROS") {
                    _showAddProfileDialog();
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60.0,
                      height: 60.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? Colors.blueAccent.withOpacity(0.3) : Colors.white,
                        border: Border.all(color: Colors.orangeAccent),
                      ),
                      child: ClipOval(
                        child: Image.asset(perfil['image'] as String, fit: BoxFit.cover, width: 50.0, height: 50.0),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(perfil['name'] as String, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActividadesSection() {
    if (_perfilSeleccionado == null) {
      return Container(
        padding: EdgeInsets.all(16.0),
        child: Text('Seleccione un perfil para ver las actividades relacionadas.', style: TextStyle(fontSize: 16)),
      );
    }

    final actividades = _actividades[_perfilSeleccionado] ?? [];
    final actividadesPersonalizadas = _actividadesPersonalizadas[_perfilSeleccionado!] ?? [];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Actividades para $_perfilSeleccionado', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Spacer(),
              IconButton(
                icon: Icon(Icons.add_circle, color: Colors.green, size: 28),
                onPressed: _showAddActivityDialog,
              ),
            ],
          ),
          SizedBox(height: 4),

          actividades.isNotEmpty || actividadesPersonalizadas.isNotEmpty
              ? GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: 1.0,
            ),
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: actividades.length + actividadesPersonalizadas.length,
            itemBuilder: (context, index) {
              final actividad = index < actividades.length
                  ? actividades[index]
                  : {'name': actividadesPersonalizadas[index - actividades.length], 'image': 'lib/assets/iconos/custom.png'};

              final isSelected = _actividadesSeleccionadas.contains(actividad['name']);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _actividadesSeleccionadas.remove(actividad['name']);
                    } else {
                      _actividadesSeleccionadas.add(actividad['name']);
                    }
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(6.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: isSelected ? Colors.blueAccent : Colors.orangeAccent),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(actividad['name'], textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            },
          )
              : Text('No hay actividades disponibles para este perfil.'),
        ],
      ),
    );
  }

  void _showAddActivityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Agregar Actividad"),
        content: TextField(
          controller: _actividadController,
          decoration: InputDecoration(labelText: "Nombre de la actividad"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _actividadesPersonalizadas[_perfilSeleccionado!]?.add(_actividadController.text);
                _actividadController.clear();
              });
              Navigator.pop(context);
            },
            child: Text("Agregar"),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardarButton() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: _actividadesSeleccionadas.isNotEmpty ? _guardarActividades : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green, // Verde menta
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12), // ✅ Aumenta el tamaño
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isLoading  ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : const Text(
          'Guardar',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }


  Future<void> _showAddProfileDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Agregar nuevo perfil"),
          content: TextField(
            controller: _perfilController,
            decoration: InputDecoration(hintText: "Ingrese nombre del perfil"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _perfiles.add({'name': _perfilController.text, 'image': 'lib/assets/iconos/custom.png'});
                });
                Navigator.pop(context);
              },
              child: Text("Agregar"),
            ),
          ],
        );
      },
    );
  }


  Future<void> _guardarActividades() async {
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);

    // Verificar si el usuario está autenticado
    if (!sessionProvider.isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    if (_perfilSeleccionado == null || _actividadesSeleccionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seleccione un perfil y al menos una actividad antes de guardar.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String userId = sessionProvider.user?.userId ?? "desconocido"; // Obtener el ID del usuario
      bool yaRespondio = prefs.getBool('alreadySelected') ?? false;

      // ✅ Si ya respondió, lo redirige directamente sin seguir ejecutando más lógica
      if (yaRespondio) {
        _redirigirUsuario(sessionProvider.rolAcceso!);
        return;  // ✅ IMPORTANTE: Detener ejecución aquí
      }

      // ✅ Guardar en Firestore solo si aún no ha respondido
      CollectionReference actividadesRef = FirebaseFirestore.instance.collection('perfiles_actividades');

      // Fecha actual
      String fechaActual = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      // Construcción del documento a guardar
      Map<String, dynamic> data = {
        'usuario_id': userId,
        'perfil': _perfilSeleccionado,
        'actividades': _actividadesSeleccionadas.toList(),
        'actividades_personalizadas': _actividadesPersonalizadas[_perfilSeleccionado] ?? [],
        'fecha_creacion': fechaActual,
      };

      // Guardar en Firestore
      await actividadesRef.add(data);

      // Guardar en SharedPreferences que la encuesta fue completada
      await prefs.setBool('alreadySelected', true);

      // ✅ Mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Perfil y actividades guardadas exitosamente.')),
      );

      // ✅ Limpiar selección
      setState(() {
        _actividadesSeleccionadas.clear();
        _actividadesPersonalizadas[_perfilSeleccionado!] = [];
      });

      // ✅ Redirigir usuario según su rol
      _redirigirUsuario(sessionProvider.rolAcceso!);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar en Firebase: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

// ✅ Método auxiliar para la redirección del usuario
  void _redirigirUsuario(int rolAcceso) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (rolAcceso == 1) {
        Navigator.pushReplacementNamed(context, '/home_inicio');
      } else if (rolAcceso == 2) {
        Navigator.pushReplacementNamed(context, '/home_estilista');
      } else {
        Navigator.pushReplacementNamed(context, '/home_default'); // Pantalla por defecto
      }
    });
  }

}