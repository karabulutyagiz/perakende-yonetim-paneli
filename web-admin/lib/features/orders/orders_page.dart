import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api.dart';
import '../../core/ws.dart';

final ordersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final resp = await ref.watch(dioProvider).get('/orders');
  return (resp.data as List).cast<Map<String, dynamic>>();
});

final _tl = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
final _dt = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');

const _statusLabels = <String, String>{
  'pending': 'Bekliyor',
  'converted': 'Faturaya Donustu',
  'cancelled': 'Iptal',
};

const _paymentMethods = <String, String>{
  'nakit': 'Nakit',
  'kart': 'Kart',
  'borc': 'Borc',
};

class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  StreamSubscription<WsEvent>? _wsSub;

  @override
  void initState() {
    super.initState();
    _wsSub = listenWsEvents(
      ref,
      const ['order.', 'invoice.', 'stock.'],
      (_) => ref.invalidate(ordersProvider),
    );
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(ordersProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Siparisler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(ordersProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(child: Text('Henuz siparis yok'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final order = orders[i];
              final customer = order['customer'] as Map<String, dynamic>?;
              final createdAt = DateTime.tryParse(order['created_at'] as String? ?? '');
              final items = (order['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
              final status = order['status'] as String? ?? 'pending';
              return Card(
                child: ExpansionTile(
                  leading: const Icon(Icons.shopping_bag_outlined),
                  title: Text(customer?['name'] as String? ?? '—'),
                  subtitle: Text([
                    if (createdAt != null) _dt.format(createdAt.toLocal()),
                    '${items.length} kalem',
                    _statusLabels[status] ?? status,
                  ].join(' · ')),
                  trailing: Text(
                    _tl.format((order['total'] as num).toDouble()),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    if ((order['note'] as String?)?.isNotEmpty == true)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text('Not: ${order['note']}'),
                        ),
                      ),
                    for (final item in items)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(item['product_name'] as String? ?? '—'),
                        subtitle: Text('${item['quantity']} ${item['unit']} x ${_tl.format((item['unit_price'] as num).toDouble())}'),
                        trailing: Text(_tl.format((item['line_total'] as num).toDouble())),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (status == 'pending')
                          TextButton(
                            onPressed: () => _cancelOrder(order['id'] as String),
                            child: const Text('Iptal Et'),
                          ),
                        if (status == 'pending') const SizedBox(width: 8),
                        if (status == 'pending')
                          FilledButton(
                            onPressed: () => _convertToInvoice(order['id'] as String),
                            child: const Text('Fatura Olustur'),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _cancelOrder(String orderId) async {
    await ref.read(dioProvider).post('/orders/$orderId/cancel');
    ref.invalidate(ordersProvider);
  }

  Future<void> _convertToInvoice(String orderId) async {
    String method = 'nakit';
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Fatura Olustur'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: method,
                  decoration: const InputDecoration(labelText: 'Odeme yontemi'),
                  items: _paymentMethods.entries
                      .map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value)))
                      .toList(),
                  onChanged: (value) => setState(() => method = value ?? 'nakit'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: note,
                  decoration: const InputDecoration(labelText: 'Not (opsiyonel)'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgec')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Olustur')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    await ref.read(dioProvider).post(
      '/orders/$orderId/convert-to-invoice',
      data: {
        'payment_method': method,
        if (note.text.trim().isNotEmpty) 'note': note.text.trim(),
      },
    );
    ref.invalidate(ordersProvider);
  }
}
