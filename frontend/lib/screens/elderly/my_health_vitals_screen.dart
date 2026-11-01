import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/common/clinical_card.dart';
import '../../state/mock_app_state.dart';
import 'health_trends_screen.dart';

class MyHealthVitalsScreen extends StatelessWidget {
  const MyHealthVitalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = MockAppState();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("My Health Vitals"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.timeline_rounded, color: AppColors.primary),
            tooltip: "7-Day Trends",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HealthTrendsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI Live Health Status Card
              ClinicalCard(
                backgroundColor: const Color(0xFFF0FDF4),
                borderColor: const Color(0xFFBBF7D0),
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, color: AppColors.successGreen),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "AI Medical Assessment",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textNavy,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "All biometrics are normal and stable. No abnormal spikes or falls detected.",
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF166534),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Vitals Breakdown Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Real-Time Telemetry",
                    style: AppTypography.labelLg.copyWith(fontSize: 16),
                  ),
                  const Row(
                    children: [
                      Icon(Icons.sensors_rounded, size: 14, color: AppColors.successGreen),
                      SizedBox(width: 4),
                      Text(
                        "Live BLE Stream",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.successGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Heart Rate Card
              _buildVitalDetailedCard(
                icon: Icons.favorite_rounded,
                color: const Color(0xFFEF4444),
                title: "Heart Rate",
                value: "${state.heartRate.value} BPM",
                status: "Normal & Regular",
                normalRange: "Normal: 60 - 100 BPM",
                waveformColor: const Color(0xFFEF4444),
              ),
              const SizedBox(height: 14),

              // SpO2 Card
              _buildVitalDetailedCard(
                icon: Icons.air_rounded,
                color: const Color(0xFF00838F),
                title: "Blood Oxygen (SpO₂)",
                value: "${state.spO2.value}%",
                status: "Optimal Saturation",
                normalRange: "Normal: 95% - 100%",
                waveformColor: const Color(0xFF00838F),
              ),
              const SizedBox(height: 14),

              // Skin Temperature Card
              _buildVitalDetailedCard(
                icon: Icons.thermostat_rounded,
                color: const Color(0xFFF59E0B),
                title: "Skin Temperature",
                value: "${state.temperature.value} °C",
                status: "Healthy Range",
                normalRange: "Normal: 36.1°C - 37.2°C",
                waveformColor: const Color(0xFFF59E0B),
              ),
              const SizedBox(height: 14),

              // Fall Detection Sensor Card
              _buildVitalDetailedCard(
                icon: Icons.personal_injury_rounded,
                color: const Color(0xFF7C3AED),
                title: "Fall Detection Sensor",
                value: "1.0G (Resting)",
                status: "Armed & Calibrated",
                normalRange: "Trigger threshold: >2.5G sudden deceleration",
                waveformColor: const Color(0xFF7C3AED),
              ),

              const SizedBox(height: 24),

              // Link to Trends
              ClinicalCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HealthTrendsScreen()),
                  );
                },
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: const Row(
                  children: [
                    Icon(Icons.show_chart_rounded, color: AppColors.primary, size: 26),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "View 7-Day Trend Analytics",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textNavy,
                            ),
                          ),
                          Text(
                            "Weekly averages, circadian rhythm & alerts",
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVitalDetailedCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required String status,
    required String normalRange,
    required Color waveformColor,
  }) {
    return ClinicalCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
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
                        normalRange,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successSoftBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.successGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textNavy,
                  letterSpacing: -0.5,
                ),
              ),
              // Simulated Waveform Bars
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [14, 22, 10, 28, 16, 24, 32, 18, 26, 12, 20].map((h) {
                  return Container(
                    margin: const EdgeInsets.only(left: 3),
                    width: 4,
                    height: h.toDouble(),
                    decoration: BoxDecoration(
                      color: waveformColor.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
