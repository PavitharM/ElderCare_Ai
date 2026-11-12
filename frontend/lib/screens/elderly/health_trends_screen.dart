import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common/clinical_card.dart';
import 'health_history_screen.dart';

class HealthTrendsScreen extends StatefulWidget {
  const HealthTrendsScreen({super.key});

  @override
  State<HealthTrendsScreen> createState() => _HealthTrendsScreenState();
}

class _HealthTrendsScreenState extends State<HealthTrendsScreen> {
  int _selectedTab = 0; // 0: Heart Rate, 1: SpO2, 2: Temp

  final List<String> _tabs = ["Heart Rate", "SpO₂", "Temperature"];
  final List<String> _days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Health Trends"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.primary),
            tooltip: "History Log",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HealthHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Segmented Filter Tabs
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: List.generate(_tabs.length, (index) {
                    final isSelected = _selectedTab == index;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            _tabs[index],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppColors.textNavy : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 20),

              // Main Trend Chart Card
              ClinicalCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedTab == 0
                                  ? "74 BPM"
                                  : (_selectedTab == 1 ? "98%" : "36.6 °C"),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textNavy,
                              ),
                            ),
                            Text(
                              "7-Day Average",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.successSoftBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.trending_flat_rounded, size: 16, color: AppColors.successGreen),
                              SizedBox(width: 4),
                              Text(
                                "Stable",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.successGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Custom Trend Bar Chart
                    SizedBox(
                      height: 160,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(_days.length, (i) {
                          final values = _selectedTab == 0
                              ? [72, 75, 78, 71, 74, 76, 74]
                              : (_selectedTab == 1
                                  ? [98, 97, 98, 99, 98, 98, 98]
                                  : [36.5, 36.6, 36.7, 36.6, 36.4, 36.6, 36.6]);
                          final maxVal = _selectedTab == 0 ? 90.0 : (_selectedTab == 1 ? 100.0 : 38.0);
                          final minVal = _selectedTab == 0 ? 60.0 : (_selectedTab == 1 ? 90.0 : 35.0);
                          final normalized = ((values[i] - minVal) / (maxVal - minVal)).clamp(0.2, 0.95);

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                "${values[i]}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textNavy,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: 28,
                                height: 110 * normalized,
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _days[i],
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Summary Stats Grid
              Row(
                children: [
                  Expanded(
                    child: ClinicalCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Lowest Recorded",
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedTab == 0 ? "68 BPM" : (_selectedTab == 1 ? "97%" : "36.4 °C"),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textNavy,
                            ),
                          ),
                          const Text(
                            "During sleep (03:15 AM)",
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClinicalCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Highest Recorded",
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedTab == 0 ? "82 BPM" : (_selectedTab == 1 ? "99%" : "36.8 °C"),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textNavy,
                            ),
                          ),
                          const Text(
                            "Morning walk (07:45 AM)",
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Medical Observation
              ClinicalCard(
                padding: const EdgeInsets.all(18),
                backgroundColor: const Color(0xFFF8FAFC),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notes_rounded, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Physician & AI Telemetry Note",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textNavy,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Circadian telemetry shows normal resting heart rate patterns with expected nocturnal dip. No signs of sudden bradycardia or tachycardia episodes this week.",
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textBody,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Navigate to Full History
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HealthHistoryScreen()),
                    );
                  },
                  icon: const Icon(Icons.history_rounded, size: 18),
                  label: const Text("View Full Health History & Logs"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
}
