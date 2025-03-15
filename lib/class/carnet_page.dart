import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';


import 'Mascota.dart';
import 'User.dart';

class CertificatePage extends StatelessWidget {
  final Mascota mascota;
  final User user; // The user object that contains Propietario and Documento

  CertificatePage({required this.mascota, required this.user});

  @override
  Widget build(BuildContext context) {
    DateTime dateTime = DateTime.parse(mascota.fechaNacimiento!);
    // Obtener el año de nacimiento
    String year = dateTime.year.toString();
    String formattedDateRegistro = DateFormat('dd/MM/yyyy').format(mascota.fechaRegistroChip!);

    return Scaffold(
      appBar: AppBar(
        title: Text('Certificado'),
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: () => _downloadAsPDF(context),
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _shareCertificate(),
          ),
        ],
      ),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('lib/assets/inba_background.png'), // Imagen de fondo
              fit: BoxFit.contain, // Ajustar para que se vea completa
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 337, // Ajusta esta posición según tu imagen
                left: 23,
                child: Text(
                    mascota.nombre.toUpperCase(),
                  style: TextStyle(fontSize: 14),
                ),
              ),
              Positioned(
                top: 284,
                left: 189,
                child: Text(
                   mascota.microchip!,
                  style: TextStyle(fontSize: 14),
                ),
              ),
              Positioned(
                top: 362,
                left: 260,
                child: Text(year ,
                  style: TextStyle(fontSize: 14),
                ),
              ),
              Positioned(
                top: 339,
                left: 260,
                child: Text(
                  mascota.especie.toUpperCase(),
                  style: TextStyle(fontSize: 14),
                ),
              ),
              Positioned(
                top: 360,
                left: 23,
                child: Text(
                   mascota.raza.toUpperCase(),
                  style: TextStyle(fontSize: 14),
                ),
              ),
              Positioned(
                top: 383,
                left: 23,
                child: Text(
                 mascota.genero!.toUpperCase(),
                  style: TextStyle(fontSize: 14),
                ),
              ),
              Positioned(
                top: 407,
                left: 23,
                child: Text(
                   mascota.direccion!.departamento,
                  style: TextStyle(fontSize: 14),
                ),
              ),
              Positioned(
                top: 383,
                left: 260,
                child: Text(
                   mascota.castrado!.toUpperCase(),
                  style: TextStyle(fontSize: 14),
                ),
              ),
              Positioned(
                top: 430,
                left: 23,
                child: Text(
                  mascota.direccion!.calleNumero.toUpperCase() +' '+ mascota.direccion!.localidad.toUpperCase()+' '+ mascota.direccion!.departamento.toUpperCase(),
                  style: TextStyle(fontSize: 14),
                ),
              ),
              Positioned(
                top: 470,
                left: 23,
                child: Text(
                  user.name.toUpperCase(),
                  style: TextStyle(fontSize: 14),
                ),
              ),
              Positioned(
                top: 470,
                left: 260,
                child: Text(
                  'CI '+user.documento!,
                  style: TextStyle(fontSize: 14),
                ),
              ),
              Positioned(
                top: 296,
                left: 300,
                child: Text(
                  DateFormat('dd/MM/yyyy').format(mascota.fechaRegistroChip!),
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // Método para generar el PDF
  Future<void> _downloadAsPDF(BuildContext context) async {
    final pdf = pw.Document();
    final image = await rootBundle.load('lib/assets/inba_background.png');
    DateTime dateTime = DateTime.parse(mascota.fechaNacimiento!);
    // Obtener el año de nacimiento
    String year = dateTime.year.toString();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              pw.Image(
                pw.MemoryImage(image.buffer.asUint8List()),
                fit: pw.BoxFit.contain,
              ),
              pw.Positioned(
                top: 284,
                left: 189,
                child: pw.Text(
                  mascota.microchip!,
                  style: pw.TextStyle(fontSize: 14),
                ),
              ),
              pw.Positioned(
                top: 362,
                left: 260,
                child: pw.Text(year ,
                  style: pw.TextStyle(fontSize: 14),
                ),
              ),
              pw.Positioned(
                top: 339,
                left: 260,
                child: pw.Text(
                  mascota.especie.toUpperCase(),
                  style: pw.TextStyle(fontSize: 14),
                ),
              ),
              pw.Positioned(
                top: 360,
                left: 23,
                child: pw.Text(
                  mascota.raza.toUpperCase(),
                  style: pw.TextStyle(fontSize: 14),
                ),
              ),
              pw.Positioned(
                top: 383,
                left: 23,
                child: pw.Text(
                  mascota.genero!.toUpperCase(),
                  style: pw.TextStyle(fontSize: 14),
                ),
              ),
              pw.Positioned(
                top: 407,
                left: 23,
                child: pw.Text(
                  mascota.direccion!.departamento,
                  style: pw.TextStyle(fontSize: 14),
                ),
              ),
              pw.Positioned(
                top: 383,
                left: 260,
                child: pw.Text(
                  mascota.castrado!.toUpperCase(),
                  style: pw.TextStyle(fontSize: 14),
                ),
              ),
              pw.Positioned(
                top: 430,
                left: 23,
                child: pw.Text(
                  mascota.direccion!.calleNumero.toUpperCase() +' '+ mascota.direccion!.localidad.toUpperCase()+' '+ mascota.direccion!.departamento.toUpperCase(),
                  style: pw.TextStyle(fontSize: 14),
                ),
              ),
              pw.Positioned(
                top: 470,
                left: 23,
                child: pw.Text(
                  user.name.toUpperCase(),
                  style: pw.TextStyle(fontSize: 14),
                ),
              ),
              pw.Positioned(
                top: 470,
                left: 260,
                child: pw.Text(
                  'CI '+user.documento!,
                  style: pw.TextStyle(fontSize: 14),
                ),
              ),
              pw.Positioned(
                top: 296,
                left: 300,
                child: pw.Text(
                  DateFormat('dd/MM/yyyy').format(mascota.fechaRegistroChip!),
                  style: pw.TextStyle(fontSize: 14),
                ),
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/certificado.pdf');
    await file.writeAsBytes(await pdf.save());

    // Mostrar diálogo para guardar
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'certificado.pdf',
    );
  }

  // Método para compartir el certificado
  Future<void> _shareCertificate() async {
    final pdf = pw.Document();
    final image = await rootBundle.load('lib/assets/inba_background.png');

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              pw.Image(
                pw.MemoryImage(image.buffer.asUint8List()),
                fit: pw.BoxFit.contain,
              ),
              pw.Positioned(
                top: 337,
                left: 23,
                child: pw.Text(
                  mascota.nombre.toUpperCase(),
                  style: pw.TextStyle(fontSize: 14),
                ),
              ),
              // (Agregar todas las demás posiciones como en el código original)
              pw.Positioned(
                top: 296,
                left: 300,
                child: pw.Text(
                  DateFormat('dd/MM/yyyy').format(mascota.fechaRegistroChip!),
                  style: pw.TextStyle(fontSize: 14),
                ),
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/certificado.pdf');
    await file.writeAsBytes(await pdf.save());

    // Compartir archivo a través de WhatsApp u otras aplicaciones
    await Share.shareFiles([file.path], text: 'Aquí está el certificado de mi mascota.');
  }

}
