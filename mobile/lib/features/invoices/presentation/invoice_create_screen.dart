import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../cart/providers/cart_provider.dart';
import '../../customers/data/customer.dart';
import '../../customers/data/customer_repository.dart';
import '../../products/data/product_repository.dart';
import '../data/invoice_repository.dart';

class InvoiceCreateScreen extends ConsumerStatefulWidget {
  const InvoiceCreateScreen({super.key});

  @override
  ConsumerState<InvoiceCreateScreen> createState() => _InvoiceCreateScreenState();
}

class _InvoiceCreateScreenState extends ConsumerState<InvoiceCreateScreen> {
  Customer? _selectedCustomer;
  PaymentMethod _method = PaymentMethod.nakit;
  bool _saving = false;

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
        SnackBar(content: Text('Hata: $e')),
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
      appBar: AppBar(title: const Text('Fatura Oluştur')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Müşteri', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          customers.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Müşteriler yüklenemedi: $e'),
            data: (list) => DropdownButtonFormField<Customer>(
              value: _selectedCustomer,
              isExpanded: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline),
                hintText: 'Müşteri seçin',
              ),
              items: [
                for (final c in list)
                  DropdownMenuItem(value: c, child: Text(c.name)),
              ],
              onChanged: (c) => setState(() => _selectedCustomer = c),
            ),
          ),
          const SizedBox(height: 24),
          Text('Ödeme Yöntemi', style: theme.textTheme.titleMedium),
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
                            ),
                          ),
                          Text(formatCurrency(l.total)),
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
            label: const Text('Faturayı Gönder'),
          ),
        ],
      ),
    );
  }
}
