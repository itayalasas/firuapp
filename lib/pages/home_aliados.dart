import 'dart:convert';
import 'dart:io';


import 'package:PetCare/pages/CalendarManagement.dart';
import 'package:PetCare/pages/ManagementPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';

import '../class/ActividadEstilista.dart';
import '../class/CalendarioDay.dart';
import '../class/CalendarioWork.dart';
import '../class/Negocio.dart';
import '../class/ServiceNegocio.dart';
import '../class/SessionProvider.dart';
import '../class/User.dart';
import '../class/UserRoles.dart';
import '../services/BusinessService.dart';
import 'Config.dart';
import 'Utiles.dart';
import 'negocio_page.dart';
import 'package:fl_chart/fl_chart.dart';

class HomeEstilista extends StatefulWidget {
  final int role;

  const HomeEstilista({required this.role});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<HomeEstilista> {
  int _currentIndex = 0;
  late String _userId;
  late User _user;
  final List<Widget> _children = [];

  int _selectedIndex = 0;
  late FirebaseMessaging messaging;

  @override
  void initState() {
    super.initState();

    // 🟢 Inicializar la lista de páginas ANTES de acceder a sus índices
    _children.addAll([
      HomePageEstilista(),
      ManagementPage(),
      ChatPage(),
      ProfilePage()
    ]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final session = Provider.of<SessionProvider>(context, listen: false);
        _userId = session.user!.userId;
        _user = session.user!;
        _loadBusiness();
        session.notifyListeners();
      }



    });
  }

  void _loadBusiness() {
    final businessService = BusinessService();
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    final userId = sessionProvider.user!.userId;

    businessService.getBusinessStreamByUserId(userId).listen((business) {
      sessionProvider.business = business;

      if (business != null) {
        print("📢 Empresa actualizada: ${business.name}");
      } else {
        print("❌ No se encontró empresa para este usuario.");
      }
    });
  }



  @override
  void dispose() {
    super.dispose();
  }

  void onTabTapped(int index) {
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);

    setState(() {
      _currentIndex = index;
    });

    if (index == 1 && sessionProvider.business == null) {
      Future.delayed(Duration.zero, () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Negocio no encontrado"),
              content: Text("Debes crear un negocio para acceder a esta sección."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _currentIndex = 2;
                    });
                  },
                  child: Text("Ir a Perfil"),
                ),
              ],
            );
          },
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: (_children.isNotEmpty && _currentIndex < _children.length)
          ? _children[_currentIndex]
          : Center(child: CircularProgressIndicator()),

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Gestión',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        currentIndex: _currentIndex,
        selectedItemColor: Colors.green[400],
        unselectedItemColor: Colors.black,
        elevation: 10,
        onTap: onTabTapped,
      ),
    );
  }
}


class HomePageEstilista extends StatefulWidget {
  @override
  _HomePageEstilistaState createState() => _HomePageEstilistaState();
}

class _HomePageEstilistaState extends State<HomePageEstilista> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard', style: TextStyle(fontFamily: 'Poppins')),
        backgroundColor: Color(0xFFA0E3A7),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Muestra carga mientras se obtienen datos
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildSalesStatsCard(),
            SizedBox(height: 16),
            _buildTurnStatsCard(),
            SizedBox(height: 16),
            _buildReservationPeakGraph(),
            SizedBox(height: 16),
            _buildEarningsGraph(),
            SizedBox(height: 16),
            _buildActivityTurnStatsGraph(),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesStatsCard() {
    final int totalSales = 120;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estadísticas de Ventas Generadas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              '$totalSales ventas',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTurnStatsCard() {
    final int reservedTurns = 80;
    final int canceledTurns = 20;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Turnos por Horarios',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Reservados: $reservedTurns',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              'Cancelados: $canceledTurns',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationPeakGraph() {
    List<FlSpot> dataPoints = [
      FlSpot(0, 5),
      FlSpot(1, 7),
      FlSpot(2, 3),
      FlSpot(3, 8),
      FlSpot(4, 5),
      FlSpot(5, 10),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pico de Reservas por Actividad',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: dataPoints.isNotEmpty
                  ? LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: dataPoints,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 4,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.3),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                  ),
                ),
              )
                  : Center(child: Text("No hay datos disponibles")),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsGraph() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total de Ganancias por Semana',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [BarChartRodData(toY: 1500, color: Colors.green)],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [BarChartRodData(toY: 2000, color: Colors.green)],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [BarChartRodData(toY: 1800, color: Colors.green)],
                    ),
                    BarChartGroupData(
                      x: 3,
                      barRods: [BarChartRodData(toY: 2200, color: Colors.green)],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTurnStatsGraph() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estadísticas de Turnos por Actividad',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(value: 40, title: 'Corte', color: Colors.blue),
                    PieChartSectionData(value: 30, title: 'Color', color: Colors.orange),
                    PieChartSectionData(value: 20, title: 'Manicura', color: Colors.red),
                    PieChartSectionData(value: 10, title: 'Otros', color: Colors.green),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}





