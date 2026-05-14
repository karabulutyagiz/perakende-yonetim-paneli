import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/formatters.dart';
import '../../orders/data/order_repository.dart';

final _dt = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myOrdersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Siparişlerim')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(
          child: Text('Siparişler yüklenemedi. Lütfen tekrar deneyin.'),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(child: Text('Henüz siparişiniz yok'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myOrdersProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final order = orders[i];
                final createdAt =
                    DateTime.tryParse(order['created_at'] as String? ?? '');
                final items =
                    (order['items'] as List?)?.cast<Map<String, dynamic>>() ??
                        const [];
                final total = (order['total'] as num).toDouble();
                return Card(
                  child: ExpansionTile(
                    title: Text(
                      'Sipariş #${order['id'].toString().substring(0, 8)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                        [
                          if (createdAt != null)
                            _dt.format(createdAt.toLocal()),
                          _statusLabel(order['status'] as String? ?? 'pending'),
                        ].join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    trailing: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 110),
                      child: Text(
                        formatCurrency(total),
                        textAlign: TextAlign.end,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      for (final item in items)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            item['product_name'] as String? ?? '—',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text('${item['quantity']} ${item['unit']}'),
                          trailing: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 110),
                            child: Text(
                              formatCurrency(
                                  (item['line_total'] as num).toDouble()),
                              textAlign: TextAlign.end,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _statusLabel(String status) => switch (status) {
        'pending' => 'Bekliyor',
        'converted' => 'Faturaya dönüştü',
        'cancelled' => 'İptal edildi',
        _ => 'Durum bilinmiyor',
      };
}
