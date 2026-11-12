import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ClinicalCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback? onTap;
  final bool hasShadow;

  const ClinicalCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.borderRadius = 22,
    this.backgroundColor = AppColors.surface,
    this.borderColor = AppColors.borderLight,
    this.onTap,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                  offset: const Offset(0, 8),
                  blurRadius: 20,
                  spreadRadius: -4,
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: card,
        ),
      );
    }
    return card;
  }
}
