import 'dart:async';
import 'dart:convert';
import 'package:PetCare/class/extensions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../class/ActividadEstilista.dart';
import '../class/ActividadNegocio.dart';
import '../class/CalendarioDay.dart';
import '../class/CalendarioWork.dart';
import '../class/Mascota.dart';
import '../class/SessionProvider.dart';
import '../class/TimeSlot.dart';
import '../class/User.dart';
import 'Config.dart';
import 'Utiles.dart';
import '../class/Negocio.dart';
import 'package:http/http.dart' as http;
import 'home_aliados.dart';
import 'package:url_launcher/url_launcher.dart';

import 'home_inicial.dart';


class CalendarPageBusinessAll extends StatefulWidget {
  final ActivityBussines? service;
  final User user;
  final Mascota mascota;
  final Business business;
  CalendarPageBusinessAll({required this.user,required this.mascota, required this.business,  this.service});


  @override
  BusinessCalendarPage createState() => BusinessCalendarPage();
}

class BusinessCalendarPage extends State<CalendarPageBusinessAll> {
  late Future<List<Activity>> _activitiesFuture;
  late Map<DateTime, List<Activity>> _events={};
  late Set<int> _workableDays={};// Días de la semana habilitados
  late List<Calendariowork> _workingHours; // Horarios de trabajo
  DateTime _focusedDay = DateTime.now();
  //DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  bool _isLoading = false;
  late List<Calendarioday> _calendarDays= []; // Días de trabajo y horarios
  late List<ActivityBussines> _activityBussines;
  late StreamSubscription _sub;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _events = {};
    final session = Provider.of<SessionProvider>(context, listen: false);

