enum EventSeverity { critical, high, warning, info }

class EmergencyEvent {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final EventSeverity severity;
  final String location;
  final double? impactForceG;
  final bool resolved;

  EmergencyEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.severity,
    required this.location,
    this.impactForceG,
    this.resolved = false,
  });
}
