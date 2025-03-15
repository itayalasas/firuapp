class Calle{
    int idCalle;
    String nombre_normalizado;

    Calle({
      required this.idCalle,
      required this.nombre_normalizado,

    });

    factory Calle.fromJson(Map<String, dynamic> json) {
      return Calle(
        idCalle: json['idCalle'] ?? 0, // Proporciona un valor predeterminado si el valor es nulo
        nombre_normalizado: json['nombre_normalizado'] ?? '',


      );
    }
}