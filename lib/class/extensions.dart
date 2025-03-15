// lib/extensions.dart

extension DateTimeFormat on DateTime {
  String toShortDateString() => "${this.day}/${this.month}/${this.year}";
  String toShortTimeString() => "${this.hour}:${this.minute.toString().padLeft(2, '0')}";
}

// Extensión para formatear la fecha
/*extension DateTimeExtension on DateTime {
  String toShortDateString() {
    return "${this.day.toString().padLeft(2, '0')}-${this.month.toString().padLeft(2, '0')}-${this.year}";
  }
}*/