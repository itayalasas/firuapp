import 'package:intl/intl.dart';

import 'CalendarioWork.dart';

class Calendarioday{
  final String dayid;
  final Calendariowork calendario;
  final String day;
  final bool check;



  Calendarioday({
    required this.dayid,
    required this.calendario,
    required this.day,
    required this.check,

  });

  factory Calendarioday.fromJson(Map<String, dynamic> json) {
    return Calendarioday(
      dayid: json['dayid'] ?? '', // Proporciona un valor predeterminado si el valor es nulo
      calendario: Calendariowork.fromJson(json['calendario'] ??{}),
      day: json['day'] ?? '',
      check: json['check'] ?? false,


    );
  }

  Map<String, dynamic> toJson() {

    return {
      'dayid': dayid,
      'calendario': calendario,
      'day': day,
      'check': check,
    };
  }
}