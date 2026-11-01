import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/common/clinical_button.dart';
import '../../widgets/common/step_progress_bar.dart';
import '../../widgets/common/clinical_card.dart';
import 'elderly_reg_step3_screen.dart';

class ElderlyRegStep2Screen extends StatefulWidget {
  const ElderlyRegStep2Screen({super.key});

  @override
  State<ElderlyRegStep2Screen> createState() => _ElderlyRegStep2ScreenState();
}

class _ElderlyRegStep2ScreenState extends State<ElderlyRegStep2Screen> {
  final Set<String> _selectedConditions = {
    "Hypertension",
    "Type 2 Diabetes",
    "Arthritis",
  };

  final List<String> _allConditions = [
    "Hypertension",
    "Type 2 Diabetes",
    "Arthritis",
    "Asthma",
    "High Cholesterol",
    "Osteoporosis",
    "Heart Disease",
  ];

  final List<String> _allergies = ["Penicillin", "Sulfa Drugs"];
  final List<String> _medications = ["Metformin 500mg", "Amlodipine 5mg"];
  final _doctorController = TextEditingController(text: "Dr. Anura Wijesinghe (General Hospital)");

  @override
  void dispose() {
    _doctorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Medical Profile"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step Indicator (Step 2 of 3)
            const StepProgressBar(currentStep: 2),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Medical History & Needs",
                      style: AppTypography.headlineLg.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Helps our AI personalize vital thresholds and alert family immediately.",
                      style: AppTypography.bodyMd.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 20),

                    // Chronic Conditions Section
                    Text(
                      "Chronic Conditions",
                      style: AppTypography.labelLg.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allConditions.map((cond) {
                        final isSelected = _selectedConditions.contains(cond);
                        return FilterChip(
                          label: Text(cond),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedConditions.add(cond);
                              } else {
                                _selectedConditions.remove(cond);
                              }
                            });
                          },
                          labelStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textDark,
                          ),
                          backgroundColor: Colors.white,
                          selectedColor: AppColors.primary,
                          checkmarkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.borderLight,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Known Allergies Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Known Allergies",
                          style: AppTypography.labelLg.copyWith(fontSize: 16),
                        ),
                        TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
                          label: const Text(
                            "Add",
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: _allergies.map((allergy) {
                        return Chip(
                          label: Text(allergy),
                          avatar: const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.emergencyRed),
                          backgroundColor: AppColors.emergencySoftBg,
                          labelStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.emergencyRedDark,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Color(0xFFFFCDD2)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Daily Medications
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Daily Medications",
                          style: AppTypography.labelLg.copyWith(fontSize: 16),
                        ),
                        TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
                          label: const Text(
                            "Add",
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ..._medications.map((med) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ClinicalCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.medication_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  med,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textNavy,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.successGreen,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),

                    // Primary Physician
                    Text(
                      "Primary Care Physician",
                      style: AppTypography.labelLg.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    ClinicalCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.medical_services_rounded,
                              color: AppColors.textDark,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Doctor & Hospital",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                TextField(
                                  controller: _doctorController,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textNavy,
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    border: InputBorder.none,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Continue Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: ClinicalButton(
                text: "Next",
                showChevron: true,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ElderlyRegStep3Screen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
