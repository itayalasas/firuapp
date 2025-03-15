import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../class/SessionProvider.dart';

class PaymentPage extends StatefulWidget {
  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isLoading = false;

  Future<void> _createPreference() async {
    setState(() {
      if (context.mounted) {
        final session = Provider.of<SessionProvider>(context, listen: false);
        session.notifyListeners();
      }

      _isLoading = true;
    });

    final url = Uri.parse('http://YOUR_SERVER_URL/create_preference');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': 'Producto de prueba',
        'unit_price': 100.0,
        'quantity': 1,
        'description': 'Descripción del producto',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final initPoint = data['init_point'];

      if (await canLaunch(initPoint)) {
        await launch(initPoint);
      } else {
        throw 'Could not launch $initPoint';
      }
    } else {
      throw 'Error creating preference: ${response.body}';
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pago con Mercado Pago'),
      ),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : ElevatedButton(
          onPressed: _createPreference,
          child: Text('Pagar con Mercado Pago'),
        ),
      ),
    );
  }
}
