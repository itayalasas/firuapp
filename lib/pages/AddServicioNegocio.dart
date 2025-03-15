import 'dart:convert';
import 'dart:io';

import 'package:PetCare/class/Negocio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';


import '../class/SessionProvider.dart';
import '../class/UserRoles.dart';
import 'Config.dart';
import 'Utiles.dart';

class AddServicioModal extends StatefulWidget {
  @override
  _AddServicioModalModalState createState() => _AddServicioModalModalState();
}

class _AddServicioModalModalState extends State<AddServicioModal> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late List<PerfilRoles> _services = [];
  PerfilRoles? _selectedService;

  List<Actividad> _actividadesNegocio = []; // 🔹 Lista de actividades del negocio
  List<Actividad> _selectedActividades = []; // 🔹 Lista de actividades seleccionadas

  @override
  void initState() {
    super.initState();
    final session = Provider.of<SessionProvider>(context, listen: false);

    _fetchRolesPerfiles();
  }

  // 🔹 Obtener los servicios desde Firestore
  Future<void> _fetchRolesPerfiles() async {
    try {
      setState(() => _isLoading = true);

      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('perfil_roles').get();

      List<PerfilRoles> roles = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return PerfilRoles.fromJson(data);
      }).toList();

      setState(() {
        _services = roles;
        _isLoading = false;
      });
    } catch (e) {
      print("❌ Error fetching roles from Firestore: $e");
      setState(() => _isLoading = false);
    }
  }

  // 🔹 Obtener actividades asociadas a un negocio
  Future<void> _fetchActividadesPorNegocio(int negocioId) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('negocios_actividades')
          .where('negocioId', isEqualTo: negocioId)
          .get();

      List<Actividad> actividades = querySnapshot.docs.map((doc) {
        return Actividad.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();

      setState(() {
        _actividadesNegocio = actividades;
        _selectedActividades.clear(); // Limpiar selección al cambiar negocio
      });
    } catch (e) {
      print("❌ Error al obtener actividades del negocio: $e");
    }
  }

  // 🔹 Guardar servicio y actividades en Firestore
  Future<void> _submitData() async {
    if (_selectedService == null) return;

    try {
      setState(() => _isLoading = true);

      final session = Provider.of<SessionProvider>(context, listen: false);
      final String negocioId = session.business!.id;
      final String negocioNombre = session.business!.name;

      // 🔹 Guardar servicio en Firestore
      Map<String, dynamic> negocioData = {
        'id': _selectedService!.id,
        'descripcion': _selectedService!.descripcion,
        'foto': _selectedService!.foto ?? '',
        'assigned_at': FieldValue.serverTimestamp(),
      };

      DocumentReference negocioRef = await FirebaseFirestore.instance
          .collection('businesses')
          .doc(negocioId)
          .collection('negocios')
          .add(negocioData);

      // 🔹 Guardar actividades seleccionadas dentro del negocio (id + descripcion)
      for (Actividad actividad in _selectedActividades) {
        await negocioRef.collection('actividades').add({
          'id': actividad.id,
          'actividad': actividad.actividad, // 🔹 Guardar la descripción también
          'status': 'Disponible',
        });
      }

      setState(() => _isLoading = false);

      Utiles.showConfirmationDialog(
        context: context,
        title: 'Registro exitoso',
        content: 'Se registró un nuevo servicio al negocio $negocioNombre.',
        onConfirm: () {
          Navigator.of(context).pop();
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      Utiles.showErrorDialog(
        context: context,
        title: 'Error',
        content: "Ocurrió un error al guardar el negocio. Intente más tarde.",
      );
      print("❌ Error al guardar negocio en Firestore: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<SessionProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Registrar nuevo servicio',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        backgroundColor: const Color(0xFFA0E3A7),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : _services.isEmpty
                ? Center(
              child: Text(
                'No hay servicios disponibles.',
                style: TextStyle(color: Colors.grey),
              ),
            )
                : DropdownButtonFormField<PerfilRoles>(
              value: _selectedService,
              items: _services.map((PerfilRoles service) {
                return DropdownMenuItem<PerfilRoles>(
                  value: service,
                  child: Row(
                    children: [
                      Icon(Icons.work, color: const Color(0xFFA0E3A7)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          service.descripcion,
                          style: TextStyle(fontFamily: 'Poppins'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (PerfilRoles? value) {
                setState(() {
                  _selectedService = value;
                  _fetchActividadesPorNegocio(_selectedService!.id);
                });
              },
              decoration: InputDecoration(
                labelText: 'Servicios',
                labelStyle: TextStyle(fontFamily: 'Poppins'),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              isExpanded: true,
            ),
            SizedBox(height: 20),

            // 🔹 Lista de actividades con CheckBox
            if (_actividadesNegocio.isNotEmpty) ...[
              Text("Selecciona actividades:", style: TextStyle(fontFamily: 'Poppins', fontSize: 16)),
              SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _actividadesNegocio.length,
                  itemBuilder: (context, index) {
                    final actividad = _actividadesNegocio[index];
                    return CheckboxListTile(
                      title: Text(actividad.actividad),
                      value: _selectedActividades.contains(actividad),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedActividades.add(actividad);
                          } else {
                            _selectedActividades.remove(actividad);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ],

            SizedBox(height: 20),

            _isLoading
                ? Center(child: CircularProgressIndicator())
                : SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: Text(
                  'Guardar Servicio',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.white),
                ),
                onPressed: _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

