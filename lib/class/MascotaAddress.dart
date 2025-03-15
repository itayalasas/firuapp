class MascotaAddress{
    String id;
    String calleNumero;
    String departamento;
    String localidad;
    String latitud;
    String longitud;

    MascotaAddress({
      required this.id,
      required this.calleNumero,
      required this.departamento,
      required this.localidad,
      required this.latitud,
      required this.longitud,



    });

    factory MascotaAddress.fromJson(Map<String, dynamic> json) {
      return MascotaAddress(
        id: json['id'] ?? '', // Proporciona un valor predeterminado si el valor es nulo
        calleNumero: json['calleNumero'] ?? '',
        departamento: json['departamento'] ?? '',
        localidad: json['localidad'] ?? '',
        latitud: json['latitud'] ?? '',
        longitud: json['longitud'] ?? '',
      );
    }

    Map<String, dynamic> toJson() {
      return {
        'id': id,
        'calleNumero': calleNumero,
        'departamento': departamento,
        'localidad': localidad,
        'latitud': latitud,
        'longitud': longitud,

      };
    }
}