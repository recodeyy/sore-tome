class InterestProfile {
  final String userId;
  final String userName;
  final String flatNumber;
  final List<String> interests;
  final String bio;
  final String? profileImageUrl;

  InterestProfile({
    required this.userId,
    required this.userName,
    required this.flatNumber,
    required this.interests,
    required this.bio,
    this.profileImageUrl,
  });

  factory InterestProfile.fromMap(Map<String, dynamic> map, String userId) {
    return InterestProfile(
      userId: userId,
      userName: map['userName'] ?? 'Resident',
      flatNumber: map['flatNumber'] ?? '...',
      interests: List<String>.from(map['interests'] ?? []),
      bio: map['bio'] ?? '',
      profileImageUrl: map['profileImageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'flatNumber': flatNumber,
      'interests': interests,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
    };
  }
}
