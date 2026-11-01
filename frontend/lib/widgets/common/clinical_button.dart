import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ClinicalButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? leading;
  final Widget? trailing;
  final double height;
  final double borderRadius;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? textColor;
  final BorderSide? borderSide;
  final bool showChevron;
  final bool isGlow;

  const ClinicalButton({
    super.key,
    required this.text,
    this.onPressed,
    this.leading,
    this.trailing,
    this.height = 56,
    this.borderRadius = 16,
    this.gradient = AppColors.buttonGradient,
    this.backgroundColor,
    this.textColor = Colors.white,
    this.borderSide,
    this.showChevron = false,
    this.isGlow = true,
  });

  @override
  State<ClinicalButton> createState() => _ClinicalButtonState();
}

class _ClinicalButtonState extends State<ClinicalButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: widget.backgroundColor == null ? widget.gradient : null,
          color: widget.backgroundColor,
          border: widget.borderSide != null ? Border.fromBorderSide(widget.borderSide!) : null,
          boxShadow: widget.isGlow
              ? [
                  BoxShadow(
                    color: (widget.gradient != null
                            ? const Color(0xFF00838F)
                            : (widget.backgroundColor ?? Colors.black))
                        .withValues(alpha: 0.25),
                    offset: const Offset(0, 6),
                    blurRadius: 18,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            onTapDown: (_) => _controller.forward(),
            onTapUp: (_) => _controller.reverse(),
            onTapCancel: () => _controller.reverse(),
            onTap: widget.onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.leading != null) ...[
                    widget.leading!,
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Text(
                      widget.text,
                      textAlign: widget.leading != null ? TextAlign.left : TextAlign.center,
                      style: TextStyle(
                        color: widget.textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  if (widget.trailing != null) ...[
                    const SizedBox(width: 10),
                    widget.trailing!,
                  ] else if (widget.showChevron) ...[
                    const SizedBox(width: 10),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: widget.textColor,
                      size: 26,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
