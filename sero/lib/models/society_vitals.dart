class SocietyVitals {
  final int parcelsPending;
  final int guardsOnDuty;
  final String activeMaintenance;
  final String systemStatus;
  final DateTime lastUpdate;

  SocietyVitals({
    required this.parcelsPending,
    required this.guardsOnDuty,
    required this.activeMaintenance,
    required this.systemStatus,
    required this.lastUpdate,
  });

  factory SocietyVitals.fromMap(Map<String, dynamic> map) {
    return SocietyVitals(
      parcelsPending: (map['parcelsPending'] as num?)?.toInt() ?? 0,
      guardsOnDuty: (map['guardsOnDuty'] as num?)?.toInt() ?? 0,
      activeMaintenance: map['activeMaintenance']?.toString() ?? "None",
      systemStatus: map['systemStatus']?.toString() ?? "Stable",
      lastUpdate: DateTime.tryParse(map['lastUpdate']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'parcelsPending': parcelsPending,
      'guardsOnDuty': guardsOnDuty,
      'activeMaintenance': activeMaintenance,
      'systemStatus': systemStatus,
      'lastUpdate': lastUpdate.toIso8601String(),
    };
  }
}


