import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../class/User.dart' as NewUser;

import '../class/SessionProvider.dart';


import '../class/UserRoles.dart';
import '../services/UserService.dart';
import '../services/login_service.dart';
import 'Config.dart';
import 'Utiles.dart';

class PetLoginPage extends StatefulWidget {
  @override
  _PetLoginPageState createState() => _PetLoginPageState();
}

class _PetLoginPageState extends State<PetLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isObscured = true;
  bool isSignUp = false;
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _isAccepted = false;
  bool _isAcceptedError = false;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  Map<String, dynamic>? _selectedRole;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> perfil = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? fcmToken;
  bool _isLoadingLogin = false;
  bool _isLoadingGoogle = false;
  bool _isLoadingRegister = false;

  late FirebaseMessaging messaging;





  @override
  void initState() {
    super.initState();
   // _checkUserLoggedIn();

    _loadUserCredentials(); // Cargar credenciales guardadas
    _fetchRoles();


  }

  Future<void> updateFCMToken(String userId) async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    try {
      String? token = await messaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection("users").doc(userId).update({
          "fcmToken": token,
        });
        print("FCM Token actualizado: $token");
      } else {
        print("No se pudo obtener el token FCM.");
      }
    } catch (e) {
      print("Error actualizando el token FCM: $e");
    }
  }

  Future<void> _fetchRoles() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('user_perfil').get();

      if (mounted) {
        setState(() {
          perfil = snapshot.docs.map((doc) {
            return {
              'id': doc['id'] is int ? doc['id'] as int : int.tryParse(doc['id'].toString()) ?? 0,
              'perfil': doc['perfil'] as String
            };
          }).toList();
        });
      }
    } catch (e) {
      print('Error fetching roles: $e');
    }
  }

  // Método para cargar correo y contraseña guardados
  Future<void> _loadUserCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? false;
      if (_rememberMe) {
        _emailController.text = prefs.getString('email') ?? '';
        _passwordController.text = prefs.getString('password') ?? '';
      }
    });
  }

  // Método para guardar el correo y la contraseña
  Future<void> _saveUserCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('email', _emailController.text);
      await prefs.setString('password', _passwordController.text);
    } else {
      await prefs.remove('email');
      await prefs.remove('password');
      await prefs.setBool('remember_me', false);
    }
  }

  /************----------nuevo aqui---------***********/
  Future<void> _signIn() async {
    final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
    final userService = UserService();

    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (userCredential.user != null) {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();

          if (userDoc.exists) {
            int userState = userDoc.get('state') ?? 1;

            if (userState == 2) {
              CollectionReference rolesRef = _firestore.collection('users')
                  .doc(userCredential.user!.uid)
                  .collection('roles');

              QuerySnapshot querySnapshot = await rolesRef.get();

              List<Perfil> perfil = querySnapshot.docs.map((doc) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                Map<String, dynamic>? roleData = data['roles'] as Map<
                    String,
                    dynamic>?;
                return Perfil.fromJson(roleData ?? {});
              }).toList();

              await updateFCMToken(userCredential.user!.uid);
              await _saveUserCredentials();
              await sessionProvider.signIn(userCredential);
              await sessionProvider.setUserPerfil(perfil);

              if (perfil.isNotEmpty) {
                if (perfil.length > 1) {
                  _showRoleSelectionDialog(perfil, sessionProvider);
                } else {
                  _navigateToHome(perfil.first.id, sessionProvider);
                }
              } else {
                Utiles.showErrorDialog(
                  context: context,
                  title: 'Error',
                  content: 'El usuario ${sessionProvider.user!
                      .username} no tiene asignado un perfil de acceso. '
                      'Por favor contactar a un administrador.info@firuapp.com.uy.',
                );
              }
            } else {
              Utiles.showErrorDialog(
                context: context,
                title: 'Verificación de correo',
                content: 'Por favor, verifica tu correo antes de continuar.',
              );
            }
          } else {
            Utiles.showErrorDialog(
              context: context,
              title: 'Error',
              content: 'No se encontraron datos de usuario.',
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = userService.getAuthErrorMessage(e.code);
        String email = _emailController.text.trim();
        if (errorMessage != 'Ocurrió un error inesperado. Intenta de nuevo.') {
          // Si el error es uno de los que tenemos en la lista, lo mostramos directamente.
          Utiles.showErrorDialog(
            context: context,
            title: 'Error al iniciar sesión',
            content: errorMessage,
          );
        } else {
          // Si no es un error conocido, verificamos si el usuario existe en la base de datos.
          QuerySnapshot userSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .get();

          if (userSnapshot.docs.isNotEmpty) {
            Utiles.showErrorDialog(
              context: context,
              title: 'Acceso denegado',
              content: 'Este correo debe autenticarse mediante otro método. Por favor, usa la opción correcta.',
            );
          } else {
            Utiles.showErrorDialog(
              context: context,
              title: 'Error al iniciar sesión',
              content: 'No se encontró un usuario con este correo.',
            );
          }
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showRoleSelectionDialog(List<Perfil> perfiles, SessionProvider sessionProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                      'Selecciona tu perfil',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                // 🔹 Lista de Perfiles
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(15),
                    child: Column(
                      children: perfiles.map((perfil) {
                        return ListTile(
                          leading: _getRoleIcon(perfil.id),
                          title: Text(
                            _getRoleName(perfil.id),
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.black),
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            _navigateToHome(perfil.id, sessionProvider);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
                // 🔹 Botón de Cancelar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.red),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Icon _getRoleIcon(int role) {
    switch (role) {
      case 1:
        return Icon(Icons.person, color: Colors.blue); // Icono para Propietario
      case 2:
        return Icon(
            Icons.directions_walk, color: Colors.green); // Icono para Paseador
      case 4:
        return Icon(
            Icons.shop, color: Colors.green); // Icono para Tienda mascota
      case 7:
        return Icon(Icons.cut, color: Colors.purple); // Icono para Estilista
      default:
        return Icon(Icons.help, color: Colors.grey); // Icono predeterminado
    }
  }

  // Mostrar errores
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))],
      ),
    );
  }



  // Inicio de sesión con Google
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // 🔹 Cerrar sesión previa para forzar la selección de cuenta
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // Si cancela el inicio de sesión

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          // 🟢 Usuario no registrado, mostrar diálogo de confirmación
          _showRegisterPrompt(googleUser, googleUser.displayName ?? 'Sin Nombre', googleUser.email, googleUser.photoUrl ?? '');
        } else {
          final sessionProvider = Provider.of<SessionProvider>(context, listen: false);

          int userState = userDoc.get('state') ?? 1;

          if (userState == 2) {
            // ✅ Cargar datos del usuario y obtener roles
            CollectionReference rolesRef = _firestore.collection('users').doc(
                userCredential.user!.uid).collection('roles');

            QuerySnapshot querySnapshot = await rolesRef.get();

            List<Perfil> perfil = querySnapshot.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

              // Acceder correctamente al campo 'role'
              Map<String, dynamic>? roleData = data['roles'] as Map<
                  String,
                  dynamic>?;

              return Perfil.fromJson(roleData ?? {}); // Evitar null
            }).toList();

            // 🔹 Actualizar el FCM Token
            await updateFCMToken(userCredential.user!.uid);

            // 🔹 Usuario ya registrado, ir a la pantalla principal
            await sessionProvider.signIn(userCredential);
            await sessionProvider.setUserPerfil(perfil);

            if (perfil.isNotEmpty) {
              if (perfil.length > 1) {
                _showRoleSelectionDialog(perfil, sessionProvider);
              } else {
                _navigateToHome(perfil.first.id, sessionProvider);
              }
            } else {
              Utiles.showErrorDialog(
                context: context,
                title: 'Error',
                content: 'El usuario ${sessionProvider.user!
                    .username} no tiene asignado un perfil de acceso. '
                    'Por favor contactar a un administrador.\n info@firuapp.com.uy.',
              );
            }
          }else{
            Utiles.showErrorDialog(
              context: context,
              title: 'Verificación de correo',
              content: 'Por favor, verifica tu correo antes de continuar.',
            );
          }
        }
      }
    } catch (e) {
      _showErrorDialog("Error con Google", "No se pudo iniciar sesión con Google.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showRegisterPrompt(GoogleSignInAccount user, String name, String email, String photo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                      "Usuario no registrado",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                // 🔹 Mensaje
                Padding(
                  padding: EdgeInsets.all(15),
                  child: Text(
                    "El usuario $email no está registrado. ¿Deseas registrarte?",
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                ),
                // 🔹 Botones
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        child: Text(
                          "Cancelar",
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.red),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          "Registrar",
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Colors.white),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showRoleNewUser(user, name, email, photo);
                        },
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
  }


  void _showRoleNewUser(GoogleSignInAccount user, String name, String email, String photo) {
    String? selectedRole;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
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
                    // 🔹 Selector de Rol
                    Padding(
                      padding: EdgeInsets.all(15),
                      child:   DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          labelText: "Perfil",
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedRole != null ? _selectedRole!['id'] as int? : null, // Asegurar int o null
                        items: perfil.map<DropdownMenuItem<int>>((roleData) {
                          return DropdownMenuItem<int>(
                            value: roleData['id'] as int, // Aseguramos que sea int
                            child: Text(roleData['perfil'] as String), // Aseguramos que sea String
                          );
                        }).toList(),
                        onChanged: (int? value) {
                          setState(() {
                            _selectedRole = perfil.firstWhere(
                                  (role) => role['id'] == value,
                              orElse: () => <String, Object>{'id': 0, 'perfil': 'Desconocido'}, // Corregido
                            );
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
                    // 🔹 Botones
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
                              if (_selectedRole != null) {
                                // 🔹 Cerrar modal de selección
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
                                              "Registrando...",
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
                                  FirebaseMessaging messaging = FirebaseMessaging.instance;
                                  String? token = await messaging.getToken();
                                  final userService = UserService();

                                  await userService.registerUserGoogle(
                                    context, user, name, email,  _selectedRole, photo, token!,
                                  );

                                  // 🔹 Cerrar loader correctamente
                                  if (loaderContext?.mounted ?? false) {
                                    Navigator.of(loaderContext!, rootNavigator: true).pop();
                                  }

                                } catch (e) {
                                  // 🔹 Cerrar loader en caso de error
                                  if (loaderContext?.mounted ?? false) {
                                    Navigator.of(loaderContext!, rootNavigator: true).pop();
                                  }

                                  Future.delayed(Duration(milliseconds: 0), () {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text("Error al registrar usuario."),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  });
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Por favor selecciona un perfil."),
                                    backgroundColor: Colors.red,
                                  ),
                                );
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
  }




//Registrar un usuario en firebase
  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => _isLoadingRegister = true);
// 🔹 Actualizar el FCM Token
    FirebaseMessaging messaging = FirebaseMessaging.instance;
      String? token = await messaging.getToken();
    try {
      final userService = UserService();
      await userService.registerUser(
        context: context,
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        password: _passwordController.text,
        photoUrl: "",
        fcToken: token,
        role: _selectedRole, // Ahora se guarda en la subcolección `roles`
      );
    } finally {
      setState(() => _isLoadingRegister = false);
    }
  }


  /*****************************---hasta aqui lo nuevo migrado--------**********************************/




  Future<bool> signOutFromGoogle() async {
    try {
      await FirebaseAuth.instance.signOut();
      return true;
    } on Exception catch (_) {
      return false;
    }
  }




  String _getRoleName(int role) {
    switch (role) {
      case 1:
        return 'Dueño';
      case 2:
        return 'Aliado';
      case 4:
        return 'Tienda mascota';
      case 7:
        return 'Estilista';
      default:
        return 'Rol desconocido';
    }
  }



  Future<void> _navigateToHome(int perfil, SessionProvider sessionProvider, ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    bool alreadySelected = prefs.getBool('alreadySelected') ?? false;

    switch (perfil) {
      case 1:
        sessionProvider.rolAcceso=perfil;
        if(alreadySelected){
          Navigator.pushReplacementNamed(context, '/home_inicio');
        }else{
          Navigator.pushReplacementNamed(context, '/encuesta_inicio');
        }

        break;
      case 2:
        sessionProvider.rolAcceso=perfil;
        if(alreadySelected){
          Navigator.pushReplacementNamed(context, '/home_estilista');
        }else{
          Navigator.pushReplacementNamed(context, '/encuesta_inicio');
        }
        break;
      default:
      // Manejo de rol desconocido
        Utiles.showInfoDialog(
            context: context, title: 'Error', message: 'Rol en desarrollo.');
        break;
    }
  }


  @override
  Widget build(BuildContext context) {
    final double fieldWidth = 300;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 32.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 5,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            width: 350,
            padding: EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 40),
                  Image.asset(
                    'lib/assets/logos/mascota.png',
                    height: 100,
                  ),
                  SizedBox(height: 20),

                  // Botones de LOGIN y REGISTRARSE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isSignUp = false;
                          });
                        },
                        child: Text(
                          'LOGIN',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 16,
                            fontWeight: !isSignUp ? FontWeight.bold : null,
                            decoration: !isSignUp ? TextDecoration.underline : null,
                            decorationColor: Colors.green,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isSignUp = true;
                          });
                        },
                        child: Text(
                          'REGISTRARSE',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 16,
                            decoration: isSignUp ? TextDecoration.underline : null, // Agregado el subrayado dinámico
                            decorationColor: Colors.green,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Mostrar campos de registro solo si es SignUp
                  if (isSignUp) ...[
                    buildTextField('Nombre y apellido', Icons.person, _nameController, false),
                    buildTextField('Teléfono', Icons.phone, _phoneController, false),
                    buildTextField('Correo electrónico', Icons.email, _emailController, false),
                    buildPasswordField('Contraseña', Icons.lock, _passwordController, true, isSignUp),
                    SizedBox(height: 10),

                    // Combo para seleccionar el rol
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: "Perfil",
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedRole != null ? _selectedRole!['id'] as int? : null, // Asegurar int o null
                      items: perfil.map<DropdownMenuItem<int>>((roleData) {
                        return DropdownMenuItem<int>(
                          value: roleData['id'] as int, // Aseguramos que sea int
                          child: Text(roleData['perfil'] as String), // Aseguramos que sea String
                        );
                      }).toList(),
                      onChanged: (int? value) {
                        setState(() {
                          _selectedRole = perfil.firstWhere(
                                (role) => role['id'] == value,
                            orElse: () => <String, Object>{'id': 0, 'perfil': 'Desconocido'}, // Corregido
                          );
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Por favor selecciona un perfil';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Checkbox de políticas y condiciones
                    Row(
                      children: [
                        Checkbox(
                          value: _isAccepted,
                          onChanged: (bool? value) {
                            setState(() {
                              _isAccepted = value!;
                              _isAcceptedError = !_isAccepted;
                            });
                          },
                          activeColor: Colors.green,
                        ),
                        Flexible(
                          child: Wrap(
                            children: [
                              Text(
                                'Aceptar ',
                                style: TextStyle(
                                  color: _isAcceptedError ? Colors.red : Colors.black,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  launch('http://179.31.2.98/');
                                },
                                child: Text(
                                  'Políticas y Condiciones',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_isAcceptedError)
                      Container(
                        margin: EdgeInsets.only(top: 5),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Debes aceptar los términos y condiciones para continuar.',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    SizedBox(height: 20),
                  ] else ...[
                    buildTextField('Correo electrónico', Icons.email, _emailController, false),
                    buildPasswordField('Contraseña', Icons.lock, _passwordController, true, isSignUp),
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (bool? value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                          activeColor: Colors.green,
                        ),
                        Text('Recordar contraseña', style: TextStyle(color: Colors.black)),
                      ],
                    ),
                  ],

                  SizedBox(height: 20),

                  // Botón de acción principal (Login o Registrar)
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        if (isSignUp) {
                          if (!_isAccepted) {
                            setState(() {
                              _isAcceptedError = true;
                            });
                            return;
                          }
                          setState(() {
                            _isLoadingRegister = true;
                            _isLoadingLogin = false;
                            _isLoadingGoogle = false;
                          });

                          await _registerUser();

                          setState(() {
                            _isLoadingRegister = false;
                          });
                        } else {
                          setState(() {
                            _isLoadingLogin = true;
                            _isLoadingRegister = false;
                            _isLoadingGoogle = false;
                          });

                          await _signIn();

                          setState(() {
                            _isLoadingLogin = false;
                          });
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: _isLoadingLogin || _isLoadingRegister
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                      isSignUp ? 'Registrar' : 'Login',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Botón de Google con cambio de texto dinámico
                  Visibility(
                    visible: !isSignUp, // Solo muestra el botón si no es SignUp
                    child: ElevatedButton.icon(
                      onPressed: _isLoadingGoogle
                          ? null
                          : () async {
                        setState(() {
                          _isLoadingGoogle = true;
                          _isLoadingLogin = false;
                          _isLoadingRegister = false;
                        });

                        await _signInWithGoogle();

                        setState(() {
                          _isLoadingGoogle = false;
                        });
                      },
                      icon: _isLoadingGoogle
                          ? CircularProgressIndicator(color: Colors.black)
                          : Image.asset('lib/assets/logos/google_logo.png', height: 24),
                      label: Text(
                        'Iniciar sesión con Google', // Eliminamos la opción de "Registrarse con Google"
                        style: TextStyle(fontSize: 18, color: Colors.black),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: Size(double.infinity, 50),
                        side: BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),

                  SizedBox(height: 20),
                  // Opción de "¿Has olvidado tu contraseña?"
                  if (!isSignUp)
                    TextButton(
                      onPressed: () {
                        // Lógica para recuperar la contraseña
                        _showForgotPasswordDialog();
                      },
                      child: Text(
                        '¿Has olvidado tu contraseña?',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool validateUruguayanPhoneNumber(String phoneNumber) {
    // Normalizar el número eliminando espacios y caracteres no numéricos
    String normalizedNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');

    // Validar formato con código de país
    final RegExp regexWithCountryCode = RegExp(r'^\+598(9\d{7})$'); // +598 seguido de 9 y 7 dígitos más

    // Validar formato sin código de país
    final RegExp regexWithoutCountryCode = RegExp(r'^(09\d{7}|\d{8})$'); // 09 seguido de 7 dígitos (móviles) o 8 dígitos (fijos)

    // Validar si el número es válido con código de país o sin él
    if (regexWithCountryCode.hasMatch(normalizedNumber) || regexWithoutCountryCode.hasMatch(normalizedNumber)) {
      return true;
    }

    return false;
  }


  // Método reutilizable para crear campos de texto con bordes rectos
  Widget buildTextField(String labelText, IconData icon, TextEditingController controller, bool isPassword) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && _isObscured,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(icon, color: Colors.green),
          filled: true,
          fillColor: Colors.white, // Fondo blanco para los campos de texto
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), // Bordes rectos para los campos
          ),
        ),
        style: TextStyle(color: Colors.black),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor ingrese su $labelText';
          }

          if (labelText == "Correo electrónico") {
            if (!_validateEmail(value)) {
              return 'Correo electrónico no válido';
            }
          }

          if (labelText == "Teléfono") {
            if (!validateUruguayanPhoneNumber(value)) {
              return 'Ingrese un número de móvil o fijo válido';
            }
          }

          return null;
        },
      ),
    );
  }


  // Método reutilizable para crear campo de contraseña con ícono de ojo

  Widget buildPasswordField(String labelText, IconData icon, TextEditingController controller, bool isPassword, bool isSignUp) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              obscureText: _isObscured,
              decoration: InputDecoration(
                labelText: labelText,
                prefixIcon: Icon(icon, color: Colors.green),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botón para mostrar/ocultar contraseña
                    IconButton(
                      icon: Icon(
                        _isObscured ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isObscured = !_isObscured;
                        });
                      },
                    ),
                    // Mostrar Tooltip SOLO si es REGISTRO
                    if (isSignUp)
                      Tooltip(
                        message: 'Debe tener más de 8 caracteres, incluir una mayúscula, un número y un símbolo.',
                        textStyle: TextStyle(color: Colors.white, fontSize: 12),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.info_outline, color: Colors.green),
                      ),
                  ],
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              style: TextStyle(color: Colors.black),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese su contraseña';
                }
                if (isSignUp) {
                  // Validación solo para el registro
                  if (value.length < 8) {
                    return 'Debe tener más de 8 caracteres';
                  }
                  if (!RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+{}\[\]:;<>,.?/~])').hasMatch(value)) {
                    return 'Debe contener una mayúscula, un número y un símbolo';
                  }
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }


  // Mostrar el diálogo de "¿Olvidaste tu contraseña?"
  void _showForgotPasswordDialog() {
    final _formKey = GlobalKey<FormState>();
    bool _isLoading = false;  // Variable local para el estado de carga en el diálogo

    showDialog(
      context: context,
      barrierDismissible: false, // Esto evita que se cierre al hacer clic fuera
      builder: (BuildContext context) {
        return StatefulBuilder(  // Añadimos StatefulBuilder para poder actualizar el estado dentro del diálogo
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              backgroundColor: Colors.grey[100],

              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Por favor, ingresa tu correo electrónico para recuperar la contraseña.',
                      style: TextStyle(color: Colors.black),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Correo electrónico',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.mail, color: Colors.green),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      // Validación del correo electrónico
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu correo electrónico';
                        }
                        if (!_validateEmail(value)) {
                          return 'Correo electrónico no válido';
                        }
                        return null;
                      },
                      style: TextStyle(color: Colors.black),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Cerrar el diálogo
                  },
                  child: Text('Cancelar', style: TextStyle(color: Colors.black)),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Validar el formulario antes de proceder
                    if (_formKey.currentState!.validate()) {
                      // Si el formulario es válido, proceder con la lógica de recuperación
                      setState(() {
                        _isLoading = true;
                      });
                      _recoverPassword().then((_) {
                        setState(() {
                          _isLoading = false;
                        });
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: _isLoading
                      ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : Text('Recuperar', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }


// Método para validar un correo electrónico
  bool _validateEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }



// Lógica para recuperar la contraseña

  Future<void> _recoverPassword() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String email = _emailController.text.trim();
      final FirebaseAuth auth = FirebaseAuth.instance;
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // 🔍 1. Buscar el usuario en Firestore por su email
      final QuerySnapshot userQuery = await firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        // ❌ El usuario NO existe en Firestore
        Utiles.showErrorDialog(
          context: context,
          title: 'Error',
          content: 'No existe un usuario registrado con este correo.',
        );
      } else {
        // ✅ El usuario existe en Firestore → Verificar el atributo 'acceso'
        final userData = userQuery.docs.first.data() as Map<String, dynamic>;
        final String acceso = userData['acceso'] ?? '';

        if (acceso == "user-password") {
          // ✅ Enviar correo de recuperación si el acceso es por email y contraseña
          await auth.sendPasswordResetEmail(email: email);

          Utiles.showConfirmationDialog(
            context: context,
            title: 'Correo Enviado',
            content: 'Hemos enviado un enlace a tu correo para restablecer la contraseña.',
            onConfirm: () {
              _emailController.clear();
              Navigator.of(context).pop();
            },
          );
        } else {
          // ❌ Si el acceso es con Google u otro proveedor, mostrar mensaje de error
          Utiles.showInfoDialog(
            context: context,
            title: 'Notificación',
            message: 'Este usuario está registrado con otro método de acceso y no permite restablecer la contraseña.',
          );
        }
      }
    } catch (e) {
      Utiles.showErrorDialog(
        context: context,
        title: 'Error',
        content: 'Error al procesar la solicitud: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


}
