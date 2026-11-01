import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/common/clinical_card.dart';

class MedicationAdherenceScreen extends StatelessWidget {
  const MedicationAdherenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Medication Adherence"),
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
              // Main Circular Score Card
              ClinicalCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 140,
                          height: 140,
                          child: CircularProgressIndicator(
                            value: 0.94,
                            strokeWidth: 12,
                            backgroundColor: const Color(0xFFE2E8F0),
                            color: AppColors.primary,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "94%",
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textNavy,
                                letterSpacing: -1,
                              ),
                            ),
                            Text(
                              "Weekly Score",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Excellent Adherence!",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Kamala has consistently taken 26 out of 28 scheduled doses on time this week.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 7-Day Streak Calendar
              Text(
                "7-Day Streak Calendar",
                style: AppTypography.labelLg.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 10),
              ClinicalCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(days.length, (i) {
                    final isComplete = i != 3; // Thu has delayed dose
                    return Column(
                      children: [
                        Text(
                          days[i],
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isComplete
                                ? AppColors.successSoftBg
                                : AppColors.warningSoftBg,
                            border: Border.all(
                              color: isComplete
                                  ? AppColors.successGreen
                                  : AppColors.warningAmber,
                            ),
                          ),
                          child: Icon(
                            isComplete ? Icons.check_rounded : Icons.schedule_rounded,
                            size: 20,
                            color: isComplete
                                ? AppColors.successGreen
                                : AppColors.warningAmber,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),

              const SizedBox(height: 20),

              // Breakdown Stats
              Row(
                children: [
                  Expanded(
                    child: ClinicalCard(
                      padding: const EdgeInsets.all(16),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Taken on Time", style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          SizedBox(height: 4),
                          Text(
                            "26 Doses",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.successGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClinicalCard(
                      padding: const EdgeInsets.all(16),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Missed Doses", style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          SizedBox(height: 4),
                          Text(
                            "0 Missed",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Caregiver Sync Alert Notice
              ClinicalCard(
                backgroundColor: const Color(0xFFF8FAFC),
                padding: const EdgeInsets.all(16),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: AppColors.primary, size: 24),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        "Caregiver Nimal Perera receives an automatic SMS alert if a critical dose is overdue by more than 30 minutes.",
                        style: TextStyle(fontSize: 13, color: AppColors.textBody, height: 1.35),
                      ),
                    ),
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
}
