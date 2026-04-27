import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import 'product.dart';

class ProductRepository {
  ProductRepository(this._dio);
  final Dio _dio;

  Future<List<Product>> list() async {
    final resp = await _dio.get('/products');
    return (resp.data as List)
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepository(ref.watch(apiClientProvider)),
);

final productsProvider = FutureProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).list();
});
