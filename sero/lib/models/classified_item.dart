class ClassifiedItem {
  final String id;
  final String title;
  final String description;
  final double price;
  final String category; // 'Furniture', 'Electronics', 'Others'
  final String sellerId;
  final String sellerName;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isSold;

  ClassifiedItem({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.sellerId,
    required this.sellerName,
    this.imageUrl,
    required this.createdAt,
    this.isSold = false,
  });

  factory ClassifiedItem.fromMap(Map<String, dynamic> map, String id) {
    return ClassifiedItem(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      category: map['category'] ?? 'Others',
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? 'Resident',
      imageUrl: map['imageUrl'],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      isSold: map['isSold'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'isSold': isSold,
    };
  }
}
