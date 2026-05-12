import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../cart/providers/cart_provider.dart';

class OrderRepository {
  OrderRepository(this._dio);
  final Dio _dio;

  Future<void> create(Cart cart, {String? note}) async {
    await _dio.post('/orders', data: {
      'note': note,
      'items': [
        for (final l in cart.lines) {'product_id': l.product.id, 'quantity': l.quantity},
      ],
    });
  }

  Future<List<Map<String, dynamic>>> listMine() async {
    final resp = await _dio.get('/orders/mine');
    return (resp.data as List).cast<Map<String, dynamic>>();
  }
}

final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => OrderRepository(ref.watch(apiClientProvider)),
);

final myOrdersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(orderRepositoryProvider).listMine();
});
