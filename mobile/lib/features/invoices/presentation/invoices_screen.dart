import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/formatters.dart';
import '../../orders/data/order_repository.dart';
import '../data/invoice_repository.dart';

final _dt = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');

class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(invoicesProvider);
    final asyncOrders = ref.watch(allOrdersProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black, size: 32),
        titleSpacing: 4,
        title: Text(
          'Faturalar',
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Faturalar yüklenemedi.')),
        data: (invoices) {
          final orders =
              asyncOrders.valueOrNull ?? const <Map<String, dynamic>>[];
          if (invoices.isEmpty) {
            return const Center(
              child: Text('Henüz siparişten oluşmuş fatura yok'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(invoicesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: invoices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _InvoiceCard(
                invoice: invoices[i],
                orders: orders,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.invoice, required this.orders});

  final Map<String, dynamic> invoice;
  final List<Map<String, dynamic>> orders;

  @override
  Widget build(BuildContext context) {
    final createdAt = DateTime.tryParse(invoice['created_at'] as String? ?? '');
    final customer = invoice['customer'] as Map<String, dynamic>?;
    final contactName = customer?['account_full_name'] as String?;
    final orderNo = _invoiceOrderNo(
      invoice['order_number']?.toString(),
      invoice['order_id']?.toString(),
      invoice['id']?.toString(),
      orders,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer?['name'] as String? ?? 'Müşteri',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sipariş #$orderNo',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => context.push('/invoices/${invoice['id']}'),
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: const Text('Dekont görüntüle'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (contactName != null && contactName.isNotEmpty)
              Text('Yetkili: $contactName'),
            if (createdAt != null)
              Text('Tarih: ${_dt.format(createdAt.toLocal())}'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                Text(
                    'Toplam: ${formatCurrency((invoice['total'] as num).toDouble())}'),
                Text(
                    'Nakit: ${formatCurrency((invoice['cash_amount'] as num).toDouble())}'),
                Text(
                    'Kart: ${formatCurrency((invoice['card_amount'] as num).toDouble())}'),
                Text(
                    'Borç: ${formatCurrency((invoice['debt_amount'] as num).toDouble())}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _invoiceOrderNo(
  String? orderNumber,
  String? orderId,
  String? invoiceId,
  List<Map<String, dynamic>> orders,
) {
  if (orderNumber != null && orderNumber.isNotEmpty) return orderNumber;
  if (invoiceId != null && invoiceId.isNotEmpty) {
    for (final order in orders) {
      if (order['invoice_id']?.toString() == invoiceId) {
        final explicit = order['order_number']?.toString();
        if (explicit != null && explicit.isNotEmpty) return explicit;
        final orderRaw = order['id']?.toString();
        if (orderRaw != null && orderRaw.isNotEmpty) {
          final value = BigInt.parse(orderRaw.replaceAll('-', ''), radix: 16);
          final digits = (value % BigInt.from(100000000)).toString();
          return digits.padLeft(8, '0');
        }
      }
    }
  }
  final raw = orderId;
  if (raw == null || raw.isEmpty) return '';
  final value = BigInt.parse(raw.replaceAll('-', ''), radix: 16);
  final digits = (value % BigInt.from(100000000)).toString();
  return digits.padLeft(8, '0');
}
