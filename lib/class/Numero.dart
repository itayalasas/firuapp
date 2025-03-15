class Numero{

  int nro_puerta;

  Numero({
    required this.nro_puerta,

  });

  factory Numero.fromJson(Map<String, dynamic> json) {
    return Numero(
      nro_puerta: json['nro_puerta'] ?? 0, // Proporciona un valor predeterminado si el valor es nulo


    );
  }
}