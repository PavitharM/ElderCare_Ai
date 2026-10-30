import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/common/clinical_card.dart';
import '../../widgets/emergency/pulse_radar.dart';
import 'pairing_successful_screen.dart';

class BluetoothPairingScreen extends StatefulWidget {
  const BluetoothPairingScreen({super.key});

  @override
  State<BluetoothPairingScreen> createState() => _BluetoothPairingScreenState();
}

class _BluetoothPairingScreenState extends State<BluetoothPairingScreen> {
  String? _pairingDeviceId;

  final List<Map<String, dynamic>> _devices = [
    {
      "id": "DEV-8492",
      "name": "ElderGuard Band V2 #8492",
      "type": "ElderGuard Smart Band",
      "signal": "Strong Signal (-48 dBm)",
      "battery": "92%",
      "recommended": true,
    },
    {
      "id": "DEV-1029",
      "name": "SmartHealth Pulse #1029",
      "type": "Generic BLE Sensor",
      "signal": "Moderate (-72 dBm)",
      "battery": "65%",
      "recommended": false,
    },
    {
      "id": "DEV-4411",
      "name": "Unknown Health Device",
      "type": "BLE Device",
      "signal": "Weak (-85 dBm)",
      "battery": "40%",
      "recommended": false,
    },
  ];

  void _startPairing(String id) {
    setState(() => _pairingDeviceId = id);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const PairingSuccessfulScreen(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Pair New Device"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight,
            ),
            child: const Icon(
              Icons.bluetooth_searching_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              // Radar Scanner
              Center(
                child: PulseRadar(
                  size: 200,
                  pulseColor: AppColors.primary,
                  centerWidget: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.watch_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Text(
                "Scanning for Nearby Wearables...",
                style: AppTypography.headlineSm.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textNavy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Hold your ElderGuard wearable close to your phone",
                textAlign: TextAlign.center,
                style: AppTypography.bodySm.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 28),

              // Discovered Devices Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Available Devices (${_devices.length})",
                    style: AppTypography.labelLg.copyWith(fontSize: 15),
                  ),
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Device Cards
              ..._devices.map((device) {
                final isPairing = _pairingDeviceId == device["id"];
                final isRecommended = device["recommended"] == true;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ClinicalCard(
                    padding: const EdgeInsets.all(16),
                    borderColor: isRecommended ? AppColors.primary : AppColors.borderLight,
                    backgroundColor: isRecommended ? const Color(0xFFF9FEFE) : Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: isRecommended ? AppColors.primaryLight : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.watch_rounded,
                                color: isRecommended ? AppColors.primary : AppColors.textDark,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          device["name"] as String,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textNavy,
                                          ),
                                        ),
                                      ),
                                      if (isRecommended)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryLight,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            "Official",
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.signal_cellular_alt_rounded,
                                          size: 14, color: AppColors.successGreen),
                                      const SizedBox(width: 4),
                                      Text(
                                        device["signal"] as String,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.battery_5_bar_rounded,
                                          size: 14, color: AppColors.primary),
                                      const SizedBox(width: 2),
                                      Text(
                                        device["battery"] as String,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: isPairing ? null : () => _startPairing(device["id"] as String),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isRecommended ? AppColors.primary : Colors.white,
                              foregroundColor: isRecommended ? Colors.white : AppColors.textNavy,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: isRecommended ? Colors.transparent : AppColors.borderLight,
                                ),
                              ),
                            ),
                            child: isPairing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.bluetooth_connected_rounded,
                                        size: 18,
                                        color: isRecommended ? Colors.white : AppColors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        "Connect & Pair",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
