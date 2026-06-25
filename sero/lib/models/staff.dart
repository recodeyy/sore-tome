class Staff {
  final String id;
  final String name;
  final String role; // e.g. maid, driver, plumber
  final String phone;
  final bool isInside;
  final List<String> workingFlats;

  Staff({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    required this.isInside,
    required this.workingFlats,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      role: json['role'] ?? 'staff',
      phone: json['phone'] ?? '',
      isInside: json['isInside'] ?? false,
      workingFlats: List<String>.from(json['workingFlats'] ?? []),
    );
  }
}
