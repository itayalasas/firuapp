class UserRoles {
  int id;
  int rolid;
  String userid;

  UserRoles({
    required this.id,
    required this.userid,
    required this.rolid,

  });

  factory UserRoles.fromJson(Map<String, dynamic> json) {
    return UserRoles(
      id: json['id'] ?? 0, // Proporciona un valor predeterminado si el valor es nulo
      rolid: json['rolid'] ?? 0,
      userid: json['userid'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userid': userid,
      'id': id,
      'rolid': rolid,
    };
  }

}



class UserPerfil {
  int id;
  int idperfil;
  String iduser;

  UserPerfil({
    required this.id,
    required this.iduser,
    required this.idperfil,

  });

  factory UserPerfil.fromJson(Map<String, dynamic> json) {
    return UserPerfil(
      id: json['id'] ?? 0, // Proporciona un valor predeterminado si el valor es nulo
      idperfil: json['idperfil'] ?? 0,
      iduser: json['iduser'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idperfil': idperfil,
      'id': id,
      'iduser': iduser,
    };
  }

}



class Perfil {
  int id;
  String perfil;

  Perfil({
    required this.id,
    required this.perfil,

  });

  factory Perfil.fromJson(Map<String, dynamic> json) {
    return Perfil(
      id: json['id'] ?? 0, // Proporciona un valor predeterminado si el valor es nulo
      perfil: json['perfil'] ?? '',

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'perfil': perfil,
      'id': id,
    };
  }

}




class PerfilRoles {
  int id;
  String descripcion;
  String? foto;

  PerfilRoles({
    required this.id,
    required this.descripcion,
    this.foto,
  });

  factory PerfilRoles.fromJson(Map<String, dynamic> json) {
    return PerfilRoles(
      id: json['id'] ?? 0, // Proporciona un valor predeterminado si el valor es nulo
      descripcion: json['descripcion'] ?? '',
      foto: json['foto'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'descripcion': descripcion,
      'id': id,
        'foto': foto,
    };
  }

}