import 'package:PetCare/pages/Config.dart';
import 'package:PetCare/pages/encuenta_inicio.dart';
import 'package:PetCare/pages/home_aliados.dart';
import 'package:PetCare/pages/home_inicial.dart';
import 'package:PetCare/pages/inicio_page.dart';
import 'package:PetCare/pages/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:provider/provider.dart';
import 'dart:io';


import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:path_provider/path_provider.dart';

import 'class/SessionProvider.dart';
import 'firebase_options.dart';
import 'modelos/ModeloMascota.dart';
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await setupFirebaseMessaging();

  // Inicializa las notificaciones locales
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@drawable/mascota');

  const InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  //FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);



  await Config.loadConfig();

  // ✅ Envolver MyApp con MultiProvider para que SessionProvider esté disponible globalmente
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SessionProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Agregamos el método para determinar la ruta inicial
  Future<String> _determineInitialRoute() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
    bool alreadySelected = prefs.getBool('alreadySelected') ?? false;



    if (!seenOnboarding) {
      return '/onboarding';
    } else if (!alreadySelected) {
      return '/home_inicio'; // Ruta de la pantalla de selección de perfil y actividades
    } else {
      return '/login'; // O la ruta que corresponda después de que el usuario haya hecho su selección
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _determineInitialRoute(), // Determinamos la ruta inicial
      builder: (context, snapshot) {
        // Mostrar una pantalla de carga mientras se verifica SharedPreferences
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        // Si hay un error, podrías manejarlo aquí
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: Text('Error al cargar la aplicación')),
            ),
          );
        }

        // Obtener la ruta inicial determinada
        String initialRoute = snapshot.data ?? '/onboarding';

        return ChangeNotifierProvider(
          create: (_) => SessionProvider(), // Asegúrate de tener este provider definido
          child: MaterialApp(
            title: 'PetCare+',
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            initialRoute: initialRoute,
            navigatorKey: navigatorKey,
            routes: {
              '/onboarding': (context) => OnboardingScreen(),
              '/login': (context) => PetLoginPage(),
              '/home_inicio': (context) => HomePageInicio(),
              '/home_estilista': (context) => HomeEstilista(role: 0),
              '/encuesta_inicio': (context) => PerfilActividadesScreen(), // Agregar esta ruta
            },
          ),
        );
      },
    );
  }

  // Check if onboarding has been seen using shared_preferences
  Future<bool> _checkIfOnboardingSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('seenOnboarding') ?? false;
  }
}

/// **🔹 PASO 2: Configurar Firebase Messaging**
Future<void> setupFirebaseMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // 🔹 Pedir permisos al usuario
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('✅ User granted permission');

    // 🔹 Obtener y guardar el FCM token del usuario
    String? fcmToken = await messaging.getToken();
    print("🟢 FCM Token: $fcmToken");

    // 🔹 Manejar notificaciones en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Mensaje recibido en primer plano: ${message.notification?.title}');

      if (navigatorKey.currentState != null) {
        showNotification(message.notification?.title, message.notification?.body);
      }
    });

    // 🔹 Manejar notificaciones cuando la app está en segundo plano o cerrada
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data.containsKey('screen')) {
        navigatorKey.currentState?.pushNamed(message.data['screen']);
      }
    });

    // 🔹 Manejar notificaciones recibidas cuando la app está en segundo plano
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null && message.data.containsKey('screen')) {
        navigatorKey.currentState?.pushNamed(message.data['screen']);
      }
    });
  } else {
    print('❌ User declined or has not accepted permission');
  }
}

/// **🔹 PASO 3: Mostrar Notificación en Primer Plano**
void showNotification(String? title, String? body) async {
  if (title == null || body == null) return;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  const AndroidNotificationDetails androidPlatformChannelSpecifics =
  AndroidNotificationDetails(
    'your_channel_id', // Cambia esto por un ID único para tu app
    'your_channel_name',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
  );

  const NotificationDetails platformChannelSpecifics =
  NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    platformChannelSpecifics,
    payload: 'item x',
  );
}

