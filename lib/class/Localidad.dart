class Localidad{
    int idLocalidad;
    String nombre_normalizado;

    Localidad({
      required this.idLocalidad,
      required this.nombre_normalizado,

    });

    factory Localidad.fromJson(Map<String, dynamic> json) {
      return Localidad(
        idLocalidad: json['idLocalidad'] ?? 0, // Proporciona un valor predeterminado si el valor es nulo
        nombre_normalizado: json['nombre_normalizado'] ?? '',


      );
    }
}