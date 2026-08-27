import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_shell.dart';
import '../data/debt.dart';
import '../data/debt_repository.dart';

final _debtDt = DateFormat('dd.MM.yyyy', 'tr_TR');

class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allDebtsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      drawer: const AppDrawer(current: '/debts'),
      appBar: const PsAppBar(title: 'Borçlar'),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: 'Borçlar yüklenemedi. Lütfen tekrar deneyin.',
          onRetry: () => ref.invalidate(allDebtsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.task_alt_rounded,
              title: 'Açık borç yok',
              subtitle: 'Tüm borçlar ödenmiş görünüyor. Harika!',
            );
          }
          final totalRemaining =
              list.fold<double>(0, (a, d) => a + d.remaining);
          final overdue =
              list.where((d) => d.status == DebtStatus.gecikti).length;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(allDebtsProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                // Özet kartı
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Toplam kalan borç',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                formatCurrency(totalRemaining),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _SummaryPill(
                              label: '${list.length} açık borç',
                              color: Colors.white.withValues(alpha: 0.18)),
                          if (overdue > 0) ...[
                            const SizedBox(height: 6),
                            _SummaryPill(
                              label: '$overdue gecikmiş',
                              color: AppColors.danger,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Renk açıklaması
                const Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    _LegendDot(color: AppTheme.debtGreen, label: '8+ gün'),
                    _LegendDot(color: AppTheme.debtYellow, label: '4–7 gün'),
                    _LegendDot(color: AppTheme.debtRed, label: '0–3 gün'),
                    _LegendDot(color: AppTheme.debtOverdue, label: 'Gecikti'),
                  ],
                ),
                const SizedBox(height: 12),
                for (final debt in list) ...[
                  _DebtCard(debt: debt),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 8),
                Text(
                  'Bir borca dokunarak ödeme alabilirsin.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
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
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
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
    final statusColor = debt.status.color;
    final isOverdue = debt.status == DebtStatus.gecikti;
    final progress = debt.totalAmount <= 0
        ? 0.0
        : (debt.paidAmount / debt.totalAmount).clamp(0.0, 1.0);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openPaySheet(context, ref),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Durum şeridi
              Container(width: 5, color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              debt.customerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isOverdue
                                  ? debt.overdueLabel
                                  : '${debt.daysLeft} gün kaldı',
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _AmountLabel(
                              label: 'Kalan',
                              value: formatCurrency(debt.remaining),
                              emphasized: true,
                            ),
                          ),
                          Expanded(
                            child: _AmountLabel(
                              label: 'Ödenen',
                              value: formatCurrency(debt.paidAmount),
                            ),
                          ),
                          Expanded(
                            child: _AmountLabel(
                              label: 'Toplam',
                              value: formatCurrency(debt.totalAmount),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: AppColors.bg,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(statusColor),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vade: ${_debtDt.format(debt.dueOn.toLocal())}'
                        '${debt.lastPaymentOn != null ? ' · Son ödeme: ${_debtDt.format(debt.lastPaymentOn!.toLocal())}' : ''}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPaySheet(BuildContext context, WidgetRef ref) async {
    final amountCtl = TextEditingController();
    String? errorText;
    bool submitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 4,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ödeme al — ${debt.customerName}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Kalan: ${formatCurrency(debt.remaining)}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Ödenen tutar (₺)',
                  prefixIcon: const Icon(Icons.payments_outlined),
                  errorText: errorText,
                  helperText: 'En fazla ${formatCurrency(debt.remaining)}',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          amountCtl.text = debt.remaining.toStringAsFixed(2),
                      child: const Text('Tümünü doldur'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: submitting
                          ? null
                          : () async {
                              final raw =
                                  amountCtl.text.trim().replaceAll(',', '.');
                              final value = double.tryParse(raw);
                              if (value == null || value <= 0) {
                                setLocal(() =>
                                    errorText = 'Geçerli bir tutar girin');
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
                                await ref.read(debtRepositoryProvider).pay(
                                    customerId: debt.customerId,
                                    amount: value);
                                if (!ctx.mounted) return;
                                Navigator.of(ctx).pop();
                                ref.invalidate(allDebtsProvider);
                                ref.invalidate(debtSummaryProvider);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Ödeme kaydedildi')),
                                );
                              } on DioException catch (e) {
                                String msg = 'Ödeme kaydedilemedi';
                                final data = e.response?.data;
                                if (data is Map &&
                                    data['detail'] is String) {
                                  msg = data['detail'] as String;
                                }
                                setLocal(() {
                                  submitting = false;
                                  errorText = msg;
                                });
                              } catch (e) {
                                setLocal(() {
                                  submitting = false;
                                  errorText = 'Beklenmeyen bir hata oluştu';
                                });
                              }
                            },
                      child: submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Ödemeyi kaydet'),
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

class _AmountLabel extends StatelessWidget {
  const _AmountLabel({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: emphasized ? 15 : 13,
              fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
              color: emphasized ? AppColors.primary : AppColors.text,
            ),
          ),
        ),
      ],
    );
  }
}
