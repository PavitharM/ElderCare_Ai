import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class StepProgressBar extends StatelessWidget {
  final int currentStep; // 1, 2, 3
  final int totalSteps;
  final List<String> stepLabels;

  const StepProgressBar({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
    this.stepLabels = const ["Personal", "Health", "Emergency"],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: List.generate(totalSteps * 2 - 1, (index) {
              if (index.isOdd) {
                // Connecting line
                final stepBefore = (index ~/ 2) + 1;
                final isPassed = currentStep > stepBefore;
                return Expanded(
                  child: Container(
                    height: 3,
                    color: isPassed ? AppColors.primary : const Color(0xFFCBD5E1),
                  ),
                );
              }

              final stepNum = (index ~/ 2) + 1;
              final isCompleted = currentStep > stepNum;
              final isActive = currentStep == stepNum;

              return Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? AppColors.primary
                      : (isActive ? AppColors.primaryLight : Colors.white),
                  border: Border.all(
                    color: (isCompleted || isActive)
                        ? AppColors.primary
                        : const Color(0xFFCBD5E1),
                    width: isActive ? 2.5 : 1.5,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                      : Text(
                          "$stepNum",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isActive ? AppColors.primary : AppColors.textMuted,
                          ),
                        ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(totalSteps, (index) {
              final stepNum = index + 1;
              final isActive = currentStep == stepNum;
              final isCompleted = currentStep > stepNum;
              return Text(
                stepLabels[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: (isActive || isCompleted)
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
