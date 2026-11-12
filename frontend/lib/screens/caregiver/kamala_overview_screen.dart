import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/common/clinical_card.dart';
import '../../widgets/common/clinical_button.dart';
import '../../state/mock_app_state.dart';
import '../elderly/my_medicines_screen.dart';
import '../elderly/health_trends_screen.dart';

class KamalaOverviewScreen extends StatelessWidget {
  const KamalaOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = MockAppState();
    final profile = state.elderlyProfile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(profile.name),
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
              // Senior Telemetry Header Card
              ClinicalCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2.5),
                        image: const DecorationImage(
                          image: AssetImage(AppAssets.avatarKamala),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textNavy,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Age 72 • Mother • Code: ${profile.linkingCode}",
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.successGreen,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                "Live Stream • Synced 2m ago",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.successGreen,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Live Biometrics
              Text(
                "Current Biometrics",
                style: AppTypography.labelLg.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: ClinicalCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 18),
                              SizedBox(width: 6),
                              Text("Heart Rate", style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "${state.heartRate.value} BPM",
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textNavy),
                          ),
                          const Text("Normal & Regular", style: TextStyle(fontSize: 11, color: AppColors.successGreen, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClinicalCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.air_rounded, color: Color(0xFF00838F), size: 18),
                              SizedBox(width: 6),
                              Text("Blood SpO₂", style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "${state.spO2.value}%",
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textNavy),
                          ),
                          const Text("Optimal Saturation", style: TextStyle(fontSize: 11, color: AppColors.successGreen, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Medication Summary Card
              ClinicalCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyMedicinesScreen()),
                  );
                },
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3E8FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.medication_rounded, color: Color(0xFF7C3AED)),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today's Medication: 2 of 4 Taken",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textNavy,
                            ),
                          ),
                          Text(
                            "Next: Calcium & Vit D3 (01:00 PM)",
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Health Trends Card
              ClinicalCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HealthTrendsScreen()),
                  );
                },
                padding: const EdgeInsets.all(18),
                child: const Row(
                  children: [
                    Icon(Icons.show_chart_rounded, color: AppColors.primary, size: 28),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "7-Day Health Trend Analysis",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textNavy,
                            ),
                          ),
                          Text(
                            "Review resting pulse patterns & circadian shifts",
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              ClinicalButton(
                text: "Call Kamala Directly",
                leading: const Icon(Icons.call_rounded, color: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Calling Kamala Perera (+94 77 123 4567)..."),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
