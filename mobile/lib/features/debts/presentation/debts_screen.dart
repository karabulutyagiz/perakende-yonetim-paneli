import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../data/debt.dart';
import '../data/debt_repository.dart';

class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(debtSummaryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Borçlular')),
      body: summary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Açık borç yok'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(debtSummaryProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _CustomerDebtCard(summary: list[i]),
            ),
          );
        },
      ),
    );
  }
}

class _CustomerDebtCard extends ConsumerWidget {
  const _CustomerDebtCard({required this.summary});
  final CustomerDebtSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: () => _openDetails(context, ref),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      summary.customerName,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    formatCurrency(summary.remaining),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${summary.debtsCount} açık borç · '
                'Ödenen: ${formatCurrency(summary.paid)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDetails(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _DebtDetails(customerId: summary.customerId, name: summary.customerName),
    );
    ref.invalidate(debtSummaryProvider);
  }
}

class _DebtDetails extends ConsumerStatefulWidget {
  const _DebtDetails({required this.customerId, required this.name});
  final String customerId;
  final String name;

  @override
  ConsumerState<_DebtDetails> createState() => _DebtDetailsState();
}

class _DebtDetailsState extends ConsumerState<_DebtDetails> {
  final _amount = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    final value = double.tryParse(_amount.text.replaceAll(',', '.'));
    if (value == null || value <= 0) return;
    try {
      await ref.read(debtRepositoryProvider).pay(
            customerId: widget.customerId,
            amount: value,
          );
      if (!mounted) return;
      ref.invalidate(debtsProvider(widget.customerId));
      ref.invalidate(debtSummaryProvider);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(debtsProvider(widget.customerId));
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, scroll) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.name, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 12),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Hata: $e'),
                data: (debts) => ListView.separated(
                  controller: scroll,
                  itemCount: debts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _DebtTile(debt: debts[i]),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Ödenen Borç (₺)',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _pay,
              child: const Text('Ödemeyi Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebtTile extends StatelessWidget {
  const _DebtTile({required this.debt});
  final Debt debt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = debt.status.color;
    final statusText = debt.status == DebtStatus.gecikti
        ? debt.overdueLabel
        : debt.status == DebtStatus.odendi
            ? 'Ödendi'
            : '${debt.daysLeft} gün kaldı';

    return Card(
      color: color.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withOpacity(0.5), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kalan: ${formatCurrency(debt.remaining)}',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text('Vade: ${formatDate(debt.dueOn)}',
                      style: theme.textTheme.bodySmall),
                  Text(statusText,
                      style: theme.textTheme.bodySmall?.copyWith(color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
