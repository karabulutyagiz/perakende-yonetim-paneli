import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_shell.dart';
import '../../orders/data/order_repository.dart';
import '../data/invoice_repository.dart';

final _dt = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');

class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(invoicesProvider);
    final asyncOrders = ref.watch(allOrdersProvider);

    return Scaffold(
      drawer: const AppDrawer(current: '/invoices'),
      appBar: const PsAppBar(title: 'Faturalar'),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: 'Faturalar yüklenemedi.',
          onRetry: () => ref.invalidate(invoicesProvider),
        ),
        data: (invoices) {
          final orders =
              asyncOrders.valueOrNull ?? const <Map<String, dynamic>>[];
          if (invoices.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Henüz fatura yok',
              subtitle:
                  'Siparişleri faturaya dönüştürdüğünde burada görünecek.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(invoicesProvider),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: invoices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
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
    final theme = Theme.of(context);
    final createdAt = DateTime.tryParse(invoice['created_at'] as String? ?? '');
    final customer = invoice['customer'] as Map<String, dynamic>?;
    final contactName = customer?['account_full_name'] as String?;
    final orderNo = _invoiceOrderNo(
      invoice['order_number']?.toString(),
      invoice['order_id']?.toString(),
      invoice['id']?.toString(),
      orders,
    );
    final cash = (invoice['cash_amount'] as num).toDouble();
    final card = (invoice['card_amount'] as num).toDouble();
    final debt = (invoice['debt_amount'] as num).toDouble();

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/invoices/${invoice['id']}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer?['name'] as String? ?? 'Müşteri',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          [
                            if (orderNo.isNotEmpty) '#$orderNo',
                            if (contactName != null &&
                                contactName.isNotEmpty)
                              contactName,
                            if (createdAt != null)
                              _dt.format(createdAt.toLocal()),
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatCurrency(
                            (invoice['total'] as num).toDouble()),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Row(
                        children: [
                          Text(
                            'Dekont',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (cash > 0)
                    _PayChip(
                      label: 'Nakit ${formatCurrency(cash)}',
                      bg: AppColors.primaryContainer,
                      fg: AppColors.primaryDark,
                    ),
                  if (card > 0)
                    _PayChip(
                      label: 'Kart ${formatCurrency(card)}',
                      bg: const Color(0xFFE0EAFB),
                      fg: const Color(0xFF1D4F91),
                    ),
                  if (debt > 0)
                    _PayChip(
                      label: 'Borç ${formatCurrency(debt)}',
                      bg: const Color(0xFFFFF4D6),
                      fg: const Color(0xFF8A6D00),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PayChip extends StatelessWidget {
  const _PayChip({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w800,
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
