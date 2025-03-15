

class ServiceNegocio {
  final int roleId;
  final String descripcion;
  final String businessId;
  final String userId;
  final String foto;


  ServiceNegocio({
    required this.roleId,
    required this.descripcion,
    required this.businessId,
    required this.userId,
    required this.foto,

  });

  // Método para crear una instancia de Event a partir de un JSON
  factory ServiceNegocio.fromJson(Map<String, dynamic> json) {

    return ServiceNegocio(
      roleId: json['roleId'] ?? 0,
      descripcion: json['descripcion'] ?? '',
      businessId: json['businessId'] ?? '',
      userId: json['userId'] ?? '',
      foto: json['foto'] ?? '',

    );
  }

  // Método para convertir una instancia de Event a un JSON
  Map<String, dynamic> toJson() {
    return {
      'roleId': roleId,
      'descripcion': descripcion,
      'businessId': businessId,
      'userId': userId,

    };
  }


}
