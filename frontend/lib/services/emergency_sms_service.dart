import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Sends emergency SMS directly from the patient's SIM (Android only), so caregivers are
/// alerted even when the phone has no internet. Native side: android/.../MainActivity.kt
class EmergencySmsService {
  static final EmergencySmsService _instance = EmergencySmsService._internal();
  factory EmergencySmsService() => _instance;
  EmergencySmsService._internal();

  static const MethodChannel _channel = MethodChannel("elderguard/emergency_sms");

  static bool get isSupported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Ask once at startup so the permission is ready before an emergency happens.
  Future<bool> ensurePermission() async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>("requestPermission") ?? false;
    } catch (e) {
      debugPrint("SMS permission request failed: $e");
      return false;
    }
  }

  /// Sends [message] to every number; returns how many were handed to the SIM.
  Future<int> sendToAll(List<String> phones, String message) async {
    if (!isSupported || phones.isEmpty) return 0;
    final hasPermission = await _channel.invokeMethod<bool>("hasPermission") ?? false;
    if (!hasPermission && !await ensurePermission()) {
      debugPrint("Emergency SMS skipped: SEND_SMS permission denied");
      return 0;
    }
    var sent = 0;
    for (final phone in phones.toSet()) {
      try {
        await _channel.invokeMethod("send", {"phone": phone, "message": message});
        sent++;
      } catch (e) {
        debugPrint("Emergency SMS to $phone failed: $e");
      }
    }
    return sent;
  }
}
