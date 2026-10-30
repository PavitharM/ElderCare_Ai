import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/common/clinical_card.dart';
import 'emergency_alert_sent_screen.dart';

class EmergencySosConfirmScreen extends StatefulWidget {
  const EmergencySosConfirmScreen({super.key});

  @override
  State<EmergencySosConfirmScreen> createState() => _EmergencySosConfirmScreenState();
}

class _EmergencySosConfirmScreenState extends State<EmergencySosConfirmScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _holdController;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const EmergencyAlertSentScreen(isFallEvent: false),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _holdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F5),
      appBar: AppBar(
        title: const Text("Emergency SOS"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Text(
                "Hold to Confirm SOS",
                style: AppTypography.headlineLg.copyWith(
                  color: AppColors.textNavy,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Press and hold the SOS button for 3 seconds to prevent accidental triggers.",
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(color: AppColors.textMuted),
              ),

              const Spacer(),

              // Hold-to-Confirm Interactive Button
              Center(
                child: GestureDetector(
                  onTapDown: (_) => _holdController.forward(),
                  onTapUp: (_) => _holdController.reverse(),
                  onTapCancel: () => _holdController.reverse(),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Progress Ring
                      SizedBox(
                        width: 210,
                        height: 210,
                        child: AnimatedBuilder(
                          animation: _holdController,
                          builder: (context, _) => CircularProgressIndicator(
                            value: _holdController.value,
                            strokeWidth: 8,
                            backgroundColor: const Color(0xFFFFCDD2),
                            color: AppColors.emergencyRed,
                          ),
                        ),
                      ),
                      // SOS Big Button
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.emergencyRed.withValues(alpha: 0.4),
                              blurRadius: 28,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.crisis_alert_rounded, color: Colors.white, size: 50),
                            SizedBox(height: 4),
                            Text(
                              "HOLD SOS",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              "3 Seconds",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Who will be notified card
              ClinicalCard(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(18),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Immediate Responders",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textNavy,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.contact_phone_rounded, size: 18, color: AppColors.primary),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Nimal Perera (Son) • +94 71 987 6543",
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.local_hospital_rounded, size: 18, color: AppColors.emergencyRed),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Emergency Ambulance Dispatch 1990",
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Instant Trigger Option
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EmergencyAlertSentScreen(isFallEvent: false),
                    ),
                  );
                },
                child: const Text(
                  "Tap here to bypass hold and trigger immediately",
                  style: TextStyle(
                    color: AppColors.emergencyRed,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
