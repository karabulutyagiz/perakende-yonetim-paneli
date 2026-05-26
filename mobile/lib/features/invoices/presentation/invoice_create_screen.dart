import 'dart:async';

import 'package:dio/dio.dart';
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
      final invoice = await ref.read(invoiceRepositoryProvider).create(
            customerId: _selectedCustomer!.id,
            method: _method,
            cart: cart,
          );
      ref.read(cartProvider.notifier).clear();
      ref.invalidate(productsProvider);
      ref.invalidate(invoicesProvider);
      if (!mounted) return;
      // pushReplacement: fatura ekranından geri tuşuyla burası yerine
      // doğal akışta önceki ekrana (home/cart) dönülsün.
      context.pushReplacement('/invoices/${invoice['id']}');
    } on DioException catch (e) {
      if (!mounted) return;
      String msg = 'Fatura oluşturulamadı. Lütfen tekrar deneyin.';
      final data = e.response?.data;
      if (data is Map && data['detail'] is String) {
        msg = data['detail'] as String;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fatura oluşturulamadı: $e')),
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
          Text('Müşteri Seçimi', style: theme.textTheme.titleMedium),
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
                                maxHeight:
                                    MediaQuery.of(ctx).size.height * 0.82,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        20, 12, 20, 8),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.people_alt_outlined,
                                          color: theme.colorScheme.primary,
                                          size: 28,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Müşteri seçimi',
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(20, 0, 20, 8),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Fatura oluşturmak için bir müşteri seçin.',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        20, 0, 20, 12),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: FilledButton.tonalIcon(
                                        icon:
                                            const Icon(Icons.person_add_alt_1),
                                        label: const Text(
                                            'Yeni müşteri ekle'),
                                        onPressed: () async {
                                          final created =
                                              await _showQuickAddCustomer(ctx);
                                          if (created != null) {
                                            ref.invalidate(customersProvider);
                                            if (ctx.mounted) {
                                              Navigator.pop(ctx, created);
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: ListView.builder(
                                      padding: const EdgeInsets.fromLTRB(
                                          12, 4, 12, 16),
                                      shrinkWrap: true,
                                      itemCount: list.length,
                                      itemBuilder: (_, i) {
                                        final c = list[i];
                                        final selected =
                                            _selectedCustomer?.id == c.id;
                                        return ListTile(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          tileColor: selected
                                              ? theme
                                                  .colorScheme.primaryContainer
                                                  .withValues(alpha: 0.45)
                                              : null,
                                          leading: CircleAvatar(
                                            radius: 22,
                                            backgroundColor: theme
                                                .colorScheme.primaryContainer,
                                            child: Icon(
                                              Icons.person,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                          title: Text(
                                            c.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          subtitle: c.phone != null
                                              ? Text(
                                                  c.phone!,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: theme
                                                      .textTheme.bodyMedium,
                                                )
                                              : null,
                                          selected: selected,
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

  Future<Customer?> _showQuickAddCustomer(BuildContext sheetCtx) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    final created = await showDialog<Customer>(
      context: sheetCtx,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSt) {
          return AlertDialog(
            title: const Text('Yeni müşteri'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Müşteri adı *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Müşteri adı zorunlu'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Telefon (opsiyonel)',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addressCtrl,
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Adres (opsiyonel)',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setSt(() => saving = true);
                        try {
                          final c = await ref
                              .read(customerRepositoryProvider)
                              .create(
                                name: nameCtrl.text.trim(),
                                phone: phoneCtrl.text.trim(),
                                address: addressCtrl.text.trim(),
                              );
                          if (ctx.mounted) Navigator.pop(ctx, c);
                        } on DioException catch (e) {
                          String msg = 'Müşteri eklenemedi';
                          final data = e.response?.data;
                          if (data is Map && data['detail'] is String) {
                            msg = data['detail'] as String;
                          }
                          if (ctx.mounted) {
                            setSt(() => saving = false);
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text(msg)),
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            setSt(() => saving = false);
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Hata: $e')),
                            );
                          }
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Kaydet'),
              ),
            ],
          );
        });
      },
    );

    if (created != null) {
      setState(() => _selectedCustomer = created);
    }
    return created;
  }
}
