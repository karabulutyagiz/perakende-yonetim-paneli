import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_shell.dart';
import '../../invoices/data/invoice_repository.dart';
import '../../orders/data/order_repository.dart';

final _dt = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  final _searchController = TextEditingController();
  String? _statusFilter; // null = tümü

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final async = ref.watch(
      auth.isTenantOwner ? allOrdersProvider : myOrdersProvider,
    );
    final search = _searchController.text.trim();

    return Scaffold(
      drawer: const AppDrawer(current: '/orders'),
      appBar: PsAppBar(
        title: auth.isTenantOwner ? 'Gelen Siparişler' : 'Siparişlerim',
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: 'Siparişler yüklenemedi. Lütfen tekrar deneyin.',
          onRetry: () => ref.invalidate(
            auth.isTenantOwner ? allOrdersProvider : myOrdersProvider,
          ),
        ),
        data: (orders) {
          var filtered = search.isEmpty
              ? orders
              : orders
                  .where((order) => _orderNo(order).startsWith(search))
                  .toList();
          if (_statusFilter != null) {
            filtered = filtered
                .where((o) =>
                    (o['status'] as String? ?? 'pending') == _statusFilter)
                .toList();
          }

          if (orders.isEmpty) {
            return EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: auth.isTenantOwner
                  ? 'Henüz sipariş gelmedi'
                  : 'Henüz siparişin yok',
              subtitle: auth.isTenantOwner
                  ? 'Müşterilerin sipariş verince burada görünecek.'
                  : 'Ürünlerden sepete ekleyip sipariş oluşturabilirsin.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(
              auth.isTenantOwner ? allOrdersProvider : myOrdersProvider,
            ),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                TextField(
                  controller: _searchController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Sipariş no ara',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: search.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final f in const [
                        (null, 'Tümü'),
                        ('pending', 'Bekliyor'),
                        ('converted', 'Faturalandı'),
                        ('cancelled', 'İptal'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(f.$2),
                            selected: _statusFilter == f.$1,
                            onSelected: (_) =>
                                setState(() => _statusFilter = f.$1),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: Center(child: Text('Aranan sipariş bulunamadı')),
                  )
                else
                  for (final order in filtered) ...[
                    _OrderCard(
                      order: order,
                      onTap: () => _openDetail(order),
                    ),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _openDetail(Map<String, dynamic> order) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _OrderDetailSheet(
        order: order,
        onCreateInvoice: _openInvoiceSheet,
      ),
    );
  }

  Future<void> _openInvoiceSheet(Map<String, dynamic> order) async {
    final invoiceId = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ConvertOrderSheet(order: order),
    );
    if (invoiceId != null && mounted) {
      ref.invalidate(allOrdersProvider);
      ref.invalidate(myOrdersProvider);
      ref.invalidate(invoicesProvider);
      context.push('/invoices/$invoiceId');
    }
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

(Color, Color, String) _statusStyle(String status) => switch (status) {
      'pending' => (
          const Color(0xFFFFF4D6),
          const Color(0xFF8A6D00),
          'Bekliyor'
        ),
      'converted' => (
          AppColors.primaryContainer,
          AppColors.primaryDark,
          'Faturalandı'
        ),
      'cancelled' => (
          const Color(0xFFFBE1DF),
          const Color(0xFF9C2119),
          'İptal edildi'
        ),
      _ => (const Color(0xFFEDEFEE), AppColors.textMuted, 'Bilinmiyor'),
    };

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = _statusStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final Map<String, dynamic> order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customer = order['customer'] as Map<String, dynamic>?;
    final contactName = customer?['account_full_name'] as String?;
    final createdAt = DateTime.tryParse(order['created_at'] as String? ?? '');
    final items =
        (order['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final status = order['status'] as String? ?? 'pending';

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      customer?['name'] as String? ??
                          'Sipariş #${_orderNo(order)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                [
                  '#${_orderNo(order)}',
                  if (contactName != null && contactName.isNotEmpty)
                    contactName,
                  if (createdAt != null) _dt.format(createdAt.toLocal()),
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    '${items.length} kalem',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textMuted),
                  ),
                  const Spacer(),
                  Text(
                    formatCurrency((order['total'] as num).toDouble()),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
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

class _OrderDetailSheet extends ConsumerWidget {
  const _OrderDetailSheet({
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
    final status = order['status'] as String? ?? 'pending';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, scrollCtl) => SafeArea(
        top: false,
        child: ListView(
          controller: scrollCtl,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    customer?['name'] as String? ?? 'Sipariş',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              [
                'Sipariş #${_orderNo(order)}',
                if (contactName != null && contactName.isNotEmpty)
                  contactName,
                if (createdAt != null) _dt.format(createdAt.toLocal()),
              ].join(' · '),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Column(
                children: [
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['product_name'] as String? ?? '—',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${item['quantity']} ${item['unit'] ?? ''}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            formatCurrency(
                              ((item['line_total'] ??
                                          ((item['unit_price'] as num?) ?? 0) *
                                              ((item['quantity'] as num?) ??
                                                  0)) as num)
                                  .toDouble(),
                            ),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Text(
                    'Toplam',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text(
                    formatCurrency((order['total'] as num).toDouble()),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            if (auth.isTenantOwner && status == 'pending') ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await onCreateInvoice(order);
                },
                icon: const Icon(Icons.receipt_long_rounded),
                label: const Text('Bu siparişten fatura oluştur'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Siparişi faturaya çevirme — tuş takımlı ödeme dağıtımı (alttan açılır).
// ---------------------------------------------------------------------------

class _ConvertOrderSheet extends ConsumerStatefulWidget {
  const _ConvertOrderSheet({required this.order});

  final Map<String, dynamic> order;

  @override
  ConsumerState<_ConvertOrderSheet> createState() =>
      _ConvertOrderSheetState();
}

class _ConvertOrderSheetState extends ConsumerState<_ConvertOrderSheet> {
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
    // Kuruş-korumalı format: 105.55 → "105,55 ₺" (yuvarlama bug'ı düzeltilmişti).
    _cashController = TextEditingController(text: _formatTlAmount(_total));
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
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sipariş #${_orderNo(widget.order)} için fatura',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Toplam: ${formatCurrency(_total)}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _AmountBox(
                      label: 'Nakit',
                      controller: _cashController,
                      active: _activeField == _AmountField.cash,
                      onTap: () =>
                          setState(() => _activeField = _AmountField.cash),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AmountBox(
                      label: 'Kart',
                      controller: _cardController,
                      active: _activeField == _AmountField.card,
                      onTap: () =>
                          setState(() => _activeField = _AmountField.card),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AmountBox(
                      label: 'Borç',
                      controller: _debtController,
                      active: _activeField == _AmountField.debt,
                      onTap: () =>
                          setState(() => _activeField = _AmountField.debt),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _AmountPad(onKeyTap: _handlePadKey),
              const SizedBox(height: 10),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Not (opsiyonel)'),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _submitting ? null : () => Navigator.pop(context),
                      child: const Text('Vazgeç'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: Text(
                        _submitting ? 'Oluşturuluyor...' : 'Fatura oluştur',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
    } on DioException catch (e) {
      if (!mounted) return;
      String msg = 'Fatura oluşturulamadı';
      final data = e.response?.data;
      if (data is Map && data['detail'] is String) {
        msg = data['detail'] as String;
      }
      _showError(msg);
      setState(() => _submitting = false);
    } catch (e) {
      if (!mounted) return;
      _showError('Fatura oluşturulamadı: $e');
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

class _AmountBox extends StatelessWidget {
  const _AmountBox({
    required this.label,
    required this.controller,
    required this.active,
    required this.onTap,
  });

  final String label;
  final TextEditingController controller;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryContainer : AppColors.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.line,
            width: active ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color:
                    active ? AppColors.primaryDark : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                controller.text,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountPad extends StatelessWidget {
  const _AmountPad({required this.onKeyTap});

  final ValueChanged<String> onKeyTap;

  @override
  Widget build(BuildContext context) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', ',', '0', 'sil'];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: keys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.2,
      ),
      itemBuilder: (context, index) {
        final key = keys[index];
        final isDelete = key == 'sil';
        return Material(
          color: isDelete ? const Color(0xFFFBE1DF) : AppColors.bg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onKeyTap(key),
            child: Center(
              child: isDelete
                  ? const Icon(
                      Icons.backspace_outlined,
                      size: 20,
                      color: Color(0xFF9C2119),
                    )
                  : Text(
                      key,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

String _formatTlInput(int value) {
  return _normalizeTlInput(value.toString());
}

/// Kuruşları KORUR — 105.55 → "105,55 ₺".
String _formatTlAmount(double value) {
  final asTr = value.toStringAsFixed(2).replaceAll('.', ',');
  return _normalizeTlInput(asTr);
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
