import 'package:cloud_firestore/cloud_firestore.dart';

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
      parcelsPending: map['parcelsPending'] ?? 0,
      guardsOnDuty: map['guardsOnDuty'] ?? 0,
      activeMaintenance: map['activeMaintenance'] ?? "None",
      systemStatus: map['systemStatus'] ?? "Stable",
      lastUpdate: (map['lastUpdate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'parcelsPending': parcelsPending,
      'guardsOnDuty': guardsOnDuty,
      'activeMaintenance': activeMaintenance,
      'systemStatus': systemStatus,
      'lastUpdate': Timestamp.fromDate(lastUpdate),
    };
  }
}


