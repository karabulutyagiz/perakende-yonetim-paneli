import 'dart:async';

import 'package:dio/dio.dart';
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

/// Tüm açık borçları flat liste olarak getirir (vade sırasına göre, en acil üstte)
final allDebtsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final resp = await ref.watch(dioProvider).get('/debts');
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
      ref.invalidate(allDebtsProvider);
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
      ref.invalidate(allDebtsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(allDebtsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Borçlar'),
        actions: [
          // Renk legend
          const _LegendBadge(color: Color(0xFFC62828), label: '≤3 gün'),
          const SizedBox(width: 8),
          const _LegendBadge(color: Color(0xFFF9A825), label: '≤7 gün'),
          const SizedBox(width: 8),
          const _LegendBadge(color: Color(0xFF2E7D32), label: '>7 gün'),
          const SizedBox(width: 16),
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
              child: Text('Açık borç yok 🎉',
                  style: TextStyle(color: Colors.black54)),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final d = list[i];
                final status = d['status'] as String? ?? 'yesil';
                final color = _statusColors[status] ?? const Color(0xFF607D8B);
                final remaining = (d['remaining'] as num).toDouble();
                final daysLeft = (d['days_left'] as int?) ?? 0;
                final customer = (d['customer'] as Map<String, dynamic>?);
                final customerName = (customer?['name'] as String?) ?? '—';
                final dueOn = DateTime.tryParse(d['due_on'] as String? ?? '');

                final badgeText = status == 'gecikti'
                    ? '${-daysLeft} gün geçti'
                    : '$daysLeft gün';

                return Card(
                  color: color.withOpacity(0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: color.withOpacity(0.5), width: 1.2),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _openPayDialog(d),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                      child: Row(
                        children: [
                          // Sol renk şeridi
                          Container(
                            width: 6,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Müşteri + vade tarihi
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                if (dueOn != null)
                                  Text(
                                    'Vade: ${_d.format(dueOn)}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Kalan tutar
                          Text(
                            _tl.format(remaining),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Gün rozeti — daima kırmızı (dikkat çeksin)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC62828),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              badgeText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _openPayDialog(Map<String, dynamic> debt) async {
    final amountCtrl = TextEditingController();
    final remaining = (debt['remaining'] as num).toDouble();
    final customer = debt['customer'] as Map<String, dynamic>?;
    final customerId = debt['customer_id'] as String;
    final customerName = (customer?['name'] as String?) ?? '—';
    String? errorText;
    bool submitting = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Ödeme — $customerName'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Kalan: ${_tl.format(remaining)}',
                    style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Ödenen tutar (₺)',
                    prefixIcon: const Icon(Icons.payments_outlined),
                    helperText: 'En fazla ${_tl.format(remaining)}',
                    errorText: errorText,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () =>
                      amountCtrl.text = remaining.toStringAsFixed(2),
                  child: const Text('Tümünü doldur'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: submitting
                  ? null
                  : () async {
                      final raw =
                          amountCtrl.text.trim().replaceAll(',', '.');
                      final value = double.tryParse(raw);
                      if (value == null || value <= 0) {
                        setLocal(() => errorText = 'Geçerli bir tutar girin');
                        return;
                      }
                      if (value > remaining + 0.005) {
                        setLocal(() =>
                            errorText = 'Kalan borçtan fazla olamaz');
                        return;
                      }
                      setLocal(() {
                        submitting = true;
                        errorText = null;
                      });
                      try {
                        await ref.read(dioProvider).post('/debts/payments',
                            data: {
                              'customer_id': customerId,
                              'amount': value,
                            });
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        ref.invalidate(allDebtsProvider);
                        ref.invalidate(debtSummaryProvider);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ödeme kaydedildi')),
                        );
                      } catch (e) {
                        String msg = 'Hata: $e';
                        if (e is DioException) {
                          final data = e.response?.data;
                          if (data is Map && data['detail'] is String) {
                            msg = data['detail'] as String;
                          }
                        }
                        setLocal(() {
                          submitting = false;
                          errorText = msg;
                        });
                      }
                    },
              child: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Ödemeyi Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

}


class _LegendBadge extends StatelessWidget {
  const _LegendBadge({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

