class SocietyEvent {
  final String id;
  final String title;
  final String description;
  final DateTime eventDate;
  final String location;

  SocietyEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.location,
  });

  factory SocietyEvent.fromMap(Map<String, dynamic> map) {
    return SocietyEvent(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      eventDate:
          DateTime.tryParse(map['eventDate'] ?? '') ?? DateTime.now(),
      location: map['location'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'eventDate': eventDate.toIso8601String(),
      'location': location,
    };
  }
}


