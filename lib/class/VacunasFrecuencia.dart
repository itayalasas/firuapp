
class VacunaFrecuencia{
   int id;
  String nombreVacuna;
  String tipoRaza;
  int edadInicioSemanas;
  int frecuenciaRefuerzo;
  String? observaciones;

  VacunaFrecuencia({
    required this.id,
    required this.nombreVacuna,
    required this.tipoRaza,
    required this.edadInicioSemanas,
    required this.frecuenciaRefuerzo,
    this.observaciones,
  });

  // Método para crear una instancia de VacunaFrecuencia a partir de un JSON
  factory VacunaFrecuencia.fromJson(Map<String, dynamic> json) {
    return VacunaFrecuencia(
      id: json['id'],
      nombreVacuna: json['nombreVacuna'],
      tipoRaza: json['tipoRaza'],
      edadInicioSemanas: json['edadInicioSemanas'],
      frecuenciaRefuerzo: json['frecuenciaRefuerzo'],
      observaciones: json['observaciones'],
    );
  }

  // Método para convertir una instancia de VacunaFrecuencia a un JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombreVacuna': nombreVacuna,
      'tipoRaza': tipoRaza,
      'edadInicioSemanas': edadInicioSemanas,
      'frecuenciaRefuerzo': frecuenciaRefuerzo,
      'observaciones': observaciones,
    };
  }
}