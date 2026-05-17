import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/customers/data/customer_repository.dart';
import '../../features/debts/data/debt_repository.dart';
import '../../features/invoices/data/invoice_repository.dart';
import '../../features/orders/data/order_repository.dart';
import '../../features/products/data/product_repository.dart';
import '../../features/reports/data/report_repository.dart';
import 'ws_client.dart';

final liveSyncProvider = Provider<void>((ref) {
  final sub = ref.watch(wsClientProvider).stream.listen((event) {
    final name = event.event;

    if (name.startsWith('product.') ||
        name == 'stock.changed' ||
        name.startsWith('category.')) {
      ref.invalidate(productsProvider);
    }

    if (name.startsWith('customer.')) {
      ref.invalidate(customersProvider);
    }

    if (name.startsWith('invoice.') ||
        name.startsWith('debt.') ||
        name == 'stock.changed') {
      ref.invalidate(invoicesProvider);
      ref.invalidate(allDebtsProvider);
      ref.invalidate(debtSummaryProvider);
      ref.invalidate(reportSummaryProvider);
    }

    if (name.startsWith('order.')) {
      ref.invalidate(myOrdersProvider);
      ref.invalidate(allOrdersProvider);
    }
  });

  ref.onDispose(sub.cancel);
});
