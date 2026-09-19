import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import 'product.dart';

class CategoryItem {
  const CategoryItem({required this.id, required this.name});
  final String id;
  final String name;

  factory CategoryItem.fromJson(Map<String, dynamic> json) => CategoryItem(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}

class ProductRepository {
  ProductRepository(this._dio);
  final Dio _dio;

  Future<List<Product>> list() async {
    final resp = await _dio.get('/products');
    return (resp.data as List)
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Product> create({
    required String name,
    required String unit,
    required double price,
    required double stock,
    String? description,
    String? categoryId,
    String? imageKey,
    DiscountType? discountType,
    double discountValue = 0,
  }) async {
    final resp = await _dio.post('/products', data: {
      'name': name,
      'unit': unit,
      'price': price,
      'stock': stock,
      'description':
          (description == null || description.isEmpty) ? null : description,
      'category_id': categoryId,
      'image_key': imageKey,
      'discount_type': discountType?.apiValue,
      'discount_value': discountType == null ? 0 : discountValue,
    });
    return Product.fromJson((resp.data as Map).cast<String, dynamic>());
  }

  Future<Product> update(
    String productId, {
    String? name,
    String? unit,
    double? price,
    double? stock,
    String? description,
    String? categoryId,
    String? imageKey,
    DiscountType? discountType,
    double discountValue = 0,
  }) async {
    final resp = await _dio.put('/products/$productId', data: {
      if (name != null) 'name': name,
      if (unit != null) 'unit': unit,
      if (price != null) 'price': price,
      if (stock != null) 'stock': stock,
      'description':
          (description == null || description.isEmpty) ? null : description,
      'category_id': categoryId,
      if (imageKey != null) 'image_key': imageKey,
      // discount_type null gönderilir → backend indirimi temizler.
      'discount_type': discountType?.apiValue,
      'discount_value': discountType == null ? 0 : discountValue,
    });
    return Product.fromJson((resp.data as Map).cast<String, dynamic>());
  }

  Future<void> delete(String productId) async {
    await _dio.delete('/products/$productId');
  }

  /// Fotoğrafı presigned URL akışıyla yükler, S3/backend `image_key` döner.
  Future<String> uploadImage({
    required Uint8List bytes,
    required String filename,
  }) async {
    final contentType = _contentTypeFor(filename);
    final presign = await _dio.post('/products/upload-url', data: {
      'filename': filename,
      'content_type': contentType,
    });
    final uploadUrl = presign.data['upload_url'] as String;
    final key = presign.data['key'] as String;

    // Presigned URL'e Authorization header'ı gitmemeli — çıplak Dio.
    await Dio().put(
      uploadUrl,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {
          Headers.contentLengthHeader: bytes.length,
          'Content-Type': contentType,
        },
      ),
    );
    return key;
  }

  Future<List<CategoryItem>> listCategories() async {
    final resp = await _dio.get('/categories');
    return (resp.data as List)
        .map((e) => CategoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CategoryItem> createCategory(String name) async {
    final resp = await _dio.post('/categories', data: {'name': name});
    return CategoryItem.fromJson((resp.data as Map).cast<String, dynamic>());
  }

  static String _contentTypeFor(String filename) {
    final ext = filename.contains('.')
        ? filename.split('.').last.toLowerCase()
        : 'jpg';
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };
  }
}

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepository(ref.watch(apiClientProvider)),
);

final productsProvider = FutureProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).list();
});

/// Kategoriler — sadece tenant_owner erişebilir (ürün formu için).
final categoriesProvider = FutureProvider<List<CategoryItem>>((ref) {
  return ref.watch(productRepositoryProvider).listCategories();
});
