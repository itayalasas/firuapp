import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

import '../class/Mascota.dart';
import '../class/User.dart';

class AnimalCertificatePage extends StatelessWidget {
  final Mascota mascota;
  final User user; // The user object that contains Propietario and Documento

  AnimalCertificatePage({required this.mascota, required this.user});

  Future<Uint8List> _generateCertificate(BuildContext context) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('CÉDULA ANIMAL', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('Nombre: ${mascota.nombre}', style: pw.TextStyle(fontSize: 16)),
              pw.Text('Especie: ${mascota.especie}', style: pw.TextStyle(fontSize: 16)),
              pw.Text('Raza: ${mascota.raza}', style: pw.TextStyle(fontSize: 16)),
              pw.Text('Sexo: ${mascota.genero}', style: pw.TextStyle(fontSize: 16)),
              pw.Text('Nacimiento: ${mascota.fechaNacimiento}', style: pw.TextStyle(fontSize: 16)),
              pw.Text('Propietario: ${user.name}', style: pw.TextStyle(fontSize: 16)),
              pw.Text('Documento: ${user.state}', style: pw.TextStyle(fontSize: 16)),
              pw.Text('N° de Chip: ${mascota.color}', style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 20),
              pw.Text('Dirección: ${user.username}', style: pw.TextStyle(fontSize: 16)),
              pw.Text('Departamento: ${user.state}', style: pw.TextStyle(fontSize: 16)),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/cedula_animal.pdf");
    await file.writeAsBytes(await pdf.save());

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cédula Animal'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final Uint8List pdfData = await _generateCertificate(context);
            // Optionally, share or display the generated PDF
            final dir = await getApplicationDocumentsDirectory();
            final file = File('${dir.path}/cedula_animal.pdf');
            await file.writeAsBytes(pdfData);

            Share.shareFiles([file.path], text: 'Cédula Animal de ${mascota.nombre}');
          },
          child: Text('Generar Cédula Animal'),
        ),
      ),
    );
  }
}
