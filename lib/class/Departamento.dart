class Departamento{
    int idDepartamento;
    String nombre_normalizado;

    Departamento({
      required this.idDepartamento,
      required this.nombre_normalizado,

    });

    factory Departamento.fromJson(Map<String, dynamic> json) {
      return Departamento(
        idDepartamento: json['idDepartamento'] ?? 0, // Proporciona un valor predeterminado si el valor es nulo
        nombre_normalizado: json['nombre_normalizado'] ?? '',


      );
    }
}