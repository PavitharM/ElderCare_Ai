import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common/clinical_card.dart';
import '../../state/mock_app_state.dart';
import '../elderly/health_dashboard_screen.dart';
import '../onboarding/welcome_registration_screen.dart';

class CaregiverProfileScreen extends StatefulWidget {
  const CaregiverProfileScreen({super.key});

  @override
  State<CaregiverProfileScreen> createState() => _CaregiverProfileScreenState();
}

class _CaregiverProfileScreenState extends State<CaregiverProfileScreen> {
  bool _fallSirenActive = true;
  bool _vitalsSpikeActive = true;
  bool _medReminderActive = true;

  @override
  Widget build(BuildContext context) {
    final state = MockAppState();
    final profile = state.caregiverProfile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Caregiver Profile"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              // Avatar & Profile Card
              ClinicalCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 3),
                            image: const DecorationImage(
                              image: AssetImage(AppAssets.avatarNimal),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.verified_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      profile.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textNavy,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      profile.relation,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "Monitoring 1 Active Senior (Kamala)",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Contact Info
              ClinicalCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Account & Alert Destination",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textNavy,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRow(Icons.email_rounded, "Email Address", profile.email),
                    const SizedBox(height: 10),
                    _buildRow(Icons.phone_rounded, "Alert Phone (SMS & Push)", profile.phone),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Notification Triggers
              ClinicalCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Emergency Notification Rules",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textNavy,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Fall Detection Siren Alert", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      subtitle: const Text("Overrides silent mode for sudden falls"),
                      value: _fallSirenActive,
                      activeThumbColor: AppColors.primary,
                      onChanged: (v) => setState(() => _fallSirenActive = v),
                    ),
                    const Divider(color: AppColors.borderLight, height: 1),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Critical Biometric Spikes", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      subtitle: const Text("Alert if pulse >100 or SpO2 <92%"),
                      value: _vitalsSpikeActive,
                      activeThumbColor: AppColors.primary,
                      onChanged: (v) => setState(() => _vitalsSpikeActive = v),
                    ),
                    const Divider(color: AppColors.borderLight, height: 1),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Overdue Medication Alerts", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      subtitle: const Text("Notify if dose is 30 mins late"),
                      value: _medReminderActive,
                      activeThumbColor: AppColors.primary,
                      onChanged: (v) => setState(() => _medReminderActive = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Switch to Senior Mode
              ClinicalCard(
                onTap: () {
                  state.setRole(AppUserRole.elderly);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HealthDashboardScreen()),
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
                            "Switch to Senior Mode",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textNavy,
                            ),
                          ),
                          Text(
                            "View app as elderly user Kamala Perera",
                            style: TextStyle(fontSize: 12, color: Color(0xFF166534)),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.secondary),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Sign Out Button
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WelcomeRegistrationScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout_rounded, color: AppColors.emergencyRed, size: 18),
                  label: const Text(
                    "Sign Out",
                    style: TextStyle(
                      color: AppColors.emergencyRed,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.textDark, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textNavy,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
