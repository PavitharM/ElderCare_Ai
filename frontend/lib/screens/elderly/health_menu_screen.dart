import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/common/clinical_card.dart';
import '../../state/mock_app_state.dart';
import '../gallery/screen_catalog_sheet.dart';
import 'hospital_qr_code_screen.dart';
import 'elderly_profile_screen.dart';
import '../wearable/my_wearable_screen.dart';
import '../emergency/emergency_sos_confirm_screen.dart';
import '../caregiver/caregiver_portal_screen.dart';

class HealthMenuScreen extends StatelessWidget {
  const HealthMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = MockAppState();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Menu & Settings"),
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
              // User Card
              ClinicalCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ElderlyProfileScreen()),
                  );
                },
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
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
                            state.elderlyProfile.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textNavy,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Age 72 • Blood ${state.elderlyProfile.bloodGroup}",
                            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "Code: ${state.elderlyProfile.linkingCode}",
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                "Health Services & Hardware",
                style: AppTypography.labelLg.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 12),

              _buildMenuTile(
                context,
                icon: Icons.qr_code_2_rounded,
                iconColor: AppColors.primary,
                title: "Hospital QR Code",
                subtitle: "Share emergency summary with triage doctors",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HospitalQrCodeScreen()),
                ),
              ),
              const SizedBox(height: 10),

              _buildMenuTile(
                context,
                icon: Icons.watch_rounded,
                iconColor: const Color(0xFF0D9488),
                title: "My Wearable",
                subtitle: "Check battery, signal and active sensors",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyWearableScreen()),
                ),
              ),
              const SizedBox(height: 10),

              _buildMenuTile(
                context,
                icon: Icons.person_rounded,
                iconColor: AppColors.textNavy,
                title: "My Profile",
                subtitle: "View personal details, contacts & medications",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ElderlyProfileScreen()),
                ),
              ),
              const SizedBox(height: 10),

              _buildMenuTile(
                context,
                icon: Icons.crisis_alert_rounded,
                iconColor: AppColors.emergencyRed,
                title: "Emergency SOS",
                subtitle: "Trigger immediate emergency assistance",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EmergencySosConfirmScreen()),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                "App Mode & Navigation",
                style: AppTypography.labelLg.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 12),

              // Switch to Caregiver Mode
              ClinicalCard(
                onTap: () {
                  state.setRole(AppUserRole.caregiver);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const CaregiverPortalScreen()),
                    (route) => false,
                  );
                },
                backgroundColor: const Color(0xFFF0FDF4),
                borderColor: const Color(0xFFBBF7D0),
                padding: const EdgeInsets.all(16),
                child: const Row(
                  children: [
                    Icon(Icons.swap_horiz_rounded, color: AppColors.secondary, size: 28),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Switch to Caregiver Portal",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textNavy,
                            ),
                          ),
                          Text(
                            "View Nimal Perera's remote monitoring view",
                            style: TextStyle(fontSize: 12, color: Color(0xFF166534)),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.secondary),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Screens Catalog Launcher
              ClinicalCard(
                onTap: () => ScreenCatalogSheet.show(context),
                backgroundColor: const Color(0xFFFAF8FF),
                borderColor: const Color(0xFFE2E8F0),
                padding: const EdgeInsets.all(16),
                child: const Row(
                  children: [
                    Icon(Icons.grid_view_rounded, color: AppColors.primary, size: 26),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "All 26 Screens Catalog",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textNavy,
                            ),
                          ),
                          Text(
                            "Jump directly to any designed screen",
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ClinicalCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textNavy,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
