import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../invoices/data/invoice_repository.dart';
import '../../orders/data/order_repository.dart';

final _dt = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String? _selectedOrderId;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final async = ref.watch(
      auth.isTenantOwner ? allOrdersProvider : myOrdersProvider,
    );
    final isTablet = MediaQuery.of(context).size.width >= 900;
    final search = _searchController.text.trim();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 4,
        title: _SectionHeaderTitle(
          title: auth.isTenantOwner ? 'Gelen Siparişler' : 'Siparişlerim',
        ),
        actions: [
          if (auth.isCustomer)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Ana sayfa'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.black.withValues(alpha: 0.06),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  minimumSize: const Size(0, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(
          child: Text('Siparişler yüklenemedi. Lütfen tekrar deneyin.'),
        ),
        data: (orders) {
          final filtered = search.isEmpty
              ? orders
              : orders
                  .where((order) => _orderNo(order).contains(search))
                  .toList();

          if (orders.isEmpty) {
            return const Center(child: Text('Henüz siparişiniz yok'));
          }

          if (filtered.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _OrdersSearchField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: (_) {
                    setState(() {});
                    _keepSearchFocused();
                  },
                ),
                const SizedBox(height: 24),
                const Center(child: Text('Aranan sipariş bulunamadı')),
              ],
            );
          }

          _selectedOrderId ??= filtered.first['id'].toString();
          final selected = filtered.firstWhere(
            (order) => order['id'].toString() == _selectedOrderId,
            orElse: () => filtered.first,
          );

          if (!isTablet) {
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(
                auth.isTenantOwner ? allOrdersProvider : myOrdersProvider,
              ),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return _OrdersSearchField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: (_) {
                        setState(() {});
                        _keepSearchFocused();
                      },
                    );
                  }
                  return _OrderExpansionCard(
                    order: filtered[i - 1],
                    onCreateInvoice: _openInvoiceDialog,
                  );
                },
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(
              auth.isTenantOwner ? allOrdersProvider : myOrdersProvider,
            ),
            child: LayoutBuilder(
                builder: (context, constraints) => Row(
                      children: [
                        SizedBox(
                          width: 360,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length + 1,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, i) {
                              if (i == 0) {
                                return _OrdersSearchField(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  onChanged: (_) {
                                    setState(() {});
                                    _keepSearchFocused();
                                  },
                                );
                              }
                              final order = filtered[i - 1];
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
                          child: SizedBox(
                            height: constraints.maxHeight,
                            child: _OrderDetailCard(
                              order: selected,
                              onCreateInvoice: _openInvoiceDialog,
                            ),
                          ),
                        ),
                      ],
                    )),
          );
        },
      ),
    );
  }

  Future<void> _openInvoiceDialog(Map<String, dynamic> order) async {
    final invoiceId = await showDialog<String?>(
      context: context,
      builder: (_) => _ConvertOrderDialog(order: order),
    );
    if (invoiceId != null && mounted) {
      ref.invalidate(allOrdersProvider);
      ref.invalidate(myOrdersProvider);
      ref.invalidate(invoicesProvider);
      context.push('/invoices/$invoiceId');
    }
  }

  void _keepSearchFocused() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_searchFocusNode.hasFocus) {
        _searchFocusNode.requestFocus();
      }
    });
  }
}

class _OrdersSearchField extends StatelessWidget {
  const _OrdersSearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: true,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      onTapOutside: (_) => focusNode.requestFocus(),
      decoration: const InputDecoration(
        labelText: 'Sipariş no ara',
        hintText: 'Örn. 12345678',
        prefixIcon: Icon(Icons.search_rounded),
      ),
    );
  }
}

String _orderNo(Map<String, dynamic> order) {
  final explicit = order['order_number']?.toString();
  if (explicit != null && explicit.isNotEmpty) return explicit;
  final raw = order['id']?.toString() ?? '';
  if (raw.isEmpty) return '00000000';
  final value = BigInt.parse(raw.replaceAll('-', ''), radix: 16);
  final digits = (value % BigInt.from(100000000)).toString();
  return digits.padLeft(8, '0');
}

