import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/common/clinical_button.dart';
import '../../widgets/common/clinical_card.dart';
import 'bluetooth_pairing_screen.dart';

class MyWearableScreen extends StatefulWidget {
  const MyWearableScreen({super.key});

  @override
  State<MyWearableScreen> createState() => _MyWearableScreenState();
}

class _MyWearableScreenState extends State<MyWearableScreen> {
  bool _isConnected = true;
  bool _isLocating = false;

  void _locateBand() {
    setState(() => _isLocating = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Sending vibration signal to ElderGuard Band V2..."),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _isLocating = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("My Wearable"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Device Summary Card
              ClinicalCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.watch_rounded,
                            color: AppColors.primary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "ElderGuard Band V2",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textNavy,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isConnected ? AppColors.successGreen : AppColors.emergencyRed,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isConnected ? "Connected • BLE 5.3" : "Disconnected",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _isConnected ? AppColors.successGreen : AppColors.emergencyRed,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.successSoftBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.battery_charging_full_rounded,
                                  size: 16, color: AppColors.successGreen),
                              SizedBox(width: 4),
                              Text(
                                "92%",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.successGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28, color: AppColors.borderLight),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatPill("Signal", "Strong", Icons.wifi_tethering_rounded),
                        _buildStatPill("Last Sync", "Just now", Icons.sync_rounded),
                        _buildStatPill("Firmware", "v2.4.1", Icons.verified_rounded),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Active IoT Sensors Grid Header
              Text(
                "Active Sensors & Hardware",
                style: AppTypography.labelLg.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 12),

              _buildSensorTile(
                icon: Icons.favorite_rounded,
                color: AppColors.emergencyRed,
                title: "PPG Optical Heart Rate",
                subtitle: "Real-time pulse sampling every second",
                status: "74 BPM",
              ),
              const SizedBox(height: 10),
              _buildSensorTile(
                icon: Icons.air_rounded,
                color: AppColors.primary,
                title: "SpO2 Pulse Oximeter",
                subtitle: "Continuous blood oxygen saturation",
                status: "98% Sat.",
              ),
              const SizedBox(height: 10),
              _buildSensorTile(
                icon: Icons.personal_injury_rounded,
                color: const Color(0xFF7C3AED),
                title: "3-Axis Fall Accelerometer",
                subtitle: "AI fall pattern & sudden impact detector",
                status: "Armed & Active",
              ),
              const SizedBox(height: 10),
              _buildSensorTile(
                icon: Icons.thermostat_rounded,
                color: AppColors.warningAmber,
                title: "Skin Temperature Sensor",
                subtitle: "Monitors fever & hypothermia risk",
                status: "36.6 °C",
              ),

              const SizedBox(height: 24),

              // Quick Actions
              Text(
                "Device Management",
                style: AppTypography.labelLg.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 12),

              ClinicalCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.vibration_rounded, color: AppColors.primary, size: 22),
                      ),
                      title: const Text(
                        "Locate My Band",
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      subtitle: const Text("Chime and vibrate the wearable band"),
                      trailing: TextButton(
                        onPressed: _isLocating ? null : _locateBand,
                        child: Text(_isLocating ? "Locating..." : "Ring"),
                      ),
                    ),
                    const Divider(color: AppColors.borderLight, height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.tune_rounded, color: AppColors.textDark, size: 22),
                      ),
                      title: const Text(
                        "Calibrate Fall Sensitivity",
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      subtitle: const Text("Medium (Standard Sensitivity)"),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Bottom Actions
              ClinicalButton(
                text: "Reconnect Device",
                onPressed: () {
                  setState(() => _isConnected = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Wearable connection refreshed!"),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BluetoothPairingScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Pair New Device",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatPill(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textNavy,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildSensorTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String status,
  }) {
    return ClinicalCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textNavy,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              status,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
