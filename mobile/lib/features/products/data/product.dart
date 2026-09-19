/// Ürün kartında tanımlanan indirim tipi. `null` = indirim yok.
enum DiscountType {
  percent,
  amount;

  String get apiValue => name;

  static DiscountType? fromApi(String? raw) => switch (raw) {
        'percent' => DiscountType.percent,
        'amount' => DiscountType.amount,
        _ => null,
      };
}

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
    this.discountType,
    this.discountValue = 0,
    double? effectivePrice,
  }) : effectivePrice = effectivePrice ??
            computeEffectivePrice(price, discountType, discountValue);

  final String id;
  final String name;
  final String? description;
  final String unit;

  /// İndirimsiz liste fiyatı.
  final double price;
  final double stock;
  final String? imageUrl;
  final String? categoryId;
  final String? categoryName;

  final DiscountType? discountType;
  final double discountValue;

  /// Müşterinin ödediği fiyat — indirim düşülmüş hâli. Backend hesaplar,
  /// eski/eksik yanıtlarda yerelde hesaplanır.
  final double effectivePrice;

  bool get hasDiscount => discountType != null && effectivePrice < price;

  /// Satırda gösterilecek indirim rozeti: "%10" ya da "₺5 indirim".
  String? get discountLabel {
    if (!hasDiscount) return null;
    if (discountType == DiscountType.percent) {
      return '%${_trimZeros(discountValue)}';
    }
    return '${_trimZeros(discountValue)} ₺ indirim';
  }

  static String _trimZeros(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  /// Backend'deki `compute_effective_price` ile aynı kural.
  static double computeEffectivePrice(
    double price,
    DiscountType? type,
    double value,
  ) {
    if (type == null || value <= 0) return price;
    final discount = type == DiscountType.percent
        ? price * (value > 100 ? 100 : value) / 100
        : (value > price ? price : value);
    final effective = price - discount;
    return effective < 0 ? 0 : double.parse(effective.toStringAsFixed(2));
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final cat = json['category'] as Map<String, dynamic>?;
    final price = (json['price'] as num).toDouble();
    final discountType = DiscountType.fromApi(json['discount_type'] as String?);
    final discountValue = (json['discount_value'] as num?)?.toDouble() ?? 0;
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      unit: json['unit'] as String,
      price: price,
      stock: (json['stock'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      categoryId: cat?['id'] as String?,
      categoryName: cat?['name'] as String?,
      discountType: discountType,
      discountValue: discountValue,
      effectivePrice: (json['effective_price'] as num?)?.toDouble(),
    );
  }
}
