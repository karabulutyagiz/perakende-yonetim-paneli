import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api.dart';

final reportProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final resp = await ref.watch(dioProvider).get('/reports/summary');
  return resp.data as Map<String, dynamic>;
});

final _tl = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reportProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(reportProvider),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (r) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _statCard('Toplam Satış',
                    _tl.format((r['total_sales'] as num).toDouble()), Icons.trending_up),
                _statCard('Fatura Sayısı', '${r['invoice_count']}', Icons.receipt_long),
                _statCard('Tekil Müşteri', '${r['unique_customers']}', Icons.people),
                _statCard('Düşük Stok', '${r['low_stock_products']}', Icons.warning_amber),
                _statCard(
                  'Açık Borç',
                  _tl.format((r['outstanding_debt'] as num).toDouble()),
                  Icons.schedule,
                ),
                _statCard(
                  'Geciken Borç',
                  _tl.format((r['overdue_debt'] as num).toDouble()),
                  Icons.error_outline,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) => SizedBox(
        width: 240,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: const Color(0xFF0E6E4E)),
                const SizedBox(height: 12),
                Text(label, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      );
}
