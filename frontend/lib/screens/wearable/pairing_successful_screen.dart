import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/common/clinical_button.dart';
import '../../widgets/common/clinical_card.dart';
import '../elderly/health_dashboard_screen.dart';

class PairingSuccessfulScreen extends StatefulWidget {
  const PairingSuccessfulScreen({super.key});

  @override
  State<PairingSuccessfulScreen> createState() => _PairingSuccessfulScreenState();
}

class _PairingSuccessfulScreenState extends State<PairingSuccessfulScreen> {
  bool _testingVibration = false;

  void _triggerTest() {
    setState(() => _testingVibration = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.vibration_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text("Simulating wearable alert vibration & audible chime!"),
          ],
        ),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _testingVibration = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Pairing Complete"),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // Success Circle Icon
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.successSoftBg,
                  border: Border.all(color: const Color(0xFFA7F3D0), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.successGreen.withValues(alpha: 0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.successGreen,
                  size: 52,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                "Device Paired Successfully!",
                style: AppTypography.headlineLg.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 6),
              Text(
                "Your wearable is now continuously streaming biometrics and monitoring for sudden falls.",
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(color: AppColors.textMuted),
              ),

              const SizedBox(height: 28),

              // Device Status Card
              ClinicalCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.watch_rounded,
                            color: AppColors.primary,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "ElderGuard Band V2",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textNavy,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Connected via Bluetooth 5.3 Low Energy",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28, color: AppColors.borderLight),
                    // Sensor Status Grid
                    _buildTelemetryRow(
                      icon: Icons.battery_charging_full_rounded,
                      color: AppColors.successGreen,
                      title: "Battery Level",
                      value: "92% (Est. 4 days)",
                    ),
                    const SizedBox(height: 12),
                    _buildTelemetryRow(
                      icon: Icons.favorite_rounded,
                      color: AppColors.emergencyRed,
                      title: "Optical PPG Sensor",
                      value: "Active (74 BPM Normal)",
                    ),
                    const SizedBox(height: 12),
                    _buildTelemetryRow(
                      icon: Icons.personal_injury_rounded,
                      color: AppColors.primary,
                      title: "Fall Detection Algorithm",
                      value: "Armed & Calibrated",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Vibration Test Button
              OutlinedButton.icon(
                onPressed: _testingVibration ? null : _triggerTest,
                icon: Icon(
                  _testingVibration ? Icons.sync_rounded : Icons.volume_up_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
                label: Text(
                  _testingVibration ? "Testing Vibration..." : "Test Wearable Vibration & Chime",
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Primary Action: Go to Dashboard
              ClinicalButton(
                text: "Go to Health Dashboard",
                showChevron: true,
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HealthDashboardScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetryRow({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