/*class HomePageEstilista extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight), // Tamaño del AppBar estándar
        child: SafeArea( // Asegura que el AppBar no cubra la barra de estado
          child: AppBar(
            title: Text(
              'Dashboard',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: const Color(0xFFA0E3A7), // Color verde menta de la marca
            elevation: 0,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Tarjeta de estadísticas de ventas
              _buildSalesStatsCard(),
              SizedBox(height: 16),

              // Tarjeta de estadísticas de turnos
              _buildTurnStatsCard(),
              SizedBox(height: 16),

              // Gráfico de picos de reservas
              _buildReservationPeakGraph(),
              SizedBox(height: 16),

              // Gráfico de ganancias
              _buildEarningsGraph(),
              SizedBox(height: 16),

              // Gráfico de estadísticas de turnos por actividad
              _buildActivityTurnStatsGraph(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalesStatsCard() {
    final int totalSales = 120;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estadísticas de Ventas Generadas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              '$totalSales ventas',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTurnStatsCard() {
    final int reservedTurns = 80;
    final int canceledTurns = 20;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Turnos por Horarios',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Reservados: $reservedTurns',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              'Cancelados: $canceledTurns',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationPeakGraph() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pico de Reservas por Actividad',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 200, // Ajusta la altura según sea necesario
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        FlSpot(0, 5),
                        FlSpot(1, 7),
                        FlSpot(2, 3),
                        FlSpot(3, 8),
                        FlSpot(4, 5),
                        FlSpot(5, 10),
                      ],
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 4,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.3),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsGraph() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total de Ganancias por Semana',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 200, // Ajusta la altura según sea necesario
              child: BarChart(
                BarChartData(
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [BarChartRodData(toY: 1500, color: Colors.green)],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [BarChartRodData(toY: 2000, color: Colors.green)],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [BarChartRodData(toY: 1800, color: Colors.green)],
                    ),
                    BarChartGroupData(
                      x: 3,
                      barRods: [BarChartRodData(toY: 2200, color: Colors.green)],
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTurnStatsGraph() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estadísticas de Turnos por Actividad',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            SizedBox(
              height: 200, // Ajusta la altura según sea necesario
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(value: 40, title: 'Corte', color: Colors.blue),
                    PieChartSectionData(value: 30, title: 'Color', color: Colors.orange),
                    PieChartSectionData(value: 20, title: 'Manicura', color: Colors.red),
                    PieChartSectionData(value: 10, title: 'Otros', color: Colors.green),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

*/






class ChatPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Chat',
        style: TextStyle(fontSize: 24.0),
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  @override
  _ProfileManagementPageState createState() => _ProfileManagementPageState();
}

class _ProfileManagementPageState extends State<ProfilePage> {
  final _picker = ImagePicker();
  File? _profileImage;
  bool _isEditing = false;

