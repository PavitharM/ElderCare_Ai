import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common/clinical_card.dart';

class HealthHistoryScreen extends StatefulWidget {
  const HealthHistoryScreen({super.key});

  @override
  State<HealthHistoryScreen> createState() => _HealthHistoryScreenState();
}

class _HealthHistoryScreenState extends State<HealthHistoryScreen> {
  String _selectedFilter = "All Logs";

  final List<String> _filters = ["All Logs", "Heart Rate", "SpO₂", "Alerts"];

  final List<Map<String, dynamic>> _historyItems = [
    {
      "time": "Today, 10:30 AM",
      "vital": "Heart Rate",
      "value": "74 BPM",
      "status": "Normal",
      "statusColor": AppColors.successGreen,
      "icon": Icons.favorite_rounded,
      "iconColor": Color(0xFFEF4444),
      "detail": "Resting pulse sampled by ElderGuard Band V2",
    },
    {
      "time": "Today, 08:30 AM",
      "vital": "Blood Oxygen (SpO₂)",
      "value": "98%",
      "status": "Optimal",
      "statusColor": AppColors.successGreen,
      "icon": Icons.air_rounded,
      "iconColor": Color(0xFF00838F),
      "detail": "Early morning pulse oximeter reading",
    },
    {
      "time": "Today, 08:00 AM",
      "vital": "Medicine Taken",
      "value": "Metformin 500mg",
      "status": "Completed",
      "statusColor": AppColors.successGreen,
      "icon": Icons.check_circle_rounded,
      "iconColor": AppColors.successGreen,
      "detail": "Confirmed by Kamala (Elderly Portal)",
    },
    {
      "time": "Yesterday, 07:15 PM",
      "vital": "Skin Temperature",
      "value": "36.6 °C",
      "status": "Healthy",
      "statusColor": AppColors.successGreen,
      "icon": Icons.thermostat_rounded,
      "iconColor": Color(0xFFF59E0B),
      "detail": "Normal baseline temperature recorded",
    },
    {
      "time": "Yesterday, 02:40 PM",
      "vital": "Sudden Movement",
      "value": "2.1G Deceleration",
      "status": "Logged",
      "statusColor": Color(0xFF64748B),
      "icon": Icons.personal_injury_rounded,
      "iconColor": Color(0xFF7C3AED),
      "detail": "Assessed by AI: Fast sitting motion (No fall)",
    },
    {
      "time": "24 Oct 2026, 09:12 AM",
      "vital": "Heart Rate Spike",
      "value": "104 BPM",
      "status": "Warning",
      "statusColor": AppColors.warningAmber,
      "icon": Icons.warning_rounded,
      "iconColor": AppColors.warningAmber,
      "detail": "Brief elevated pulse during brisk garden walk",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Health History"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
            tooltip: "Export PDF",
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Health history PDF exported successfully for Dr. Anura Wijesinghe."),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: _filters.map((f) {
                  final isSelected = _selectedFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedFilter = f),
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textDark,
                      ),
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.borderLight,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Timeline List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: _historyItems.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = _historyItems[index];
                  return ClinicalCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: (item["iconColor"] as Color).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            item["icon"] as IconData,
                            color: item["iconColor"] as Color,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item["vital"] as String,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textNavy,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (item["statusColor"] as Color).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item["status"] as String,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: item["statusColor"] as Color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item["value"] as String,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textNavy,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item["detail"] as String,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.access_time_rounded,
                                      size: 12, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    item["time"] as String,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
