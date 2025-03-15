class Desparasitaciones {
  final int deparacitacionid;
  final int mascotaid;
  final String tipoDesparasitante;
  final String nombreProducto;
  final String fechaAdministracion;
  final String proximaFechaDesparasitacion;
  final String? veterinarioResponsable;
  final String clinicaVeterinaria;
  final String? observaciones;


  Desparasitaciones({
    required this.deparacitacionid,
    required this.mascotaid,
    required this.tipoDesparasitante,
    required this.nombreProducto,
    required this.fechaAdministracion,
    required this.proximaFechaDesparasitacion,
    this.veterinarioResponsable,
    required this.clinicaVeterinaria,
    this.observaciones,

  });

  factory Desparasitaciones.fromJson(Map<String, dynamic> json) {
    return Desparasitaciones(
      deparacitacionid: json['deparacitacionid'] ?? 0, // Proporciona un valor predeterminado si el valor es nulo
      mascotaid: json['mascotaid'] ?? 0,
      tipoDesparasitante: json['tipoDesparasitante'] ?? '',
      fechaAdministracion: json['fechaAdministracion'] ?? '',
      proximaFechaDesparasitacion: json['proximaFechaDesparasitacion'] ?? '',
      veterinarioResponsable: json['veterinarioResponsable'] ?? '',
      clinicaVeterinaria: json['clinicaVeterinaria'] ?? '',
      nombreProducto: json['nombreProducto'] ?? '',
      observaciones: json['observaciones'] ?? '',

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deparacitacionid': deparacitacionid,
      'mascotaid': mascotaid,
      'tipoDesparasitante': tipoDesparasitante,
      'fechaAdministracion': fechaAdministracion,
      'proximaFechaDesparasitacion': proximaFechaDesparasitacion,
      'veterinarioResponsable': veterinarioResponsable,
      'clinicaVeterinaria': clinicaVeterinaria,
      'nombreProducto': nombreProducto,
      'observaciones': observaciones,
    };
  }
}