import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/common/clinical_button.dart';
import '../../widgets/common/clinical_card.dart';
import '../../widgets/emergency/pulse_radar.dart';
import '../elderly/health_dashboard_screen.dart';

class EmergencyAlertSentScreen extends StatelessWidget {
  final bool isFallEvent;

  const EmergencyAlertSentScreen({
    super.key,
    this.isFallEvent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F5),
      appBar: AppBar(
        title: const Text("Emergency Alert Broadcast"),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Radar Flashing Beacon
              Center(
                child: PulseRadar(
                  size: 190,
                  pulseColor: AppColors.emergencyRed,
                  centerWidget: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.emergencyRed,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.emergencyRed.withValues(alpha: 0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.campaign_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                "Emergency Alert Sent!",
                style: AppTypography.display.copyWith(
                  color: AppColors.emergencyRed,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isFallEvent
                    ? "Automatic fall alarm broadcast to family and emergency services."
                    : "SOS distress signal sent to family contacts with your live GPS location.",
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(color: AppColors.textMuted),
              ),

              const SizedBox(height: 24),

              // Dispatch Checklist Card
              ClinicalCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildDispatchItem(
                      icon: Icons.check_circle_rounded,
                      color: AppColors.successGreen,
                      title: "Nimal Perera (Son & Caregiver)",
                      subtitle: "Alert delivered • Phone ringing with audio siren",
                    ),
                    const Divider(height: 20, color: AppColors.borderLight),
                    _buildDispatchItem(
                      icon: Icons.check_circle_rounded,
                      color: AppColors.successGreen,
                      title: "1990 Emergency Ambulance",
                      subtitle: "Triage standby • Incident ID #EG-9912",
                    ),
                    const Divider(height: 20, color: AppColors.borderLight),
                    _buildDispatchItem(
                      icon: Icons.my_location_rounded,
                      color: AppColors.primary,
                      title: "Live GPS Telemetry Broadcast",
                      subtitle: "No. 42, Temple Road, Colombo 03 (Active)",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              ClinicalButton(
                text: "Call Nimal Perera (Son)",
                leading: const Icon(Icons.call_rounded, color: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Calling Nimal Perera (+94 71 987 6543)..."),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Connecting to Suwa Seriya 1990 Emergency Ambulance..."),
                        backgroundColor: AppColors.emergencyRed,
                      ),
                    );
                  },
                  icon: const Icon(Icons.emergency_rounded, size: 20),
                  label: const Text(
                    "Call 1990 Emergency Services",
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emergencyRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HealthDashboardScreen()),
                    (route) => false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textNavy,
                  side: const BorderSide(color: AppColors.borderLight, width: 1.5),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  "I Am Safe Now (Deactivate Alert)",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDispatchItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textNavy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
