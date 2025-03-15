import 'dart:io';

import 'package:PetCare/class/UserRoles.dart';
import 'package:PetCare/pages/Config.dart';
import 'package:PetCare/services/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/chat/v1.dart';
import 'package:googleapis/compute/v1.dart';
import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server/gmail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:googleapis/compute/v1.dart' hide Duration;

import '../pages/Utiles.dart';
import 'login_service.dart';

class UserService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// **🔹 Registrar un nuevo usuario en Firebase Authentication y Firestore**
  Future<void> registerUser({
    required BuildContext context,
    required String name,
    required String email,
    required String phone,
    required String password,
    required String photoUrl,
    String? fcToken,
    required Map<String, dynamic>? role,
  }) async {
    try {
      fb.UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      fb.User? user = userCredential.user;
      if (user != null) {
        // **Marcar como nuevo usuario en `SharedPreferences`**
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isNewUser', true);

        if(photoUrl.isEmpty){
         File? imageFile= await StorageService.setProfileImage(user.uid);
          photoUrl = await AuthService.uploadProfilePicture(user.uid, imageFile!);
        }


        // **Guardar usuario en Firestore**
        await _firestore.collection('users').doc(user.uid).set({
          'userId': user.uid,
          'name': name.trim(),
          'state': 1, // Usuario recién registrado
          'fctoken': fcToken ?? '',
          'email': email.trim(),
          'phone': phone.trim(),
          'photo': photoUrl,
          'acceso':'user-password',
          'created_at': FieldValue.serverTimestamp(),
        });

        // **Guardar el rol dentro de la subcolección `roles`**
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('roles')
            .add({
          'roles': role,
          'assigned_at': FieldValue.serverTimestamp(),
        });

        // **Enviar el correo personalizado con el link de verificación**
        await sendVerificationEmail(name.trim(),email, user.uid);

        // **Mostrar mensaje de verificación de correo**
        if (context.mounted) {
          Utiles.showConfirmationDialog(
            context: context,
            title: 'Registro exitoso',
            content: 'Cuenta creada correctamente. Revisa tu correo para verificar tu cuenta.',
            onConfirm: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          );
        }
      }
    } on fb.FirebaseAuthException catch (e) {
      String errorMessage = 'Error desconocido';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'El correo ya está registrado.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'La contraseña es demasiado débil.';
      }

      if (context.mounted) {
        Utiles.showErrorDialog(
            context: context, title: 'Error', content: errorMessage);
      }
    }
  }

  Future<void> sendVerificationEmail(String name,String email, String userId) async {
    String verificationLink = "https://us-central1-petapp-3b220.cloudfunctions.net/verifyUserEmail?userId=$userId";

    String emailBody = """
  <html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Confirmación de usuario</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            text-align: center;
            padding: 20px;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            border: 1px solid #ddd;
            border-radius: 10px;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
        }
        .header {
            color: #007bff;
            font-size: 24px;
            font-weight: bold;
        }
        .button {
            display: inline-block;
            background-color: #007bff;
            color: #ffffff;
            padding: 10px 20px;
            text-decoration: none;
            border-radius: 5px;
            margin-top: 20px;
        }
        .footer {
            margin-top: 20px;
            color: #555;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">Confirmación de usuario</div>
        <p>Estimado(a) $name,</p>
        <p>Gracias por su registro en la aplicación <strong>PetCare+</strong>. Para hacer uso de la misma debe confirmar su correo. Por favor, haga clic en el siguiente botón para confirmar su usuario:</p>
        <a href="$verificationLink"  class="button">Confirmar usuario</a>
        <p>Si el botón no funciona, puede copiar y pegar el siguiente enlace en su navegador:</p>
        <p>$verificationLink"</p>
        <div class="footer">
            Gracias,<br>
            <strong>Equipo de PetCare+</strong>
        </div>
    </div>
</body>
</html>
  """;

    final emailAddres = Config.get('user_mail_admin');
    final emailToken  = Config.get('user_token_admin');
    final personalizado  = Config.get('user_personalizado_mail');

    final smtpServer = gmail(emailAddres, emailToken);

    final mailer.Message message = mailer.Message()
      ..from = mailer.Address('ayalaitsas@gmail.com', personalizado)
      ..recipients.add(email)
      ..subject = 'Verificación de Correo - PetCare+'
      ..html = emailBody;

    try {
      final sendReport = await mailer.send(message, smtpServer);
      print('Correo enviado: ${sendReport.toString()}');
    } catch (e) {
      print('Error al enviar correo: $e');
    }
  }

  Future<void> registerUserGoogle(BuildContext context, GoogleSignInAccount googleUser, String name, String email, Map<String, dynamic>? role, String photo, String fcmToken) async {
    try {
      fb.UserCredential userCredential = await _auth.signInWithCredential(
        fb.GoogleAuthProvider.credential(
          idToken: (await googleUser.authentication).idToken,
          accessToken: (await googleUser.authentication).accessToken,
        ),
      );

      fb.User? user = userCredential.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'userId': user.uid,
          'name': name.trim(),
          'state': 1, // Usuario recién registrado
          'fctoken': fcmToken,
          'email': email.trim(),
          'phone': '',
          'photo': photo,
          'acceso':'google',
          'created_at': FieldValue.serverTimestamp(),
        });

        await _firestore.collection('users').doc(user.uid).collection('roles').add({
          'roles': role,
          'assigned_at': FieldValue.serverTimestamp(),
        });

        await sendVerificationEmail(name.trim(), email, user.uid);

        // **Mostrar mensaje de éxito**

          if (context.mounted) {
            Utiles.showConfirmationDialog(
              context: context,
              title: 'Registro exitoso',
              content: 'Cuenta creada correctamente. Revisa tu correo para verificar tu cuenta.',
              onConfirm: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
            );
          } else {
            Navigator.of(context, rootNavigator: true).pushReplacementNamed('/login');
          }
        }
    } on fb.FirebaseAuthException catch (e) {
      if (context.mounted) {
        Utiles.showErrorDialog(context: context, title: 'Error', content: "No se pudo completar el registro.");
      }
    }
  }




  String getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos. Verifica tus credenciales.';
      case 'user-not-found':
        return 'No se encontró un usuario con este correo.';
      case 'wrong-password':
        return 'Contraseña incorrecta. Intenta de nuevo.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada. Contacta al soporte.';
      case 'email-already-in-use':
        return 'Este correo ya está registrado. Intenta con otro.';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Intenta más tarde.';
      case 'operation-not-allowed':
        return 'Este método de autenticación no está permitido.';
      default:
        return 'Ocurrió un error inesperado. Intenta de nuevo.';
    }
  }


}