class _SectionHeaderTitle extends StatelessWidget {
  const _SectionHeaderTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _OrderExpansionCard extends ConsumerWidget {
  const _OrderExpansionCard({
    required this.order,
    required this.onCreateInvoice,
  });

  final Map<String, dynamic> order;
  final Future<void> Function(Map<String, dynamic> order) onCreateInvoice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final customer = order['customer'] as Map<String, dynamic>?;
    final contactName = customer?['account_full_name'] as String?;
    final createdAt = DateTime.tryParse(order['created_at'] as String? ?? '');
    final items =
        (order['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final total = (order['total'] as num).toDouble();

    return Card(
      child: ExpansionTile(
        title: Text(
          customer?['name'] as String? ?? 'Sipariş #${_orderNo(order)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          [
            if (contactName != null && contactName.isNotEmpty) contactName,
            'Sipariş #${_orderNo(order)}',
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
          if (auth.isTenantOwner &&
              (order['status'] as String? ?? 'pending') == 'pending')
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FilledButton.icon(
                  onPressed: () => onCreateInvoice(order),
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: const Text('Fatura oluştur'),
                ),
              ),
            ),
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
    final customer = order['customer'] as Map<String, dynamic>?;
    final contactName = customer?['account_full_name'] as String?;
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
                customer?['name'] as String? ?? 'Sipariş #${_orderNo(order)}',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                [
                  if (contactName != null && contactName.isNotEmpty)
                    contactName,
                  'Sipariş #${_orderNo(order)}',
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

class _OrderDetailCard extends ConsumerWidget {
  const _OrderDetailCard({
    required this.order,
    required this.onCreateInvoice,
  });

  final Map<String, dynamic> order;
  final Future<void> Function(Map<String, dynamic> order) onCreateInvoice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final items =
        (order['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final customer = order['customer'] as Map<String, dynamic>?;
    final contactName = customer?['account_full_name'] as String?;
    final createdAt = DateTime.tryParse(order['created_at'] as String? ?? '');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sipariş ayrıntısı',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sipariş no: ${_orderNo(order)}',
            style: theme.textTheme.titleMedium,
          ),
          if (customer?['name'] != null) ...[
            const SizedBox(height: 4),
            Text('Dükkan: ${customer!['name']}'),
          ],
          if (contactName != null && contactName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Yetkili: $contactName'),
          ],
          if (createdAt != null) ...[
            const SizedBox(height: 4),
            Text('Tarih: ${_dt.format(createdAt.toLocal())}'),
          ],
          const SizedBox(height: 4),
          Text(
            'Durum: ${_statusLabel(order['status'] as String? ?? 'pending')}',
          ),
          if (auth.isTenantOwner &&
              (order['status'] as String? ?? 'pending') == 'pending') ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => onCreateInvoice(order),
              icon: const Icon(Icons.receipt_long_rounded),
              label: const Text('Bu siparişten fatura oluştur'),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'Ürünler',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
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
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Text(
                  'Toplam',
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  formatCurrency((order['total'] as num).toDouble()),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
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

class _ConvertOrderDialog extends ConsumerStatefulWidget {
  const _ConvertOrderDialog({required this.order});

  final Map<String, dynamic> order;

  @override
  ConsumerState<_ConvertOrderDialog> createState() =>
      _ConvertOrderDialogState();
}

class _ConvertOrderDialogState extends ConsumerState<_ConvertOrderDialog> {
  late final TextEditingController _cashController;
  late final TextEditingController _cardController;
  late final TextEditingController _debtController;
  final TextEditingController _noteController = TextEditingController();
  _AmountField _activeField = _AmountField.cash;
  bool _submitting = false;

  double get _total => (widget.order['total'] as num).toDouble();

  @override
  void initState() {
    super.initState();
    _cashController =
        TextEditingController(text: _formatTlInput(_total.round()));
    _cardController = TextEditingController(text: _formatTlInput(0));
    _debtController = TextEditingController(text: _formatTlInput(0));
  }

  @override
  void dispose() {
    _cashController.dispose();
    _cardController.dispose();
    _debtController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Sipariş #${_orderNo(widget.order)} için fatura'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Toplam: ${formatCurrency(_total)}'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _cashController,
                readOnly: true,
                showCursor: false,
                onTap: () => setState(() => _activeField = _AmountField.cash),
                decoration: const InputDecoration(labelText: 'Nakit ödeme'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _cardController,
                readOnly: true,
                showCursor: false,
                onTap: () => setState(() => _activeField = _AmountField.card),
                decoration: const InputDecoration(labelText: 'Kart ödeme'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _debtController,
                readOnly: true,
                showCursor: false,
                onTap: () => setState(() => _activeField = _AmountField.debt),
                decoration: const InputDecoration(labelText: 'Borç tutarı'),
              ),
              const SizedBox(height: 12),
              _AmountPad(
                activeLabel: switch (_activeField) {
                  _AmountField.cash => 'Nakit ödeme',
                  _AmountField.card => 'Kart ödeme',
                  _AmountField.debt => 'Borç tutarı',
                },
                onKeyTap: _handlePadKey,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Not'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: Text(_submitting ? 'Oluşturuluyor...' : 'Fatura oluştur'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final cash = _parseAmount(_cashController.text);
    final card = _parseAmount(_cardController.text);
    final debt = _parseAmount(_debtController.text);
    if (cash == null || card == null || debt == null) {
      _showError('Ödeme alanlarına geçerli tutar girin');
      return;
    }
    final sum = cash + card + debt;
    if ((sum - _total).abs() > 0.009) {
      _showError('Ödeme toplamı sipariş toplamı ile aynı olmalı');
      return;
    }

    PaymentMethod method;
    if (debt > 0) {
      method = PaymentMethod.borc;
    } else if (card > 0 && cash == 0) {
      method = PaymentMethod.kart;
    } else {
      method = PaymentMethod.nakit;
    }

    setState(() => _submitting = true);
    try {
      final order = await ref.read(orderRepositoryProvider).convertToInvoice(
            orderId: widget.order['id'].toString(),
            paymentMethod: method,
            cashAmount: cash,
            cardAmount: card,
            debtAmount: debt,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          );
      if (!mounted) return;
      final invoiceId = order['invoice_id']?.toString();
      Navigator.pop(context, invoiceId);
    } catch (_) {
      if (!mounted) return;
      _showError('Fatura oluşturulamadı');
      setState(() => _submitting = false);
    }
  }

  double? _parseAmount(String raw) {
    final normalized = raw.replaceAll(' ₺', '').replaceAll('.', '').trim();
    if (normalized.isEmpty) return 0;
    return double.tryParse(normalized.replaceAll(',', '.'));
  }

  void _handlePadKey(String key) {
    final controller = switch (_activeField) {
      _AmountField.cash => _cashController,
      _AmountField.card => _cardController,
      _AmountField.debt => _debtController,
    };
    final current = controller.text.replaceAll(' ₺', '');
    String next;
    if (key == 'sil') {
      next = current.isEmpty ? '' : current.substring(0, current.length - 1);
    } else if (key == ',') {
      next = current.contains(',')
          ? current
          : (current.isEmpty ? '0,' : '$current,');
    } else {
      next = current == '0' ? key : '$current$key';
    }
    controller.text = _normalizeTlInput(next);
    setState(() {});
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

enum _AmountField { cash, card, debt }

class _AmountPad extends StatelessWidget {
  const _AmountPad({required this.activeLabel, required this.onKeyTap});

  final String activeLabel;
  final ValueChanged<String> onKeyTap;

  @override
  Widget build(BuildContext context) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', ',', '0', 'sil'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Aktif alan: $activeLabel'),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: keys.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.9,
          ),
          itemBuilder: (context, index) {
            final key = keys[index];
            return FilledButton(
              onPressed: () => onKeyTap(key),
              child: Text(key == 'sil' ? 'Sil' : key),
            );
          },
        ),
      ],
    );
  }
}

String _formatTlInput(int value) {
  return _normalizeTlInput(value.toString());
}

String _normalizeTlInput(String raw) {
  final sanitized = raw.replaceAll(' ₺', '').replaceAll('.', '');
  if (sanitized.isEmpty) return '0 ₺';
  final parts = sanitized.split(',');
  final liraDigits = parts.first.replaceAll(RegExp(r'[^0-9]'), '');
  final lira = liraDigits.isEmpty ? '0' : liraDigits;
  final kurusSource =
      parts.length > 1 ? parts[1].replaceAll(RegExp(r'[^0-9]'), '') : '';
  final kurus =
      kurusSource.length > 2 ? kurusSource.substring(0, 2) : kurusSource;
  final reversed = lira.split('').reversed.toList();
  final buffer = StringBuffer();
  for (var i = 0; i < reversed.length; i++) {
    if (i > 0 && i % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(reversed[i]);
  }
  final formattedLira = buffer.toString().split('').reversed.join();
  final decimalPart = parts.length > 1 ? ',$kurus' : '';
  return '$formattedLira$decimalPart ₺';
}
