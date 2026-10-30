import 'package:flutter/foundation.dart';

class ApiConfig {
  // Configurable base URL
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:8000/api/v1";
    }
    // Android emulator alias for host machine localhost
    if (defaultTargetPlatform == TargetPlatform.android) {
      return "http://10.0.2.2:8000/api/v1";
    }
    return "http://localhost:8000/api/v1";
  }

  static const Duration timeoutDuration = Duration(seconds: 8);
}