    if (context.mounted) {
      final session = Provider.of<SessionProvider>(context, listen: false);
      session.notifyListeners();
    }
    String? token =  session.token;
    _fetchActivitiesAndInitializeCalendar(widget.business.userid, token!);
    _fetchActivitiesBusiness( widget.business.id,token);



  }



  void _handleIncomingLink(Uri uri) {
    // Obtener el estado de la transacción de la URL
    final String path = uri.host;

    if (path.contains('success')) {
      //Actualizar el estado de la reserva y registrar los datos de la transaccion
      // Redirige a la página de éxito
      Utiles.showConfirmationDialog(context:context, title:'Pago exitoso', content:'Su pago quedo registrado.',onConfirm: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomePageInicio()),
        );

      });


    } else if (path.contains('failure')) {
      // Redirige a la página de fallo
      /* Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FailureScreen()),
          );*/
      Utiles.showErrorDialog(context:context, title:'Error', content: "No se pudo procesar el pago." );

    } else if (path.contains('pending')) {
      // Redirige a la página de pendiente
      /*Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PendingScreen()),
          );*/
      Utiles.showErrorDialog(context:context, title:'Error', content: "No se pudo procesar el pago." );

    }
  }

  Future<void> _fetchActivitiesAndInitializeCalendar(String userid, String token) async {
    try {
      // Obtén las actividades y datos de calendario de la API
      List<Activity> activities = await fetchActivities(userid, token); // Reemplaza con valores reales
      List<Calendarioday> calendarDays = await fetchCalendarDays(userid, token); // Implementa este método para obtener los días laborables
      // _workingHours = await fetchWorkingHours(); // Implementa este método para obtener los horarios de trabajo
      Map<DateTime, List<Activity>> groupedEvents={};
      // Agrupa las actividades por fecha
      if(activities.isNotEmpty)
        groupedEvents = _groupActivitiesByDate(activities);

      // Obtén los días laborables
      _workableDays = _getWorkableDays(calendarDays);
      _calendarDays = calendarDays;

      setState(() {
        _events = groupedEvents;
      });
    } catch (e) {
      // Manejo de errores
      print('Error fetching activities: $e');
    }
  }


  Future<void> _fetchActivitiesBusiness(String negocioId, String token) async {
    final baseUrl = Config.get('api_base_url');
    final url = Uri.parse('$baseUrl/api/businesses/list-activity-businesses');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json; charset=utf-8'
    };
    // Agrega los parámetros a la URL
    final params = {
      'negocioId': negocioId
    };

    // Construye la URL con los parámetros
    // Construye la URL con los parámetros
    final uri = url.scheme == 'https'
        ? Uri.https(url.authority, url.path, params)
        : Uri.http(url.authority, url.path, params);

    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      _activityBussines= data.map((item) => ActivityBussines.fromJson(item)).toList();


    }else if (response.statusCode == 204) {
      Utiles.showErrorDialogBoton(context:context, title:'Notificación', content:'El negocio seleccionado ('+widget.business.name+') no tiene eventos registrados. Seleccione otro.',onConfirm: () {
       /* Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ManagementPage()),
        );*/
      });
      throw Exception('Failed to load calendar days');
    } else {
      throw Exception('Failed to load calendar days');
    }

  }



  Future<List<Calendarioday>> fetchCalendarDays(String userId, String token) async {


    final baseUrl = Config.get('api_base_url');
    final url = Uri.parse('$baseUrl/api/parameters/calendario-word-user');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json; charset=utf-8'
    };
    // Agrega los parámetros a la URL
    final params = {
      'userid': userId
    };

    // Construye la URL con los parámetros
    final uri = url.scheme == 'https'
        ? Uri.https(url.authority, url.path, params)
        : Uri.http(url.authority, url.path, params);
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((item) => Calendarioday.fromJson(item)).toList();


    }else if (response.statusCode == 204) {
      Utiles.showErrorDialogBoton(context:context, title:'Notificación', content:'No ha definido un calendario. Registre uno a continuación.',onConfirm: () {
        /*Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ManagementPage()),
        );*/
      });
      throw Exception('Failed to load calendar days');
    } else {
      throw Exception('Failed to load calendar days');
    }


  }

  Set<int> _getWorkableDays(List<Calendarioday> days) {
    final workableDays = <int>{};
    for (var day in days) {
      if (day.check) {
        final dayOfWeek = _getDayOfWeekFromString(day.day);
        if (dayOfWeek != null) {
          workableDays.add(dayOfWeek);
        }
      }
    }
    return workableDays;
  }

  int? _getDayOfWeekFromString(String dayString) {
    switch (dayString.toLowerCase()) {
      case 'lun':
        return DateTime.monday;
      case 'mar':
        return DateTime.tuesday;
      case 'mie':
        return DateTime.wednesday;
      case 'jue':
        return DateTime.thursday;
      case 'vie':
        return DateTime.friday;
      case 'sab':
        return DateTime.saturday;
      case 'dom':
        return DateTime.sunday;
      default:
        return null;
    }
  }

  Map<DateTime, List<Activity>> _groupActivitiesByDate(List<Activity> activities) {
    Map<DateTime, List<Activity>> data = {};
    for (var activity in activities) {
      final date = DateTime.parse(activity.fecha); // Asegúrate de que `activity.date` esté en formato compatible
      if (data[activity.fecha] == null) data[date] = [];
      data[date]!.add(activity);
    }
    return data;
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  List<Activity> _getEventsForDay(DateTime day) {
    return _events[_normalizeDate(day)] ?? [];
  }

  bool _isDayEnabled(DateTime day) {
    return _workableDays.contains(day.weekday);
  }

  Future<List<Activity>> fetchActivities(String userId, String token) async {
    final baseUrl = Config.get('api_base_url');
    final url = Uri.parse('$baseUrl/api/activity/activitys?id=$userId&status=Aprobada');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token', // Reemplaza 'tu_token_aqui' con tu token real
      'Content-Type': 'application/json; charset=utf-8', // Ejemplo de otro encabezado opcional
    },);

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Activity.fromJson(json)).toList();
    }else if (response.statusCode == 204) {
      Future<List<Activity>> activitiesFuture = Future.value([]);
      return  activitiesFuture;
    } else if (response.statusCode == 401) {
     Utiles.showErrorDialogUNAUTHORIZED(context: context, title: "Sessión", content: "Debe autenticarse.");
     throw Exception('Failed to load activities');
    }else {
      throw Exception('Failed to load activities');
    }
  }

  // Obtener horarios de trabajo para el día seleccionado
  List<TimeOfDay> _getWorkingHoursForSelectedDay() {
    try {
      final calendarDay = _calendarDays.firstWhere(
            (cDay) => _getDayOfWeekFromString(cDay.day) == _selectedDay.weekday,
      );
      final startTimeParts = calendarDay.calendario.startTime.split(':');
      final endTimeParts = calendarDay.calendario.endTime.split(':');
      final startHour = int.parse(startTimeParts[0]);
      final startMinute = int.parse(startTimeParts[1]);
      final endHour = int.parse(endTimeParts[0]);
      final endMinute = int.parse(endTimeParts[1]);

      List<TimeOfDay> workingHours = [];

      int currentHour = startHour;
      while (currentHour < endHour) {
        workingHours.add(TimeOfDay(hour: currentHour, minute: 0));
        currentHour++;
      }

      return workingHours;
    } catch (e) {
      print('Error getting working hours: $e');
      return [];
    }
  }

