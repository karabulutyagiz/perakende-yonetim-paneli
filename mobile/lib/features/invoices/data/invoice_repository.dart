import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../cart/providers/cart_provider.dart';

enum PaymentMethod { kart, nakit, borc }

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.kart => 'Kart',
        PaymentMethod.nakit => 'Nakit',
        PaymentMethod.borc => 'Borç',
      };
  String get value => name;
}

class InvoiceRepository {
  InvoiceRepository(this._dio);
  final Dio _dio;

  Future<List<Map<String, dynamic>>> list() async {
    final resp = await _dio.get('/invoices', queryParameters: {
      'only_order_backed': true,
    });
    return (resp.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getById(String invoiceId) async {
    final resp = await _dio.get('/invoices/$invoiceId');
    return (resp.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> create({
    required String customerId,
    required PaymentMethod method,
    required Cart cart,
    String? note,
  }) async {
    final resp = await _dio.post('/invoices', data: {
      'customer_id': customerId,
      'payment_method': method.value,
      'note': note,
      'items': [
        for (final l in cart.lines)
          {'product_id': l.product.id, 'quantity': l.quantity},
      ],
    });
    return (resp.data as Map).cast<String, dynamic>();
  }
}

final invoiceRepositoryProvider = Provider<InvoiceRepository>(
  (ref) => InvoiceRepository(ref.watch(apiClientProvider)),
);

final invoicesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(invoiceRepositoryProvider).list();
});
