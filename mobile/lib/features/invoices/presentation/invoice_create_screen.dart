import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/ws/ws_client.dart';
import '../../cart/providers/cart_provider.dart';
import '../../customers/data/customer.dart';
import '../../customers/data/customer_repository.dart';
import '../../products/data/product_repository.dart';
import '../data/invoice_repository.dart';

class InvoiceCreateScreen extends ConsumerStatefulWidget {
  const InvoiceCreateScreen({super.key});

  @override
  ConsumerState<InvoiceCreateScreen> createState() =>
      _InvoiceCreateScreenState();
}

class _InvoiceCreateScreenState extends ConsumerState<InvoiceCreateScreen> {
  Customer? _selectedCustomer;
  PaymentMethod _method = PaymentMethod.nakit;
  bool _saving = false;
  StreamSubscription? _wsSub;

  @override
  void initState() {
    super.initState();
    // Web admin'den müşteri eklendiğinde / silindiğinde anında yenilensin
    _wsSub = ref.read(wsClientProvider).stream.listen((event) {
      if (!mounted) return;
      if (event.event.startsWith('customer.')) {
        ref.invalidate(customersProvider);
      }
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> _submit() async {
    final cart = ref.read(cartProvider);
    if (_selectedCustomer == null || cart.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(invoiceRepositoryProvider).create(
            customerId: _selectedCustomer!.id,
            method: _method,
            cart: cart,
          );
      ref.read(cartProvider.notifier).clear();
      ref.invalidate(productsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fatura oluşturuldu')),
      );
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fatura oluşturulamadı. Lütfen tekrar deneyin.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider);
    final cart = ref.watch(cartProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Fatura oluştur')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Müşteri', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          customers.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const Text(
              'Müşteriler yüklenemedi. Lütfen tekrar deneyin.',
            ),
            data: (list) => Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(
                  _selectedCustomer?.name ?? 'Müşteri seçin',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: _selectedCustomer?.phone != null
                    ? Text(
                        _selectedCustomer!.phone!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: list.isEmpty
                    ? null
                    : () async {
                        final picked = await showModalBottomSheet<Customer>(
                          context: context,
                          showDragHandle: true,
                          isScrollControlled: true,
                          builder: (ctx) => SafeArea(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: MediaQuery.of(ctx).size.height * 0.7,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'Müşteri seç',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: list.length,
                                      itemBuilder: (_, i) {
                                        final c = list[i];
                                        return ListTile(
                                          leading: const Icon(Icons.person),
                                          title: Text(
                                            c.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          subtitle: c.phone != null
                                              ? Text(
                                                  c.phone!,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                )
                                              : null,
                                          selected:
                                              _selectedCustomer?.id == c.id,
                                          onTap: () => Navigator.pop(ctx, c),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                        if (picked != null) {
                          setState(() => _selectedCustomer = picked);
                        }
                      },
              ),
            ),
          ),
          if (customers.value?.isEmpty ?? false)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Henüz müşteri yok. Web admin panelinden müşteri ekleyin.',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          const SizedBox(height: 24),
          Text('Ödeme yöntemi', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<PaymentMethod>(
            segments: const [
              ButtonSegment(
                value: PaymentMethod.kart,
                label: Text('Kart'),
                icon: Icon(Icons.credit_card),
              ),
              ButtonSegment(
                value: PaymentMethod.nakit,
                label: Text('Nakit'),
                icon: Icon(Icons.payments_outlined),
              ),
              ButtonSegment(
                value: PaymentMethod.borc,
                label: Text('Borç'),
                icon: Icon(Icons.schedule),
              ),
            ],
            selected: {_method},
            onSelectionChanged: (s) => setState(() => _method = s.first),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (final l in cart.lines)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${l.product.name} × ${l.quantity.toStringAsFixed(0)}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              formatCurrency(l.total),
                              textAlign: TextAlign.end,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Toplam',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        formatCurrency(cart.total),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: (_selectedCustomer == null || cart.isEmpty || _saving)
                ? null
                : _submit,
            icon: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline),
            label: const Text('Faturayı gönder'),
          ),
        ],
      ),
    );
  }
}
