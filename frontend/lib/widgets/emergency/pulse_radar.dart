import 'package:flutter/material.dart';

class PulseRadar extends StatefulWidget {
  final double size;
  final Color pulseColor;
  final Widget? centerWidget;
  final int ringCount;

  const PulseRadar({
    super.key,
    this.size = 220,
    this.pulseColor = const Color(0xFF00838F),
    this.centerWidget,
    this.ringCount = 3,
  });

  @override
  State<PulseRadar> createState() => _PulseRadarState();
}

class _PulseRadarState extends State<PulseRadar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: List.generate(widget.ringCount, (i) {
                  final progress = (_controller.value + (i / widget.ringCount)) % 1.0;
                  final currentRadius = (widget.size / 2) * progress;
                  final opacity = (1.0 - progress).clamp(0.0, 1.0) * 0.45;

                  return Container(
                    width: currentRadius * 2,
                    height: currentRadius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.pulseColor.withValues(alpha: opacity),
                        width: 2.0,
                      ),
                      color: widget.pulseColor.withValues(alpha: opacity * 0.2),
                    ),
                  );
                }),
              );
            },
          ),
          if (widget.centerWidget != null) widget.centerWidget!,
        ],
      ),
    );
  }
}
