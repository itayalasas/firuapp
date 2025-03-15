import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class Config {
  static late Map<String, String> _config;

  static Future<void> loadConfig() async {
    final configString = await rootBundle.loadString('lib/assets/config.properties');
    _config = _parseProperties(configString);
  }

  static String get(String key) {
    return _config[key] ?? '';
  }

  static Map<String, String> _parseProperties(String properties) {
    final map = <String, String>{};
    final lines = LineSplitter.split(properties);
    for (var line in lines) {
      if (line.isNotEmpty && !line.startsWith('#')) {
        final index = line.indexOf('=');
        if (index != -1) {
          final key = line.substring(0, index).trim();
          final value = line.substring(index + 1).trim();
          map[key] = value;
        }
      }
    }
    return map;
  }
}
