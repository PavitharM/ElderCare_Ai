import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common/clinical_card.dart';
import '../../state/mock_app_state.dart';
import '../../models/emergency_event.dart';
import 'fall_event_details_screen.dart';

class EmergencyAlertsLogScreen extends StatefulWidget {
  const EmergencyAlertsLogScreen({super.key});

  @override
  State<EmergencyAlertsLogScreen> createState() => _EmergencyAlertsLogScreenState();
}

class _EmergencyAlertsLogScreenState extends State<EmergencyAlertsLogScreen> {
  String _selectedFilter = "All Alerts";

  @override
  Widget build(BuildContext context) {
    final state = MockAppState();
    final events = state.emergencyEvents;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Emergency Alerts"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: ["All Alerts", "Critical", "Warnings", "Resolved"].map((f) {
                  final isSelected = _selectedFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedFilter = f),
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textDark,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.borderLight,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Events List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: events.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final ev = events[index];
                  final isCritical = ev.severity == EventSeverity.critical;
                  final isWarning = ev.severity == EventSeverity.warning;

                  Color badgeColor = isCritical
                      ? AppColors.emergencyRed
                      : (isWarning ? AppColors.warningAmber : AppColors.primary);
                  Color softBg = isCritical
                      ? AppColors.emergencySoftBg
                      : (isWarning ? AppColors.warningSoftBg : AppColors.primaryLight);

                  return ClinicalCard(
                    onTap: isCritical
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FallEventDetailsScreen(),
                              ),
                            );
                          }
                        : null,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: softBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isCritical
                                    ? "CRITICAL"
                                    : (isWarning ? "WARNING" : "TELEMETRY INFO"),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: badgeColor,
                                ),
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.check_circle_outline_rounded,
                                size: 14, color: AppColors.successGreen),
                            const SizedBox(width: 4),
                            const Text(
                              "Resolved",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.successGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          ev.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textNavy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ev.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textBody,
                            height: 1.35,
                          ),
                        ),
                        const Divider(height: 20, color: AppColors.borderLight),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 14, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  ev.location,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (isCritical)
                              const Row(
                                children: [
                                  Text(
                                    "View Telemetry",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Icon(Icons.chevron_right_rounded,
                                      size: 16, color: AppColors.primary),
                                ],
                              ),
                          ],
                        ),
                      ],
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