  // Controladores para las contraseñas
  final TextEditingController _currentPasswordController =
  TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {  // Verifica si el widget sigue montado antes de notificar cambios
        final session = Provider.of<SessionProvider>(context, listen: false);
        session.notifyListeners();
      }
    });

  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
      // Llama al método para actualizar la imagen en la base de datos
      await _updateProfileImage(pickedFile);
    }
  }

  Future<void> _updateProfileImage(XFile pickedFile) async {
    final session = Provider.of<SessionProvider>(context, listen: false);

    // Convert the image to base64
    final bytes = await pickedFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    // Call the API to update the image in the database
    final response = await http.post(
      Uri.parse('${Config.get('api_base_url')}/api/user/update-photo'),
      headers: {
        'Authorization': 'Bearer ${session.token!}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'photo': base64Image,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Foto de perfil actualizada exitosamente')),
      );
      // Update the photo in the session
      //session.updateUserPhoto(base64Image);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar la foto de perfil')),
      );
    }
  }

  void _showImageSourceDialog() {
    final session = Provider.of<SessionProvider>(context, listen: false);

    // Check if the platform is "manual"
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Profile Picture'),
          actions: [
            TextButton(
              onPressed: () {
                _pickImage(ImageSource.camera);
                Navigator.of(context).pop();
              },
              child: Text('Take a Photo'),
            ),
            TextButton(
              onPressed: () {
                _pickImage(ImageSource.gallery);
                Navigator.of(context).pop();
              },
              child: Text('Choose from Gallery'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );

  }


  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    final user = sessionProvider.user; // Obtener el usuario logueado

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight), // Tamaño del AppBar estándar
        child: SafeArea( // Asegura que el AppBar no cubra la barra de estado
          child: AppBar(
            title: Text(
              'Perfil',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: const Color(0xFFA0E3A7), // Color verde menta de la marca
            elevation: 0,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: user?.photo != null
                          ? (user!.photo.startsWith('http')
                          ? NetworkImage(user.photo) // Cargar imagen desde URL
                          : MemoryImage(base64Decode(user.photo)) // Opción para manejar base64, en caso de ser necesario
                      ) as ImageProvider
                          : null,
                      child: user?.photo == null
                          ? Icon(Icons.person, size: 60) // Icono de persona si no hay imagen
                          : null,

                    ),

                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton(
                        icon: Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: _showImageSourceDialog,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Divider(height: 1, color: Colors.grey),

                ListTile(
                  title: Text(
                    'Negocio',
                    style: TextStyle(
                      color: sessionProvider.business != null
                          ? Colors.grey // Disabled appearance
                          : Colors.black, // Enabled appearance
                    ),
                  ),
                  leading: Icon(
                    Icons.business,
                    color: sessionProvider.business != null
                        ? Colors.grey // Disabled appearance
                        : Colors.blue, // Enabled appearance
                  ),
                  enabled: sessionProvider.business == null, // Disable interaction
                  onTap: sessionProvider.business == null
                      ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RegisterBusinessPage(),
                      ),
                    );
                  }
                      : null, // Do nothing if disabled
                ),

                ListTile(
                  title: Text('Horario de trabajo'),
                  leading: Icon(Icons.calendar_today, color: Colors.blue),
                  onTap: () {
                    showCalendarManagementDialog(context);
                  },
                ),

                Divider(height: 1, color: Colors.grey),

                ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Editar Perfil'),
                  onTap: () {
                    Navigator.pushNamed(context, '/editProfile');
                  },
                ),

                ListTile(
                  leading: Icon(Icons.add_box_outlined),
                  title: Text('Nuevo perfil'),
                  onTap: () {
                    _showAssignRoleModal(context, sessionProvider.user!.userId);

                  },
                ),

                ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Cerrar Sesión'),
                  onTap: () {
                    // Logout and redirect to login
                    Provider.of<SessionProvider>(context, listen: false).signOut(context);
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  void _showAssignRoleModal(BuildContext context, String userId) {
    String? selectedRole;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('user_perfil').get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final rolesData = snapshot.data!.docs
                    .map((doc) => {
                  'id': doc['id'],
                  'perfil': doc['perfil'],
                })
                    .toList();

                // 🔹 Obtener los perfiles asignados del `SessionProvider`
                final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
                final assignedRoles = sessionProvider.perfil;

                // 🔹 Filtrar roles que ya tiene el usuario
                List<Map<String, dynamic>> availableRoles = rolesData.map((role) {
                  bool isAssigned = assignedRoles.any((assignedRole) => assignedRole.id == role['id']);
                  return {
                    'id': role['id'],
                    'perfil': role['perfil'],
                    'isAssigned': isAssigned,
                  };
                }).toList();

                return Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 🔹 Encabezado
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFA0E3A7),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                          ),
                          padding: EdgeInsets.all(15),
                          child: Center(
                            child: Text(
                              "Selecciona un perfil",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),

                        // 🔹 Selector de Perfil (Dropdown)
                        Padding(
                          padding: EdgeInsets.all(15),
                          child: DropdownButtonFormField<int>(
                            decoration: InputDecoration(
                              labelText: "Perfil",
                              border: OutlineInputBorder(),
                            ),
                            value: selectedRole != null ? int.tryParse(selectedRole!) : null,
                            items: availableRoles.map<DropdownMenuItem<int>>((role) {
                              return DropdownMenuItem<int>(
                                value: role['id'],
                                enabled: !role['isAssigned'], // 🔹 Deshabilitar si ya está asignado
                                child: Text(
                                  role['perfil'],
                                  style: TextStyle(
                                    color: role['isAssigned'] ? Colors.grey : Colors.black,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (int? value) {
                              setState(() {
                                selectedRole = value.toString();
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Por favor selecciona un perfil';
                              }
                              return null;
                            },
                          ),
                        ),

                        // 🔹 Botones de acción
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // 🔹 Botón Cancelar
                              TextButton(
                                child: Text(
                                  "Cancelar",
                                  style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.red),
                                ),
                                onPressed: () {
                                  Navigator.of(dialogContext, rootNavigator: true).pop();
                                },
                              ),

                              // 🔹 Botón Guardar con loader
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () async {
                                  if (selectedRole != null) {
                                    bool alreadyAssigned = assignedRoles.any((role) => role.id == int.parse(selectedRole!));

                                    if (alreadyAssigned) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text("Este perfil ya está asignado."),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                      return;
                                    }

                                    Navigator.of(dialogContext, rootNavigator: true).pop();

                                    // 🔹 Mostrar loader
                                    BuildContext? loaderContext;
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (BuildContext loadingContext) {
                                        loaderContext = loadingContext;
                                        return Dialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                          child: Padding(
                                            padding: EdgeInsets.all(20),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                CircularProgressIndicator(),
                                                SizedBox(height: 20),
                                                Text(
                                                  "Asignando perfil...",
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 16,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );

                                    try {
                                      // 🔹 Guardar el nuevo perfil en Firestore
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(userId)
                                          .collection('roles')
                                          .add({
                                        'roles': {
                                          'id': int.parse(selectedRole!),
                                          'perfil': availableRoles
                                              .firstWhere((role) => role['id'] == int.parse(selectedRole!))['perfil'],
                                        },
                                        'assigned_at': Timestamp.now(),
                                      });

                                      // 🔹 Actualizar la lista de perfiles en SessionProvider
                                      List<Perfil> updatedProfiles = [
                                        ...sessionProvider.perfil,
                                        Perfil(
                                          id: int.parse(selectedRole!),
                                          perfil: availableRoles
                                              .firstWhere((role) => role['id'] == int.parse(selectedRole!))['perfil'],
                                        ),
                                      ];
                                      sessionProvider.setUserPerfil(updatedProfiles);

                                      // 🔹 Cerrar loader correctamente
                                      if (loaderContext?.mounted ?? false) {
                                        Navigator.of(loaderContext!, rootNavigator: true).pop();
                                      }

                                      // ✅ **Notificar a la UI**
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text("Perfil asignado correctamente."),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (loaderContext?.mounted ?? false) {
                                        Navigator.of(loaderContext!, rootNavigator: true).pop();
                                      }

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text("Error al asignar perfil."),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text("Por favor selecciona un perfil."),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Text(
                                  "Guardar",
                                  style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.white),
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

