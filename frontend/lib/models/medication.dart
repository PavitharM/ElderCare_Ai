class MedicationItem {
  final String id;
  final String name;
  final String dosage;
  final String time;
  final String schedulePeriod; // Morning, Afternoon, Evening
  final String instruction; // e.g. "After food"
  bool isTaken;

  MedicationItem({
    required this.id,
    required this.name,
    required this.dosage,
    required this.time,
    required this.schedulePeriod,
    required this.instruction,
    this.isTaken = false,
  });
}
