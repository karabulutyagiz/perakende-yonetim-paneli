class Product {
  Product({
    required this.id,
    required this.name,
    required this.unit,
    required this.price,
    required this.stock,
    this.description,
    this.imageUrl,
    this.categoryId,
    this.categoryName,
  });

  final String id;
  final String name;
  final String? description;
  final String unit;
  final double price;
  final double stock;
  final String? imageUrl;
  final String? categoryId;
  final String? categoryName;

  factory Product.fromJson(Map<String, dynamic> json) {
    final cat = json['category'] as Map<String, dynamic>?;
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      unit: json['unit'] as String,
      price: (json['price'] as num).toDouble(),
      stock: (json['stock'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      categoryId: cat?['id'] as String?,
      categoryName: cat?['name'] as String?,
    );
  }
}
