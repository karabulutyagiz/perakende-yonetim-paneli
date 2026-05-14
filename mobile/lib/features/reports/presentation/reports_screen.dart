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
      appBar: AppBar(title: const Text('Raporlar')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(
          child: Text('Raporlar yüklenemedi. Lütfen tekrar deneyin.'),
        ),
        data: (r) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(reportSummaryProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatGrid(
                items: [
                  _Stat('Toplam satış', formatCurrency(r.totalSales),
                      Icons.trending_up),
                  _Stat('Fatura', '${r.invoiceCount}', Icons.receipt_long),
                  _Stat(
                      'Müşteri', '${r.uniqueCustomers}', Icons.people_outline),
                  _Stat('Düşük stok', '${r.lowStock}', Icons.warning_amber),
                ],
              ),
              const SizedBox(height: 16),
              _SectionTitle('Ödeme dağılımı'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _paymentRow('Kart', r.kart, theme.colorScheme.primary),
                      _paymentRow('Nakit', r.nakit, theme.colorScheme.tertiary),
                      _paymentRow('Borç', r.borc, theme.colorScheme.error),
                      const SizedBox(height: 12),
                      _summaryRow(
                        context,
                        label: 'Açık toplam borç',
                        value: formatCurrency(r.outstandingDebt),
                      ),
                      _summaryRow(
                        context,
                        label: 'Geciken borç',
                        value: formatCurrency(r.overdueDebt),
                        valueColor: theme.colorScheme.error,
                      ),
                    ],
                  ),
                ),
              ),
              if (r.dailySales.isNotEmpty) ...[
                const SizedBox(height: 16),
                _SectionTitle('Günlük satış'),
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
                                color:
                                    theme.colorScheme.primary.withOpacity(0.12),
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
                _SectionTitle('En çok alışveriş yapan müşteriler'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        for (final e in r.topCustomers.take(5))
                          _listMetricTile(
                            icon: Icons.person_outline,
                            label: e.key,
                            value: formatCurrency(e.value),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              if (r.categoryBreakdown.isNotEmpty) ...[
                const SizedBox(height: 16),
                _SectionTitle('Kategori kırılımı'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        for (final e in r.categoryBreakdown)
                          _listMetricTile(
                            icon: Icons.category_outlined,
                            label: e.key,
                            value: formatCurrency(e.value),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                formatCurrency(value),
                textAlign: TextAlign.end,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );

  Widget _summaryRow(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final valueStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: valueColor,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _listMetricTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon),
      minVerticalPadding: 10,
      title: Text(
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 110),
        child: Text(
          value,
          textAlign: TextAlign.end,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;
        final cardWidth =
            isNarrow ? constraints.maxWidth : (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final it in items)
              SizedBox(
                width: cardWidth,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(it.icon,
                                color: theme.colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                it.label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            it.value,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
