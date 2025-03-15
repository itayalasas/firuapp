import 'dart:convert';
import 'dart:io';

import 'package:PetCare/class/Negocio.dart';
import 'package:PetCare/class/ServiceNegocio.dart';
import 'package:PetCare/class/UserRoles.dart';
import 'package:PetCare/pages/AdoptionManagement.dart';
import 'package:PetCare/pages/CalendarManagement.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';


import 'package:provider/provider.dart';



import '../class/SessionProvider.dart';
import 'AddServicioNegocio.dart';


class ManagementPage extends StatefulWidget {
  @override
  _ManagementPageState createState() => _ManagementPageState();
}

class _ManagementPageState extends State<ManagementPage> {
  final List<String> _services = []; // List to store services fetched from the API
  String? _selectedService; // Selected service from the dropdown
  bool _isLoadingServices = true; // Indicates if services are being loaded
  Negocio? selectServiceNegocio;


  @override
  void initState() {
    super.initState();
    final session = Provider.of<SessionProvider>(context, listen: false);

  }



  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);

    // Lista de negocios, si no hay negocios, quedará vacía
    final List<Negocio> negocios = sessionProvider.business?.negocios ?? [];

    // Asegurarse de que el color de la barra de estado no sea cubierto
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
              'Gestión de negocio',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 20),
            ),
            backgroundColor: const Color(0xFFA0E3A7),
            elevation: 0,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Si hay negocios, mostrar el header, si no, mensaje de selección
            negocios.isNotEmpty
                ? _buildHeader(negocios)
                : Center(
              child: Text(
                "Seleccione un negocio",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            ),

            SizedBox(height: 20),

            _buildActionButtons(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF67C8F1),
        onPressed: () => _showAddServicioModal(context),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }


  /// 🔹 Cabecera que muestra el negocio seleccionado
  Widget _buildHeader(List<Negocio> negocios) {
    // Si `selectedNegocio` es null, asignar el primer negocio de la lista
    selectServiceNegocio ??= negocios.isNotEmpty ? negocios.first : null;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: selectServiceNegocio != null && selectServiceNegocio!.foto.isNotEmpty
                      ? NetworkImage(selectServiceNegocio!.foto) as ImageProvider<Object>
                      : null,
                  backgroundColor: Colors.white,
                ),
                if (selectServiceNegocio == null)
                  Positioned.fill(
                    child: Icon(
                      Icons.business,
                      color: Colors.grey[400],
                      size: 50,
                    ),
                  ),
              ],
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectServiceNegocio?.descripcion ?? "Seleccione un negocio",
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 18),
                  ),
                ],
              ),
            ),
            SizedBox(width: 10),
            IconButton(
              icon: Icon(Icons.select_all, color: Colors.green[400], size: 40),
              onPressed: () => _selectOtherBusiness(negocios),
            ),
          ],
        ),
        SizedBox(height: 20),
      ],
    );
  }


/// 🔹 Método para seleccionar otro negocio y actualizar la UI
void _selectOtherBusiness(List<Negocio> negocios) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return ListView.builder(
        itemCount: negocios.length,
        itemBuilder: (context, index) {
          final negocio = negocios[index];

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: negocio.foto.isNotEmpty
                  ? NetworkImage(negocio.foto) as ImageProvider<Object>
                  : null,
              backgroundColor: Colors.grey[300],
              child: negocio.foto.isEmpty
                  ? Icon(Icons.business, color: Colors.white)
                  : null,
            ),
            title: Text(negocio.descripcion),
            onTap: () {
              setState(() {
                selectServiceNegocio = negocio; // Actualizar el negocio seleccionado
              });
              Navigator.pop(context);
            },
          );
        },
      );
    },
  );
}
  // Función para cambiar la mascota seleccionada
  void _selectOtherPet(List<Negocio> servicios) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return ListView.builder(
            itemCount: servicios.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: servicios[index].foto.startsWith('http')
                      ? NetworkImage(servicios[index].foto) as ImageProvider<Object>
                      : AssetImage('lib/assets/sin_imagen.png') as ImageProvider<Object>,
                ),
                title: Text(servicios[index].descripcion),
                onTap: () {
                  setState(() {
                    selectServiceNegocio = servicios[index];
                    //profileCompletion = _calculateProfileCompletion(selectedMascota!);
                  });
                  Navigator.pop(context);
                },
              );
            },
          );
        });
  }



  // Botones de acción que dependen del servicio seleccionada
  Widget _buildActionButtons() {
    bool areButtonsEnabled = selectServiceNegocio != null;

    // 🔹 Mapeo de actividades a botones (ajustado a `Widget`)
    Map<String, Widget> actividadIconos = {
      "Agenda": Icon(Icons.calendar_today, size: 30, color: Colors.blue),
      "Examenes": Icon(Icons.medical_services, size: 40, color: Colors.red),
      "Desparasitación": Icon(Icons.local_hospital, size: 35, color: Colors.green),
      "Perfil": Icon(Icons.person, size: 30, color: Colors.purple),
      "Adopciones": Icon(Icons.pets, size: 30, color: Colors.orange),
    };

    // 🔹 Obtener las actividades del negocio seleccionado
    List<Widget> buttons = [];
    if (selectServiceNegocio != null) {
      for (Actividad actividad in selectServiceNegocio!.actividades) {
        if (actividadIconos.containsKey(actividad.actividad)) {
          buttons.add(_buildActionButton(
            actividadIconos[actividad.actividad]!, // 🔹 Pasamos `Widget` en lugar de `IconData`
            actividad.actividad,
            areButtonsEnabled,
          ));
        }
      }
    }

    return Expanded(
      child: SingleChildScrollView(
        child: GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          childAspectRatio: 1.2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: buttons,
        ),
      ),
    );
  }



// Función para construir los botones con borde azul y fondo blanco
  // Función para construir los botones con borde azul y fondo blanco
  Widget _buildActionButton(Widget icon, String label, bool isEnabled) {
    return OutlinedButton(
      onPressed: isEnabled
          ? () {
        if (label == 'Agenda') {
          showCalendarManagementDialog(context);
        } else if (label == 'Adopciones') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AdoptionManagementScreen()),
          );
        } else if (label == 'Recuerdos') {
          // Abrir la pantalla de "Recuerdos"
        }
      }
          : null, // Si el botón está deshabilitado, no realiza ninguna acción
      style: OutlinedButton.styleFrom(
        foregroundColor: isEnabled ? Colors.black : Colors.grey,
        side: BorderSide(
          color: Color(0xFF67C8F1), // Borde azul
          width: 1.5, // Ancho del borde
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15), // Bordes suaves
        ),
        backgroundColor: Colors.white, // Fondo blanco
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 🔹 Se usa `icon` directamente (ya es un `Widget`)
          IconTheme(
            data: IconThemeData(
              color: isEnabled ? Color(0xFF0288D1) : Colors.grey, // Azul si está habilitado, gris si no
              size: 30,
            ),
            child: icon, // Se mantiene el icono original con su color y tamaño
          ),
          SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5, // Reducir el tamaño del texto
              color: isEnabled ? Colors.black : Colors.grey, // Texto negro si está habilitado, gris si está deshabilitado
            ),
            maxLines: 2, // Permitir hasta 2 líneas de texto
          ),
        ],
      ),
    );
  }


  void _showAddServicioModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return AddServicioModal();
      },
    );
  }


  void showCalendarManagementDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite ocupar el espacio necesario
      barrierColor: Colors.transparent, // ✅ Elimina el fondo negro
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return CalendarManagementBottomSheet();
      },
    );
  }
}