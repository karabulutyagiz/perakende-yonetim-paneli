import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/formatters.dart';
import '../../orders/data/order_repository.dart';

final _dt = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String? _selectedOrderId;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myOrdersProvider);
    final isTablet = MediaQuery.of(context).size.width >= 900;

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

          _selectedOrderId ??= orders.first['id'].toString();
          final selected = orders.firstWhere(
            (order) => order['id'].toString() == _selectedOrderId,
            orElse: () => orders.first,
          );

          if (!isTablet) {
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(myOrdersProvider),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _OrderExpansionCard(order: orders[i]),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myOrdersProvider),
            child: Row(
              children: [
                SizedBox(
                  width: 360,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final order = orders[i];
                      final isSelected =
                          order['id'].toString() == _selectedOrderId;
                      return _OrderListCard(
                        order: order,
                        selected: isSelected,
                        onTap: () => setState(() {
                          _selectedOrderId = order['id'].toString();
                        }),
                      );
                    },
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _OrderDetailCard(order: selected),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OrderExpansionCard extends StatelessWidget {
  const _OrderExpansionCard({required this.order});

  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final createdAt = DateTime.tryParse(order['created_at'] as String? ?? '');
    final items =
        (order['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
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
            if (createdAt != null) _dt.format(createdAt.toLocal()),
            _statusLabel(order['status'] as String? ?? 'pending'),
          ].join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
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
                  formatCurrency((item['line_total'] as num).toDouble()),
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderListCard extends StatelessWidget {
  const _OrderListCard({
    required this.order,
    required this.selected,
    required this.onTap,
  });

  final Map<String, dynamic> order;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final createdAt = DateTime.tryParse(order['created_at'] as String? ?? '');
    return Card(
      color: selected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sipariş #${order['id'].toString().substring(0, 8)}',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                [
                  if (createdAt != null) _dt.format(createdAt.toLocal()),
                  _statusLabel(order['status'] as String? ?? 'pending'),
                ].join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              Text(
                formatCurrency((order['total'] as num).toDouble()),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderDetailCard extends StatelessWidget {
  const _OrderDetailCard({required this.order});

  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final items =
        (order['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final createdAt = DateTime.tryParse(order['created_at'] as String? ?? '');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sipariş ayrıntısı',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sipariş no: ${order['id'].toString().substring(0, 8)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (createdAt != null) ...[
              const SizedBox(height: 4),
              Text('Tarih: ${_dt.format(createdAt.toLocal())}'),
            ],
            const SizedBox(height: 4),
            Text(
                'Durum: ${_statusLabel(order['status'] as String? ?? 'pending')}'),
            const SizedBox(height: 20),
            Text(
              'Ürünler',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            for (final item in items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item['product_name'] as String? ?? '—'),
                subtitle: Text('${item['quantity']} ${item['unit']}'),
                trailing: Text(
                  formatCurrency((item['line_total'] as num).toDouble()),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            const Divider(height: 28),
            Row(
              children: [
                Text(
                  'Toplam',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  formatCurrency((order['total'] as num).toDouble()),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _statusLabel(String status) => switch (status) {
      'pending' => 'Bekliyor',
      'converted' => 'Faturaya dönüştü',
      'cancelled' => 'İptal edildi',
      _ => 'Durum bilinmiyor',
    };
