import 'package:intl/intl.dart';

import 'User.dart';

class Calendariowork {
  final String id;
  final String userid;
  final String startTime;
  final String endTime;



  Calendariowork({
    required this.id,
    required this.userid,
    required this.startTime,
    required this.endTime,

  });

  factory Calendariowork.fromJson(Map<String, dynamic> json) {
    return Calendariowork(
      id: json['id'] ?? '', // Proporciona un valor predeterminado si el valor es nulo
      userid: json['userid'] ?? '',
      startTime: json['starttime'] ?? '',
      endTime: json['endtime'] ?? '',


    );
  }

  Map<String, dynamic> toJson() {
    final dateFormat = DateFormat('yyyy-MM-dd');

    return {
      'id': id,
      'userid': userid,
      'starttime': startTime,
      'endtime': endTime,
    };
  }
}