import 'package:flutter/material.dart';

enum MetricStatus { optimal, normal, warning, critical }

class VitalReading {
  final String label;
  final String value;
  final String unit;
  final String statusText;
  final MetricStatus status;
  final IconData icon;
  final Color tintColor;
  final String normalRange;
  final List<double> history7Days;

  const VitalReading({
    required this.label,
    required this.value,
    required this.unit,
    required this.statusText,
    required this.status,
    required this.icon,
    required this.tintColor,
    required this.normalRange,
    required this.history7Days,
  });
}
