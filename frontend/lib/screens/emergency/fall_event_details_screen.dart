import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common/clinical_card.dart';
import '../../widgets/common/clinical_button.dart';

class FallEventDetailsScreen extends StatelessWidget {
  const FallEventDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Fall Incident Details"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 3D Pixar Fall Illustration Card
              Container(
                height: 190,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  image: const DecorationImage(
                    image: AssetImage(AppAssets.illustrationFall),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Severity & Timestamp
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.emergencySoftBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_rounded, color: AppColors.emergencyRed, size: 16),
                        SizedBox(width: 6),
                        Text(
                          "HIGH IMPACT DETECTED (2.8G)",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.emergencyRedDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    "Today, 10:14 AM",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Sensor Telemetry Card
              ClinicalCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "IoT Biometric & Motion Telemetry",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textNavy,
                      ),
                    ),
                    const Divider(height: 20, color: AppColors.borderLight),
                    _buildDataRow("Peak Impact Force", "2.8 G-force (Threshold > 2.5G)"),
                    _buildDataRow("Deceleration Duration", "0.12 seconds"),
                    _buildDataRow("Post-Impact Motion", "Stationary / Floor Level (18s)"),
                    _buildDataRow("Detection Hardware", "ElderGuard Wearable + Optical Radar"),
                    _buildDataRow("Indoor Location", "Living Room (Ground Floor)"),
                    _buildDataRow("GPS Position", "6.9271° N, 79.8612° E (Colombo 03)"),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Responder Status
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
                      child: const Icon(Icons.check_circle_rounded, color: AppColors.successGreen),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Caregiver Notified",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textNavy,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Emergency SMS and app alert sent to Nimal Perera (+94 71 987 6543).",
                            style: TextStyle(fontSize: 12, color: Color(0xFF166534)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              ClinicalButton(
                text: "Call Caregiver (Nimal)",
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
              const SizedBox(height: 10),
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
                  icon: const Icon(Icons.local_hospital_rounded, size: 20),
                  label: const Text(
                    "Dial 1990 Emergency Ambulance",
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textNavy,
            ),
          ),
        ],
      ),
    );
  }
}
