/// Safely parses a Firestore Timestamp, DateTime, ISO string, epoch int,
/// or API-serialized timestamp map ({_seconds: ...}) to DateTime.
DateTime parseTimestamp(dynamic v) {
  return parseTimestampNullable(v) ?? DateTime.now();
}

DateTime? parseTimestampNullable(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  // Firestore Timestamp has a toDate() method
  try {
    return (v as dynamic).toDate() as DateTime;
  } catch (_) {}
  // API-serialized Firestore Timestamp: {_seconds: ..., _nanoseconds: ...}
  if (v is Map) {
    final s = v['_seconds'] ?? v['seconds'];
    if (s is num) {
      return DateTime.fromMillisecondsSinceEpoch((s * 1000).toInt());
    }
  }
  if (v is num) {
    // Heuristic: values above year ~2128 in seconds are millis
    return DateTime.fromMillisecondsSinceEpoch(
        v > 5000000000 ? v.toInt() : (v * 1000).toInt());
  }
  return DateTime.tryParse(v.toString());
}
