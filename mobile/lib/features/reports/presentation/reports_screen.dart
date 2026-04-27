import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../data/report_repository.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reportSummaryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Rapor')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (r) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(reportSummaryProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatGrid(
                items: [
                  _Stat('Toplam Satış', formatCurrency(r.totalSales), Icons.trending_up),
                  _Stat('Fatura', '${r.invoiceCount}', Icons.receipt_long),
                  _Stat('Müşteri', '${r.uniqueCustomers}', Icons.people_outline),
                  _Stat('Düşük Stok', '${r.lowStock}', Icons.warning_amber),
                ],
              ),
              const SizedBox(height: 16),
              _SectionTitle('Ödeme Dağılımı'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _paymentRow('Kart', r.kart, theme.colorScheme.primary),
                      _paymentRow('Nakit', r.nakit, theme.colorScheme.tertiary),
                      _paymentRow('Borç', r.borc, theme.colorScheme.error),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Açık Toplam Borç'),
                          Text(formatCurrency(r.outstandingDebt),
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Geciken Borç'),
                          Text(
                            formatCurrency(r.overdueDebt),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (r.dailySales.isNotEmpty) ...[
                const SizedBox(height: 16),
                _SectionTitle('Günlük Satış'),
                SizedBox(
                  height: 200,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              isCurved: true,
                              color: theme.colorScheme.primary,
                              barWidth: 3,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: theme.colorScheme.primary.withOpacity(0.12),
                              ),
                              spots: [
                                for (var i = 0; i < r.dailySales.length; i++)
                                  FlSpot(i.toDouble(), r.dailySales[i].value),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              if (r.topCustomers.isNotEmpty) ...[
                const SizedBox(height: 16),
                _SectionTitle('En Çok Alan Müşteriler'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        for (final e in r.topCustomers.take(5))
                          ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: Text(e.key),
                            trailing: Text(formatCurrency(e.value)),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              if (r.categoryBreakdown.isNotEmpty) ...[
                const SizedBox(height: 16),
                _SectionTitle('Kategori Kırılımı'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        for (final e in r.categoryBreakdown)
                          ListTile(
                            leading: const Icon(Icons.category_outlined),
                            title: Text(e.key),
                            trailing: Text(formatCurrency(e.value)),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _paymentRow(String label, double value, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(label)),
            Text(formatCurrency(value),
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      );
}

class _Stat {
  const _Stat(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.items});
  final List<_Stat> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        for (final it in items)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(it.icon, color: theme.colorScheme.primary),
                  const SizedBox(height: 8),
                  Text(it.label, style: theme.textTheme.bodySmall),
                  Text(
                    it.value,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
