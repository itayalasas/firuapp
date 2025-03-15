class Localidades{
int id;
String nombre;
int codigoPostal;
String? alias;

Localidades({
  required this.id,
  required this.nombre,
  required this.codigoPostal,
   this.alias,

});

factory Localidades.fromJson(Map<String, dynamic> json) {
  return Localidades(
    id: json['id'] ?? 0, // Proporciona un valor predeterminado si el valor es nulo
    nombre: json['nombre'] ?? '',
    codigoPostal: json['codigoPostal'] ?? 0,
    alias: json['alias'] ?? '',


  );
}

}