import 'dart:convert';
import 'dart:io';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:flutter/services.dart' show rootBundle;

import '../pages/Config.dart';

class FirebaseNotificationService {
  static const String fcmUrl = "https://fcm.googleapis.com/v1/projects/petapp-3b220/messages:send";

  // Método para obtener el token de autenticación
   static Future<String?> _getAccessToken(String plataforma) async {
    try {
      Map<String, dynamic>? jsonData;
      final urlAuht = Config.get('url_json_chatbot');

      final responseAuth = await http.get(Uri.parse(urlAuht));


      // URL para obtener el token
      final url = Config.get('api_oauth2_googleapis');
      // Crear JWT (token Web)
      final jwt = createJwt(json.decode(responseAuth.body), plataforma);

      // Enviar solicitud POST para obtener el token de acceso
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          'assertion': jwt,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['access_token'];
      } else {
        print('Error obteniendo token: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

// Función para crear el JWT (JSON Web Token)
 static String createJwt(Map<String, dynamic> serviceAccount, String plataforma) {
    final header = {
      'alg': 'RS256',
      'typ': 'JWT',
    };

    String scope="";

    if(plataforma=="dialogflow") scope="https://www.googleapis.com/auth/dialogflow";
    if(plataforma=="google") scope="https://www.googleapis.com/auth/cloud-platform";
    if(plataforma=="messaging") scope="https://www.googleapis.com/auth/firebase.messaging";

    final now = DateTime.now();
    final claims = {
      'iss': serviceAccount['client_email'], // Email de la cuenta de servicio
      'scope': scope, // Alcance
      'aud': 'https://oauth2.googleapis.com/token', // Destinatario
      'exp': (now.millisecondsSinceEpoch / 1000 + 3600).round(), // Expira en 1 hora
      'iat': (now.millisecondsSinceEpoch / 1000).round(), // Hora actual
    };

    // Cargar la clave privada en formato PEM
    final privateKeyPem = serviceAccount['private_key'];

    // Eliminar los encabezados y pies de la clave
    final privateKey = privateKeyPem
        .replaceAll('-----BEGIN PRIVATE KEY-----', '')
        .replaceAll('-----END PRIVATE KEY-----', '')
        .replaceAll(RegExp(r'\s+'), ''); // Elimina los espacios en blanco

    // Decodificar la clave en bytes
    final privateKeyBytes = base64.decode(privateKey);

    // Crear el JWT con las claims y firmarlo con la clave privada
    final jwt = JWT(claims);

    // Firmar el JWT usando RS256 y la clave privada
    final token = jwt.sign(RSAPrivateKey(privateKeyPem), algorithm: JWTAlgorithm.RS256);

    return token;
  }

// Función para firmar el JWT usando la clave privada de la cuenta de servicio
  String signJwt(String input, String privateKey) {
    // Aquí debes implementar la firma usando RS256 (puedes usar la librería 'rsa_pkcs')
    // Añade la lógica de firma con la clave privada
    // Este es un ejemplo simple, necesitas incluir el código para la firma.
    return 'signed_data'; // Reemplazar con el JWT firmado
  }

  // Método para enviar la notificación
  static Future<void> sendNotification(String fcmToken, String title, String body, String plataforma) async {
    final accessToken = await _getAccessToken(plataforma);
    if (accessToken == null) {
      print("❌ No se pudo obtener el token de acceso. Notificación cancelada.");
      return;
    }

    final Map<String, dynamic> data = {
      "message": {
        "token": fcmToken,
        "notification": {
          "title": title,
          "body": body,
        },
        "data": {
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
        }
      }
    };

    final response = await http.post(
      Uri.parse(fcmUrl),
      headers: {
        "Authorization": "Bearer $accessToken",
        "Content-Type": "application/json",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      print("✅ Notificación enviada exitosamente");
    } else {
      print("❌ Error al enviar notificación: ${response.statusCode} - ${response.body}");
    }
  }


}
