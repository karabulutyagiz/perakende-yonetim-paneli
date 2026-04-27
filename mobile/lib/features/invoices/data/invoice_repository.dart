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

  Future<void> create({
    required String customerId,
    required PaymentMethod method,
    required Cart cart,
    String? note,
  }) async {
    await _dio.post('/invoices', data: {
      'customer_id': customerId,
      'payment_method': method.value,
      'note': note,
      'items': [
        for (final l in cart.lines)
          {'product_id': l.product.id, 'quantity': l.quantity},
      ],
    });
  }
}

final invoiceRepositoryProvider = Provider<InvoiceRepository>(
  (ref) => InvoiceRepository(ref.watch(apiClientProvider)),
);
