import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/common/clinical_card.dart';
import 'emergency_alert_sent_screen.dart';
import 'fall_event_details_screen.dart';

class FallDetectedCountdownScreen extends StatefulWidget {
  const FallDetectedCountdownScreen({super.key});

  @override
  State<FallDetectedCountdownScreen> createState() => _FallDetectedCountdownScreenState();
}

class _FallDetectedCountdownScreenState extends State<FallDetectedCountdownScreen>
    with SingleTickerProviderStateMixin {
  int _secondsRemaining = 25;
  Timer? _countdownTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        _triggerEmergencyAlert();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerEmergencyAlert() {
    _countdownTimer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const EmergencyAlertSentScreen(isFallEvent: true),
      ),
    );
  }

  void _cancelAlert() {
    _countdownTimer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 28),
            SizedBox(width: 10),
            Text("Alert Cancelled", style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Text(
          "We're glad you are okay! Your family caregivers were not alarmed and the false alarm was logged safely.",
          style: TextStyle(fontSize: 14, color: AppColors.textBody, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text("Return to Dashboard"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _secondsRemaining / 25.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F5),
      appBar: AppBar(
        title: const Text("Fall Detection Alert"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.emergencyRed.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.emergencyRed.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, size: 8, color: AppColors.emergencyRed),
                SizedBox(width: 6),
                Text(
                  "CRITICAL",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.emergencyRed,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            children: [
              const Spacer(),

              // Circular Countdown Visual
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pulsing Outer Rings
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) => Container(
                        width: 220 + (_pulseController.value * 20),
                        height: 220 + (_pulseController.value * 20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.emergencyRed.withValues(
                            alpha: (1.0 - _pulseController.value) * 0.2,
                          ),
                        ),
                      ),
                    ),
                    // Progress Track
                    SizedBox(
                      width: 170,
                      height: 170,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 10,
                        backgroundColor: const Color(0xFFFFCDD2),
                        color: AppColors.emergencyRed,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    // Center Time
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "$_secondsRemaining",
                          style: const TextStyle(
                            fontSize: 54,
                            fontWeight: FontWeight.w900,
                            color: AppColors.emergencyRed,
                            letterSpacing: -2,
                          ),
                        ),
                        const Text(
                          "SECONDS",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                "Fall Detected!",
                style: AppTypography.display.copyWith(
                  color: AppColors.textNavy,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Sending automatic emergency alert to caregivers and emergency contacts in ${_secondsRemaining}s.",
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(color: AppColors.textMuted),
              ),

              const SizedBox(height: 20),

              // Telemetry Subcard (Tappable for details)
              ClinicalCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FallEventDetailsScreen(),
                    ),
                  );
                },
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.contact_emergency_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Primary Responder: Nimal (Son)",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textNavy,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Living Room (2.8G Impact) • View Details",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  ],
                ),
              ),

              const Spacer(),

              // MASSIVE SAFE BUTTON: "I AM OK"
              Container(
                height: 68,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF007F8F), Color(0xFF008F91), Color(0xFF01A798)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00838F).withValues(alpha: 0.35),
                      offset: const Offset(0, 6),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: _cancelAlert,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.white, size: 30),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "I AM OK",
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                Text(
                                  "Tap to cancel alarm immediately",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: Colors.white, size: 28),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // SEND ALERT NOW BUTTON
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _triggerEmergencyAlert,
                  icon: const Icon(Icons.emergency_rounded, size: 22),
                  label: const Text(
                    "SEND ALERT NOW (Immediate)",
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emergencyRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
