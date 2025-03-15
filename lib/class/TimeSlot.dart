import 'package:flutter/material.dart';

class TimeSlot {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  late final int availableTurnos;
  late final bool isAvailable;

  TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.availableTurnos,
    required this.isAvailable,
  });
}
