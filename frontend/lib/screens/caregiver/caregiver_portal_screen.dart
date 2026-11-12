import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/common/clinical_card.dart';
import '../../widgets/common/floating_pill_nav.dart';
import '../gallery/screen_catalog_sheet.dart';
import 'kamala_overview_screen.dart';
import 'linked_elderly_profiles_screen.dart';
import 'caregiver_profile_screen.dart';
import '../elderly/health_trends_screen.dart';
import '../elderly/my_medicines_screen.dart';
import '../emergency/emergency_alerts_log_screen.dart';

class CaregiverPortalScreen extends StatefulWidget {
  const CaregiverPortalScreen({super.key});

  @override
  State<CaregiverPortalScreen> createState() => _CaregiverPortalScreenState();
}

class _CaregiverPortalScreenState extends State<CaregiverPortalScreen> {
  int _navIndex = 0;

  void _onNavTap(int index) {
    setState(() => _navIndex = index);
    if (index == 0) return;
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LinkedElderlyProfilesScreen()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EmergencyAlertsLogScreen()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CaregiverProfileScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Caregiver Header Bar
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        // Nimal Avatar
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 2),
                            image: const DecorationImage(
                              image: AssetImage(AppAssets.avatarNimal),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Good Morning,",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                "Nimal!",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textNavy,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Screen Catalog Launcher
                        IconButton(
                          icon: const Icon(Icons.grid_view_rounded, color: AppColors.primary),
                          tooltip: "View All 26 Screens",
                          onPressed: () => ScreenCatalogSheet.show(context),
                        ),
                        // Alerts Notification Bell
                        IconButton(
                          icon: Stack(
                            children: [
                              const Icon(Icons.notifications_rounded,
                                  color: AppColors.textDark, size: 26),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 9,
                                  height: 9,
                                  decoration: const BoxDecoration(
                                    color: AppColors.emergencyRed,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EmergencyAlertsLogScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Hero Illustration Banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE0F2F1), Color(0xFFE8F5E9)],
                      ),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    "LIVE TELEMETRY ACTIVE",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "All Family Members Safe",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textNavy,
                                  ),
                                ),
                                const Text(
                                  "Continuous IoT BLE stream active",
                                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.health_and_safety_rounded,
                            size: 52,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Monitored Senior Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: ClinicalCard(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const KamalaOverviewScreen(),
                        ),
                      );
                    },
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.successGreen, width: 2),
                            image: const DecorationImage(
                              image: AssetImage(AppAssets.avatarKamala),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Currently Monitoring",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Kamala Perera",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textNavy,
                                ),
                              ),
                              Text(
                                "Age 72 • Mother • Living Room",
                                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.successSoftBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  size: 14, color: AppColors.successGreen),
                              SizedBox(width: 4),
                              Text(
                                "Normal",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.successGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2x2 Telemetry Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    children: [
                      _buildMetricTile(
                        icon: Icons.favorite_rounded,
                        color: const Color(0xFFEF4444),
                        value: "74 BPM",
                        label: "Heart Rate",
                      ),
                      _buildMetricTile(
                        icon: Icons.air_rounded,
                        color: const Color(0xFF00838F),
                        value: "98%",
                        label: "SpO₂ Oxygen",
                      ),
                      _buildMetricTile(
                        icon: Icons.personal_injury_rounded,
                        color: const Color(0xFF7C3AED),
                        value: "Armed",
                        label: "Fall Detection",
                      ),
                      _buildMetricTile(
                        icon: Icons.thermostat_rounded,
                        color: const Color(0xFFF59E0B),
                        value: "36.6 °C",
                        label: "Skin Temp",
                      ),
                    ],
                  ),
                ),

                // Quick Actions Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                  child: Text(
                    "Quick Caregiver Actions",
                    style: AppTypography.labelLg.copyWith(fontSize: 16),
                  ),
                ),

                // Quick Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      ClinicalCard(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Calling Mother Kamala Perera (+94 77 123 4567)..."),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: const Row(
                          children: [
                            Icon(Icons.phone_in_talk_rounded, color: AppColors.successGreen, size: 22),
                            SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                "Call Mother (Direct Voice)",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textNavy,
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClinicalCard(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MyMedicinesScreen()),
                          );
                        },
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: const Row(
                          children: [
                            Icon(Icons.medication_rounded, color: AppColors.primary, size: 22),
                            SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                "Check Medicine Schedule",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textNavy,
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClinicalCard(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const HealthTrendsScreen()),
                          );
                        },
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: const Row(
                          children: [
                            Icon(Icons.show_chart_rounded, color: Color(0xFF7C3AED), size: 22),
                            SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                "Weekly Health Trends",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textNavy,
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),

          // Bottom Floating Pill Navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingPillNavBar(
              currentIndex: _navIndex,
              onTap: _onNavTap,
              items: const [
                FloatingPillNavItem(icon: Icons.home_rounded, label: "Home"),
                FloatingPillNavItem(icon: Icons.people_rounded, label: "Profiles"),
                FloatingPillNavItem(icon: Icons.notifications_rounded, label: "Alerts"),
                FloatingPillNavItem(icon: Icons.person_rounded, label: "Profile"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return ClinicalCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textNavy,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
