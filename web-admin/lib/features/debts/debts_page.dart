import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api.dart';
import '../../core/ws.dart';

final debtSummaryProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final resp = await ref.watch(dioProvider).get('/debts/summary');
  return (resp.data as List).cast<Map<String, dynamic>>();
});

final customerDebtsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, customerId) async {
    final resp = await ref.watch(dioProvider).get('/debts', queryParameters: {
      'customer_id': customerId,
      'only_open': false,
    });
    return (resp.data as List).cast<Map<String, dynamic>>();
  },
);

final _tl = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
final _d = DateFormat('dd.MM.yyyy', 'tr_TR');

const _statusColors = <String, Color>{
  'yesil': Color(0xFF2E7D32),
  'sari': Color(0xFFF9A825),
  'kirmizi': Color(0xFFC62828),
  'gecikti': Color(0xFF7B1FA2),
  'odendi': Color(0xFF455A64),
};

const _statusLabels = <String, String>{
  'yesil': 'Yeşil',
  'sari': 'Sarı',
  'kirmizi': 'Kırmızı',
  'gecikti': 'Gecikti',
  'odendi': 'Ödendi',
};

class DebtsPage extends ConsumerStatefulWidget {
  const DebtsPage({super.key});

  @override
  ConsumerState<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends ConsumerState<DebtsPage> {
  StreamSubscription<WsEvent>? _wsSub;

  @override
  void initState() {
    super.initState();
    _wsSub = listenWsEvents(ref, const ['debt.', 'invoice.'], (_) {
      ref.invalidate(debtSummaryProvider);
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> _recompute() async {
    try {
      await ref.read(dioProvider).post('/debts/recompute');
      ref.invalidate(debtSummaryProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(debtSummaryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Borçlar'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Durumları güncelle'),
            onPressed: _recompute,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text('Açık borç yok',
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
                  final row = list[i];
                  final customer = row['customer'] as Map<String, dynamic>;
                  final remaining = (row['remaining'] as num).toDouble();
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text((customer['name'] as String)[0]),
                    ),
                    title: Text(customer['name'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        '${row['debts_count']} borç · Toplam ${_tl.format((row['total_debt'] as num).toDouble())}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _tl.format(remaining),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: remaining > 0
                                ? const Color(0xFFC62828)
                                : const Color(0xFF2E7D32),
                          ),
                        ),
                        const Text('kalan',
                            style: TextStyle(
                                fontSize: 11, color: Colors.black54)),
                      ],
                    ),
                    onTap: () => _openCustomerSheet(customer),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  void _openCustomerSheet(Map<String, dynamic> customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CustomerDebtsSheet(customer: customer),
    );
  }
}

class _CustomerDebtsSheet extends ConsumerStatefulWidget {
  const _CustomerDebtsSheet({required this.customer});
  final Map<String, dynamic> customer;

  @override
  ConsumerState<_CustomerDebtsSheet> createState() => _CustomerDebtsSheetState();
}

class _CustomerDebtsSheetState extends ConsumerState<_CustomerDebtsSheet> {
  StreamSubscription<WsEvent>? _wsSub;

  @override
  void initState() {
    super.initState();
    _wsSub = listenWsEvents(ref, const ['debt.'], (_) {
      ref.invalidate(customerDebtsProvider(widget.customer['id'] as String));
    });
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.customer['id'] as String;
    final async = ref.watch(customerDebtsProvider(id));
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.customer['name'] as String,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Ödeme Kaydet'),
                  onPressed: () => _recordPayment(id),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: async.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Hata: $e')),
                data: (debts) {
                  if (debts.isEmpty) {
                    return const Center(child: Text('Borç yok'));
                  }
                  return ListView.separated(
                    controller: scrollCtrl,
                    itemCount: debts.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final d = debts[i];
                      final status = d['status'] as String? ?? 'yesil';
                      final remaining = (d['remaining'] as num).toDouble();
                      final dueOn = DateTime.tryParse(d['due_on'] as String? ?? '');
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _statusColors[status],
                          child: Text('${d['days_left']}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                        ),
                        title: Text(
                          _tl.format((d['total_amount'] as num).toDouble()),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text([
                          if (dueOn != null) 'Vade: ${_d.format(dueOn)}',
                          'Ödenen: ${_tl.format((d['paid_amount'] as num).toDouble())}',
                          _statusLabels[status] ?? status,
                        ].join(' · ')),
                        trailing: Text(
                          _tl.format(remaining),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: remaining > 0
                                ? const Color(0xFFC62828)
                                : const Color(0xFF2E7D32),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recordPayment(String customerId) async {
    final amountCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ödeme Kaydet'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tutar, müşterinin en eski açık borcundan başlayarak dağıtılır.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Tutar (₺)',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final amount =
        double.tryParse(amountCtrl.text.trim().replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geçerli bir tutar girin')));
      return;
    }
    try {
      await ref.read(dioProvider).post('/debts/payments', data: {
        'customer_id': customerId,
        'amount': amount,
      });
      ref.invalidate(customerDebtsProvider(customerId));
      ref.invalidate(debtSummaryProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Ödeme kaydedildi')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }
}
