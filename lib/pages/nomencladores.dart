
 import 'package:cloud_firestore/cloud_firestore.dart';


 Future<void> insertRazasToFirestore() async {
   final CollectionReference tipoRazaCol =
   FirebaseFirestore.instance.collection('tipo_raza');

   // Lista completa de razas (extraída del Excel) con atributo 'tipo': 'Perro'
   final List<Map<String, dynamic>> razas = [
     { 'nombre': "Yorkshire Terrier",         'porcentaje': 12.0, 'tamanio': "Pequeño",  'pesoMin_kg': 2.0,  'pesoMax_kg': 3.0  },
     { 'nombre': "Pastor Alemán",             'porcentaje': 10.0, 'tamanio': "Grande",    'pesoMin_kg': 30.0, 'pesoMax_kg': 40.0 },
     { 'nombre': "French Poodle (Caniche)",   'porcentaje': 9.0,  'tamanio': "Pequeño",  'pesoMin_kg': 3.0,  'pesoMax_kg': 6.0  },
     { 'nombre': "Golden Retriever",          'porcentaje': 8.0,  'tamanio': "Grande",    'pesoMin_kg': 25.0, 'pesoMax_kg': 34.0 },
     { 'nombre': "Labrador Retriever",        'porcentaje': 7.0,  'tamanio': "Grande",    'pesoMin_kg': 25.0, 'pesoMax_kg': 36.0 },
     { 'nombre': "Border Collie",             'porcentaje': 6.0,  'tamanio': "Mediano",   'pesoMin_kg': 14.0, 'pesoMax_kg': 20.0 },
     { 'nombre': "Pug",                       'porcentaje': 5.0,  'tamanio': "Pequeño",  'pesoMin_kg': 6.0,  'pesoMax_kg': 8.0  },
     { 'nombre': "Bulldog Francés",           'porcentaje': 4.0,  'tamanio': "Pequeño",  'pesoMin_kg': 8.0,  'pesoMax_kg': 14.0 },
     { 'nombre': "Mini Pinscher",             'porcentaje': 3.0,  'tamanio': "Pequeño",  'pesoMin_kg': 4.0,  'pesoMax_kg': 6.0  },
     { 'nombre': "Schnauzer Miniatura",       'porcentaje': 3.0,  'tamanio': "Pequeño",  'pesoMin_kg': 5.0,  'pesoMax_kg': 8.0  },
     { 'nombre': "Beagle",                    'porcentaje': 2.5,  'tamanio': "Mediano",   'pesoMin_kg': 9.0,  'pesoMax_kg': 11.0 },
     { 'nombre': "Chihuahua",                 'porcentaje': 2.5,  'tamanio': "Pequeño",  'pesoMin_kg': 1.5,  'pesoMax_kg': 3.0  },
     { 'nombre': "Boxer",                     'porcentaje': 2.0,  'tamanio': "Grande",    'pesoMin_kg': 25.0, 'pesoMax_kg': 32.0 },
     { 'nombre': "Dálmata",                   'porcentaje': 2.0,  'tamanio': "Grande",    'pesoMin_kg': 23.0, 'pesoMax_kg': 25.0 },
     { 'nombre': "Cocker Spaniel",            'porcentaje': 1.8,  'tamanio': "Mediano",   'pesoMin_kg': 13.0, 'pesoMax_kg': 15.0 },
     { 'nombre': "Pequeño DétoxUruguay",      'porcentaje': 1.5,  'tamanio': "Pequeño",  'pesoMin_kg': 14.0, 'pesoMax_kg': 18.0 },
     { 'nombre': "Rottweiler",                'porcentaje': 1.2,  'tamanio': "Grande",    'pesoMin_kg': 42.0, 'pesoMax_kg': 60.0 },
     { 'nombre': "Pastor Australiano",        'porcentaje': 1.0,  'tamanio': "Mediano",   'pesoMin_kg': 18.0, 'pesoMax_kg': 25.0 },
     { 'nombre': "Mastín Italiano",           'porcentaje': 0.8,  'tamanio': "Gigante",   'pesoMin_kg': 50.0, 'pesoMax_kg': 70.0 },
     { 'nombre': "Shar Pei",                  'porcentaje': 0.7,  'tamanio': "Mediano",   'pesoMin_kg': 18.0, 'pesoMax_kg': 27.0 },
     { 'nombre': "Husky Siberiano",           'porcentaje': 0.6,  'tamanio': "Mediano",   'pesoMin_kg': 20.0, 'pesoMax_kg': 27.0 },
     { 'nombre': "Akita Inu",                 'porcentaje': 0.6,  'tamanio': "Grande",    'pesoMin_kg': 34.0, 'pesoMax_kg': 54.0 },
     { 'nombre': "Shiba Inu",                 'porcentaje': 0.5,  'tamanio': "Mediano",   'pesoMin_kg': 8.0,  'pesoMax_kg': 10.0 },
     { 'nombre': "Cane Corso",                'porcentaje': 0.5,  'tamanio': "Grande",    'pesoMin_kg': 45.0, 'pesoMax_kg': 50.0 },
     { 'nombre': "San Bernardo",              'porcentaje': 0.4,  'tamanio': "Gigante",   'pesoMin_kg': 55.0, 'pesoMax_kg': 90.0 },
     { 'nombre': "Gran Danés",                'porcentaje': 0.3,  'tamanio': "Gigante",   'pesoMin_kg': 54.0, 'pesoMax_kg': 90.0 },
     { 'nombre': "Weimaraner",                'porcentaje': 0.3,  'tamanio': "Grande",    'pesoMin_kg': 30.0, 'pesoMax_kg': 40.0 },
     { 'nombre': "Basenji",                   'porcentaje': 0.3,  'tamanio': "Mediano",   'pesoMin_kg': 9.0,  'pesoMax_kg': 11.0 },
     { 'nombre': "Boston Terrier",            'porcentaje': 0.3,  'tamanio': "Pequeño",  'pesoMin_kg': 6.0,  'pesoMax_kg': 11.0 },
     { 'nombre': "Fox Terrier",               'porcentaje': 0.2,  'tamanio': "Pequeño",  'pesoMin_kg': 6.0,  'pesoMax_kg': 9.0  },
     { 'nombre': "Lhasa Apso",                'porcentaje': 0.2,  'tamanio': "Pequeño",  'pesoMin_kg': 5.0,  'pesoMax_kg': 7.0  },
     { 'nombre': "Perro Cimarrón Uruguayo",   'porcentaje': 0.2,  'tamanio': "Grande",    'pesoMin_kg': 33.0, 'pesoMax_kg': 45.0 },
     { 'nombre': "Perro Mestizo (sin raza)",  'porcentaje': 15.0, 'tamanio': "Variable",  'pesoMin_kg': 5.0,  'pesoMax_kg': 35.0 },
     { 'nombre': "Caniche Mediano",           'porcentaje': 0.2,  'tamanio': "Mediano",   'pesoMin_kg': 7.0,  'pesoMax_kg': 12.0 },
     { 'nombre': "Pastor Belga",              'porcentaje': 0.2,  'tamanio': "Grande",    'pesoMin_kg': 25.0, 'pesoMax_kg': 30.0 },
     { 'nombre': "Pointer",                   'porcentaje': 0.2,  'tamanio': "Grande",    'pesoMin_kg': 20.0, 'pesoMax_kg': 30.0 },
     { 'nombre': "Braco Alemán",              'porcentaje': 0.2,  'tamanio': "Grande",    'pesoMin_kg': 25.0, 'pesoMax_kg': 32.0 },
     { 'nombre': "Collie",                    'porcentaje': 0.2,  'tamanio': "Grande",    'pesoMin_kg': 22.0, 'pesoMax_kg': 34.0 },
     { 'nombre': "Pekingese",                 'porcentaje': 0.1,  'tamanio': "Pequeño",  'pesoMin_kg': 3.0,  'pesoMax_kg': 6.0  },
   ];

   for (final raza in razas) {
     final dataConTipo = {
       ...raza,
       'tipo': 'Perro',
     };
     await tipoRazaCol.add(dataConTipo);
   }

   print('✅ Razas insertadas correctamente en Firestore (con campo tipo="Perro")');
 }



 Future<void> insertGatosToFirestore() async {
   final col = FirebaseFirestore.instance.collection('tipo_raza');

   final List<Map<String, dynamic>> gatos = [
     {
       'nombre': 'Mestizo (Domestic Shorthair)',
       'pesoMin_kg': 2.0,
       'pesoMax_kg': 6.0,
       'porcentaje': 94.0,
       'tamanio': 'Variable',
       'tipo': 'Gato',
     },
     {
       'nombre': 'Ragdoll',
       'pesoMin_kg': 4.0,
       'pesoMax_kg': 7.0,
       'porcentaje': 6 * 0.1534,
       'tamanio': 'Mediano',
       'tipo': 'Gato',
     },
     {
       'nombre': 'Maine Coon',
       'pesoMin_kg': 5.0,
       'pesoMax_kg': 8.0,
       'porcentaje': 6 * 0.1312,
       'tamanio': 'Grande',
       'tipo': 'Gato',
     },
     {
       'nombre': 'Persa (Persian)',
       'pesoMin_kg': 3.0,
       'pesoMax_kg': 4.0,
       'porcentaje': 6 * 0.1190,
       'tamanio': 'Pequeño',
       'tipo': 'Gato',
     },
     {
       'nombre': 'Exotic Shorthair',
       'pesoMin_kg': 3.0,
       'pesoMax_kg': 5.0,
       'porcentaje': 6 * 0.0935,
       'tamanio': 'Pequeño',
       'tipo': 'Gato',
     },
     {
       'nombre': 'Devon Rex',
       'pesoMin_kg': 2.0,
       'pesoMax_kg': 4.0,
       'porcentaje': 6 * 0.0819,
       'tamanio': 'Pequeño',
       'tipo': 'Gato',
     },
     {
       'nombre': 'Otras razas puras',
       'pesoMin_kg': 3.0,
       'pesoMax_kg': 6.0,
       'porcentaje': 6 * 0.42,
       'tamanio': 'Variable',
       'tipo': 'Gato',
     },
   ];

   for (var raza in gatos) {
     await col.add(raza);
   }
   print('✅ Razas de Gato insertadas correctamente');
 }

 /// Inserta las especies de aves de compañía más comunes en Uruguay con todos los campos
 Future<void> insertAvesToFirestore() async {
   final col = FirebaseFirestore.instance.collection('tipo_raza');

   final List<Map<String, dynamic>> aves = [
     {
       'nombre': 'Periquito (Budgerigar)',
       'pesoMin_kg': 0.03,
       'pesoMax_kg': 0.04,
       'porcentaje': 45.0,
       'tamanio': 'Pequeño',
       'tipo': 'Ave',
     },
     {
       'nombre': 'Cacatúa Ninfa (Cockatiel)',
       'pesoMin_kg': 0.08,
       'pesoMax_kg': 0.12,
       'porcentaje': 20.0,
       'tamanio': 'Mediano',
       'tipo': 'Ave',
     },
     {
       'nombre': 'Agapornis (Lovebird)',
       'pesoMin_kg': 0.05,
       'pesoMax_kg': 0.06,
       'porcentaje': 10.0,
       'tamanio': 'Pequeño',
       'tipo': 'Ave',
     },
     {
       'nombre': 'Canario',
       'pesoMin_kg': 0.02,
       'pesoMax_kg': 0.03,
       'porcentaje': 8.0,
       'tamanio': 'Pequeño',
       'tipo': 'Ave',
     },
     {
       'nombre': 'Conures y Parrotlets',
       'pesoMin_kg': 0.08,
       'pesoMax_kg': 0.15,
       'porcentaje': 8.0,
       'tamanio': 'Mediano',
       'tipo': 'Ave',
     },
     {
       'nombre': 'Loro gris africano y medianos/grandes',
       'pesoMin_kg': 0.4,
       'pesoMax_kg': 0.6,
       'porcentaje': 5.0,
       'tamanio': 'Grande',
       'tipo': 'Ave',
     },
     {
       'nombre': 'Otras especies (finches, papagayos, etc.)',
       'pesoMin_kg': 0.01,
       'pesoMax_kg': 1.0,
       'porcentaje': 4.0,
       'tamanio': 'Variable',
       'tipo': 'Ave',
     },
   ];

   for (var raza in aves) {
     await col.add(raza);
   }
   print('✅ Especies de Ave insertadas correctamente');
 }
