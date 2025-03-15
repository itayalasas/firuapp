import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../class/Negocio.dart';
import '../class/SessionProvider.dart';
import 'Config.dart';
import 'Utiles.dart';

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';

class RegisterBusinessPage extends StatefulWidget {
  @override
  _RegisterBusinessPageState createState() => _RegisterBusinessPageState();
}

class _RegisterBusinessPageState extends State<RegisterBusinessPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _rutController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetNumberController = TextEditingController();
  final _localityController = TextEditingController();
  File? _logo;
  final _picker = ImagePicker();
  bool _isLoading = false;

  final List<String> _departments = ['Montevideo', 'Canelones', 'Maldonado'];
  String? _selectedDepartment;

  Future<void> _pickLogo() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _logo = File(pickedFile.path);
      });
    }
  }

  Future<String> _uploadLogo(File logo) async {
    try {
      String fileName = 'logos/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(logo);
      TaskSnapshot taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Error al subir el logo: $e');
    }
  }

  Future<void> _registerBusiness() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String logoUrl = _logo != null ? await _uploadLogo(_logo!) : 'https://example.com/default-logo.png';
      final session = Provider.of<SessionProvider>(context, listen: false);
      await FirebaseFirestore.instance.collection('businesses').add({
        'name': _nameController.text,
        'rut': _rutController.text,
        'phone': _phoneController.text,
        'address': '${_streetNumberController.text}, ${_localityController.text}, $_selectedDepartment',
        'latitud': '',
        'longitud': '',
        'logo_url': logoUrl,
        'average_rating': 0.0,
        'created_at': FieldValue.serverTimestamp(),
        'userid': session.user!.userId,  // Reemplazar con el ID real del usuario logueado
        'review_count': 0,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Negocio registrado exitosamente')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar el negocio: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registrar Negocio')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickLogo,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  child: _logo == null
                      ? Icon(Icons.camera_alt, size: 40, color: Colors.grey[800])
                      : ClipOval(child: Image.file(_logo!, width: 100, height: 100, fit: BoxFit.cover)),
                ),
              ),
              SizedBox(height: 10),
              _buildTextField(_nameController, 'Nombre del negocio', Icons.business),
              _buildTextField(_rutController, 'RUT (opcional)', Icons.account_balance),
              _buildTextField(_phoneController, 'Número de teléfono', Icons.phone),
              _buildDropdownField('Departamento', _departments, _selectedDepartment, (value) {
                setState(() => _selectedDepartment = value);
              }),
              _buildTextField(_streetNumberController, 'Calle y número', Icons.location_on),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _registerBusiness,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: Size(double.infinity, 50)),
                child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Registrar', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.green),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true, fillColor: Colors.white,
        ),
        validator: (value) => value == null || value.isEmpty ? 'Ingrese $label' : null,
      ),
    );
  }

  Widget _buildDropdownField(String label, List<String> items, String? value, ValueChanged<String?> onChanged) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: Colors.white),
        value: value,
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
        validator: (value) => value == null || value.isEmpty ? 'Seleccione $label' : null,
      ),
    );
  }
}

