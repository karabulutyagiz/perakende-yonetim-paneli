import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api.dart';
import '../../core/ws.dart';

final invoicesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final resp = await ref.watch(dioProvider).get('/invoices', queryParameters: {
        'limit': 200,
      });
  return (resp.data as List).cast<Map<String, dynamic>>();
});

final _tl = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
final _dt = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');

const _paymentLabels = <String, String>{
  'nakit': 'Nakit',
  'kart': 'Kart',
  'borc': 'Borç',
};

class InvoicesPage extends ConsumerStatefulWidget {
  const InvoicesPage({super.key});

  @override
  ConsumerState<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends ConsumerState<InvoicesPage> {
  StreamSubscription<WsEvent>? _wsSub;

  @override
  void initState() {
    super.initState();
    _wsSub = listenWsEvents(
      ref,
      const ['invoice.', 'stock.', 'debt.'],
      (_) => ref.invalidate(invoicesProvider),
    );
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(invoicesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faturalar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(invoicesProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text('Henüz fatura yok',
                  style: TextStyle(color: Colors.black54)),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final inv = list[i];
                  final customer = inv['customer'] as Map<String, dynamic>?;
                  final method = inv['payment_method'] as String? ?? '';
                  final createdAt =
                      DateTime.tryParse(inv['created_at'] as String? ?? '');
                  final items = (inv['items'] as List?) ?? const [];
                  return ExpansionTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: Text(customer?['name'] as String? ?? '—',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text([
                      if (createdAt != null) _dt.format(createdAt.toLocal()),
                      _paymentLabels[method] ?? method,
                      '${items.length} kalem',
                    ].join(' · ')),
                    trailing: Text(
                      _tl.format((inv['total'] as num).toDouble()),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    childrenPadding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    children: [
                      if (inv['note'] != null &&
                          (inv['note'] as String).isNotEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text('Not: ${inv['note']}',
                                style: const TextStyle(color: Colors.black54)),
                          ),
                        ),
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(4),
                          1: FlexColumnWidth(2),
                          2: FlexColumnWidth(2),
                          3: FlexColumnWidth(2),
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                            ),
                            children: const [
                              _CellHeader('Ürün'),
                              _CellHeader('Miktar'),
                              _CellHeader('Birim Fiyat'),
                              _CellHeader('Tutar'),
                            ],
                          ),
                          for (final it in items.cast<Map<String, dynamic>>())
                            TableRow(children: [
                              _Cell(it['product_name'] as String? ?? '—'),
                              _Cell('${it['quantity']} ${it['unit'] ?? ''}'),
                              _Cell(_tl
                                  .format((it['unit_price'] as num).toDouble())),
                              _Cell(_tl
                                  .format((it['line_total'] as num).toDouble())),
                            ]),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CellHeader extends StatelessWidget {
  const _CellHeader(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
      );
}

class _Cell extends StatelessWidget {
  const _Cell(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Text(text),
      );
}
