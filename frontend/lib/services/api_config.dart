import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Override for physical phones (BLE needs a real device), e.g.
  /// flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000/api/v1
  static const String _override = String.fromEnvironment("API_BASE_URL");

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
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
