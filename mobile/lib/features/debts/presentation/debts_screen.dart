import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../data/debt.dart';
import '../data/debt_repository.dart';

class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allDebtsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Borçlar'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(36),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                _LegendDot(color: Color(0xFFE53935), label: '≤3 gün'),
                SizedBox(width: 12),
                _LegendDot(color: Color(0xFFFFB300), label: '≤7 gün'),
                SizedBox(width: 12),
                _LegendDot(color: Color(0xFF43A047), label: '>7 gün'),
              ],
            ),
          ),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Açık borç yok 🎉'));
          }
          // Backend zaten due_on ASC ile sıralı; OVERDUE da en başta gelir.
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(allDebtsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _DebtCard(debt: list[i]),
            ),
          );
        },
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
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
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white)),
      ],
    );
  }
}

class _DebtCard extends ConsumerWidget {
  const _DebtCard({required this.debt});
  final Debt debt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = debt.status.color;
    final statusText = debt.status == DebtStatus.gecikti
        ? '${-debt.daysLeft} gün geçti'
        : debt.status == DebtStatus.odendi
            ? 'Ödendi'
            : '${debt.daysLeft} gün';

    return Card(
      color: color.withOpacity(0.10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withOpacity(0.55), width: 1.4),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openPayDialog(context, ref),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  debt.customerName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatCurrency(debt.remaining),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFC62828),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPayDialog(BuildContext context, WidgetRef ref) async {
    final amountCtl = TextEditingController();
    String? errorText;
    bool submitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ödeme — ${debt.customerName}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Kalan: ${formatCurrency(debt.remaining)}',
                  style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Ödenen tutar (₺)',
                  prefixIcon: const Icon(Icons.payments_outlined),
                  errorText: errorText,
                  helperText: 'En fazla ${formatCurrency(debt.remaining)}',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          amountCtl.text = debt.remaining.toStringAsFixed(2),
                      child: const Text('Tümünü doldur'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: submitting
                          ? null
                          : () async {
                              final raw =
                                  amountCtl.text.trim().replaceAll(',', '.');
                              final value = double.tryParse(raw);
                              if (value == null || value <= 0) {
                                setLocal(() => errorText = 'Geçerli bir tutar girin');
                                return;
                              }
                              if (value > debt.remaining + 0.005) {
                                setLocal(() =>
                                    errorText = 'Kalan borçtan fazla olamaz');
                                return;
                              }
                              setLocal(() {
                                submitting = true;
                                errorText = null;
                              });
                              try {
                                await ref
                                    .read(debtRepositoryProvider)
                                    .pay(customerId: debt.customerId, amount: value);
                                if (!ctx.mounted) return;
                                Navigator.of(ctx).pop();
                                ref.invalidate(allDebtsProvider);
                                ref.invalidate(debtSummaryProvider);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Ödeme kaydedildi')),
                                );
                              } on DioException catch (e) {
                                String msg = 'Ödeme kaydedilemedi';
                                final data = e.response?.data;
                                if (data is Map && data['detail'] is String) {
                                  msg = data['detail'] as String;
                                }
                                setLocal(() {
                                  submitting = false;
                                  errorText = msg;
                                });
                              } catch (e) {
                                setLocal(() {
                                  submitting = false;
                                  errorText = 'Beklenmeyen hata: $e';
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
