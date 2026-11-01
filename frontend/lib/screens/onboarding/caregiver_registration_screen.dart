import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/common/clinical_button.dart';
import '../../widgets/common/clinical_text_field.dart';
import '../../widgets/common/clinical_card.dart';
import '../../state/mock_app_state.dart';
import '../caregiver/caregiver_portal_screen.dart';

class CaregiverRegistrationScreen extends StatefulWidget {
  const CaregiverRegistrationScreen({super.key});

  @override
  State<CaregiverRegistrationScreen> createState() => _CaregiverRegistrationScreenState();
}

class _CaregiverRegistrationScreenState extends State<CaregiverRegistrationScreen> {
  final _nameController = TextEditingController(text: "Nimal Perera");
  final _emailController = TextEditingController(text: "nimal.perera@gmail.com");
  final _phoneController = TextEditingController(text: "+94 71 987 6543");
  final _passwordController = TextEditingController(text: "••••••••••••");
  final _codeController = TextEditingController(text: "EG-8829-KP");
  String _selectedRelation = "Son";

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Caregiver Registration"),
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
              Text(
                "Create Caregiver Account",
                style: AppTypography.headlineLg.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 4),
              Text(
                "Monitor vitals, receive real-time fall alerts, and track medication schedules.",
                style: AppTypography.bodyMd.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),

              // Full Name
              ClinicalTextField(
                label: "Full Name",
                hintText: "Enter your full name",
                controller: _nameController,
                icon: Icons.person_rounded,
              ),
              const SizedBox(height: 12),

              // Relationship Card
              ClinicalCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.family_restroom_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Relationship to Elderly",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedRelation,
                              isDense: true,
                              isExpanded: true,
                              items: ["Son", "Daughter", "Spouse", "Grandchild", "Nurse / Caregiver", "Other"].map((r) {
                                return DropdownMenuItem(
                                  value: r,
                                  child: Text(
                                    r,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textNavy,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedRelation = val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Email Address
              ClinicalTextField(
                label: "Email Address",
                hintText: "Enter your email",
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                icon: Icons.email_rounded,
              ),
              const SizedBox(height: 12),

              // Mobile Phone
              ClinicalTextField(
                label: "Mobile Phone (For Emergency Alerts)",
                hintText: "Enter phone number",
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                icon: Icons.phone_android_rounded,
              ),
              const SizedBox(height: 12),

              // Password
              ClinicalTextField(
                label: "Password",
                hintText: "Create a password",
                controller: _passwordController,
                obscureText: true,
                icon: Icons.lock_rounded,
              ),
              const SizedBox(height: 20),

              // Linking Code Card
              ClinicalCard(
                backgroundColor: const Color(0xFFF0FDF4),
                borderColor: const Color(0xFFBBF7D0),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.link_rounded, color: AppColors.secondary, size: 22),
                        SizedBox(width: 8),
                        Text(
                          "Link Monitored Elderly",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textNavy,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Enter the 9-character code from your elderly family member's app.",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _codeController,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: AppColors.primary,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: "e.g. EG-8829-KP",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.secondary),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.borderLight),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Submit Action
              ClinicalButton(
                text: "Create Account & Enter Portal",
                showChevron: true,
                onPressed: () {
                  MockAppState().setRole(AppUserRole.caregiver);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CaregiverPortalScreen(),
                    ),
                    (route) => false,
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