// Calcular turnos disponibles para una hora específica, considerando la duración del servicio
  int _getAvailableSlotsForHour(DateTime selectedDay, TimeOfDay startHour) {
   if (widget.service == null || widget.service!.turnos == null) return 0;

    final serviceDuration = widget.service!.tiempo; // duración del servicio en minutos
    final hoursNeeded = (serviceDuration / 60).ceil(); // número de horas que ocupa la actividad

    // Lista para almacenar la disponibilidad por hora
    List<int> availableSlotsList = [];

    for (int i = 0; i < hoursNeeded; i++) {
      final currentHour = startHour.hour + i;
      if (currentHour >= 24) {
        return 0; // Excede el día
      }

      final hourToCheck = TimeOfDay(hour: currentHour, minute: 0);
      final hourStart = DateTime(
        selectedDay.year, selectedDay.month, selectedDay.day,
        hourToCheck.hour, hourToCheck.minute,
      );
      final hourEnd = hourStart.add(Duration(hours: 1));

      // Contar actividades que se superponen con esta hora para el servicio seleccionado
      final overlappingActivities = _getEventsForDay(selectedDay).where((activity) {
        //if (activity.actividadid != widget.) return false;

        final activityStart = DateTime(
          selectedDay.year, selectedDay.month, selectedDay.day,
          int.parse(activity.startime.split(':')[0]),
          int.parse(activity.startime.split(':')[1]),
        );
        final activityEnd = DateTime(
          selectedDay.year, selectedDay.month, selectedDay.day,
          int.parse(activity.endtime.split(':')[0]),
          int.parse(activity.endtime.split(':')[1]),
        );

        // Verificar si la actividad se superpone con el intervalo actual
        return activityStart.isBefore(hourEnd) && activityEnd.isAfter(hourStart);
      }).length;

      // Calcular los slots disponibles para esta hora
      final int turno = widget.service!.turnos!;
      final availableSlots = subtract(turno , overlappingActivities) ;
      availableSlotsList.add(availableSlots);
    }

    // El número de turnos disponibles es el mínimo de los turnos disponibles en todas las horas necesarias
    return availableSlotsList.isNotEmpty ? availableSlotsList.reduce((a, b) => a < b ? a : b) : 0;
  }
  int subtract(int a, int b) {
    return a - b;
  }
  // Mostrar la interfaz para reservar un turno
  Future<void> _reserveTimeSlot(DateTime selectedDay, TimeOfDay selectedStartTime) async {
    if (widget.service == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Servicio no seleccionado')),
      );
      return;
    }

    final selectedStartDateTime = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
      selectedStartTime.hour,
      selectedStartTime.minute,
    );

    final selectedEndDateTime = selectedStartDateTime.add(Duration(minutes: widget.service!.tiempo));

    // Verificar si hay conflictos con actividades existentes
    bool isConflicting = _getEventsForDay(selectedDay).any((event) {
      if (event.actividadid != widget.service!.id) return false;

      final activityStartParts = event.startime.split(':');
      final activityEndParts = event.endtime.split(':');

      final activityStart = DateTime(
        selectedDay.year,
        selectedDay.month,
        selectedDay.day,
        int.parse(event.startime.split(':')[0]),
        int.parse(event.startime.split(':')[1]),
      );
      final activityEnd = DateTime(
        selectedDay.year,
        selectedDay.month,
        selectedDay.day,
        int.parse(event.endtime.split(':')[0]),
        int.parse(event.endtime.split(':')[1]),
      );

      return selectedStartDateTime.isBefore(activityEnd) && selectedEndDateTime.isAfter(activityStart);
    });

    if (isConflicting) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('El intervalo seleccionado se superpone con una actividad existente')),
      );
      return;
    }

    // Mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirmar Reserva'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Actividad: ${widget.service!.actividad}'),
              Text('Precio: \$${widget.service!.precio.toStringAsFixed(2)}'),
              Text('Hora de inicio: ${selectedStartTime.format(context)}'),
              Text('Hora de fin: ${TimeOfDay.fromDateTime(selectedEndDateTime).format(context)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // Proceder con la reserva
    try {
      setState(() {
        _isLoading = true;
      });

      // Llamar a la API para reservar el turno
     /* final newActivity = await _reserveTime(selectedDay, selectedStartDateTime, selectedEndDateTime);

      // Actualizar los eventos localmente
      setState(() {
        if (_events[_normalizeDate(selectedDay)] == null) {
          _events[_normalizeDate(selectedDay)] = [];
        }
        _events[_normalizeDate(selectedDay)]!.add(newActivity);
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reserva realizada con éxito')),
      );*/

      // Envía los datos como un Map al cerrar la pantalla
      Navigator.pop(context, {
        'selectedStartTime': selectedStartTime.format(context),
        'selectedEndTime': TimeOfDay.fromDateTime(selectedEndDateTime).format(context),
        'service': widget.service,
        'selectedDay': selectedDay,
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al reservar el turno: $e')),
      );
    }
  }

  // Función para reservar el turno a través de la API
  Future<Activity> _reserveTime(DateTime selectedDay, DateTime startTime, DateTime endTime) async {
    final baseUrl = Config.get('api_base_url');
    final url = Uri.parse('$baseUrl/api/activity/add-activity'); // Asegúrate de que esta sea la URL correcta
    final session = Provider.of<SessionProvider>(context, listen: false);
    final token = session.token;
    final dateFormat = DateFormat('yyyy-MM-dd');
    final body = {
      'actividadid': Utiles.getId(),
      'mascota': widget.mascota,
      'usuario': widget.business.userid,
      'title': widget.service?.actividad,
      'description': widget.service!.descripcion,
      'fecha': dateFormat.format(selectedDay),
      'startime': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
      'endtime': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
      'precio': widget.service!.precio,
       'status': "Aprobada",
       'turnos': 1,
      // Agrega otros campos necesarios según tu API
    };

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      // Reserva exitosa, parsear la nueva actividad
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return Activity.fromJson(data);
    } else {
      // Manejar errores
      throw Exception('Failed to reserve time slot: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    List<TimeOfDay> workingHours;
    try {
      workingHours = _getWorkingHoursForSelectedDay();
    } catch (e) {
      workingHours = [];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Calendario'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Calendario
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            calendarFormat: _calendarFormat,
            onDaySelected: (selectedDay, focusedDay) {
              if (_isDayEnabled(selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Este día no es laborable')),
                );
              }
            },
            eventLoader: _getEventsForDay,
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            enabledDayPredicate: _isDayEnabled,
          ),
          SizedBox(height: 8.0),
          // Título de los horarios disponibles
          Text(
            'Horarios Disponibles para ${_selectedDay.toLocal().toShortDateString()}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          // Lista de horarios disponibles
          Expanded(
            child: ListView.builder(
              itemCount: workingHours.length,
              itemBuilder: (context, index) {
                final hour = workingHours[index];
                final availableSlots = _getAvailableSlotsForHour(_selectedDay, hour);
                final isAvailable = availableSlots > 0;

                return ListTile(
                  title: Text(hour.format(context)),
                  subtitle: Text('Turnos disponibles: $availableSlots'),
                  trailing: isAvailable
                      ? Icon(Icons.check, color: Colors.green)
                      : Icon(Icons.lock, color: Colors.red),
                  onTap: isAvailable
                      ? () => _reserveTimeSlot(_selectedDay, hour)
                      : null,
                );
              },
            ),
          ),
          // (Opcional) Lista de actividades existentes
          /*
                Expanded(
                  child: ListView.builder(
                    itemCount: _getEventsForDay(_selectedDay).length,
                    itemBuilder: (context, index) {
                      final activity = _getEventsForDay(_selectedDay)[index];
                      return ListTile(
                        leading: Image.asset("lib/assets/perro.png", width: 50, height: 50),
                        title: Text(activity.title),
                        subtitle: Text('${activity.startime} - ${activity.endtime}'),
                      );
                    },
                  ),
                ),
                */
        ],
      ),
    );
  }



}