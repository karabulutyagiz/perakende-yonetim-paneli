import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api.dart';

class ReportRange {
  const ReportRange(this.fromDate, this.toDate, this.label);
  final DateTime fromDate;
  final DateTime toDate;
  final String label;
}

ReportRange _rangeLastNDays(int n, String label) {
  final to = DateTime.now();
  final from = to.subtract(Duration(days: n - 1));
  return ReportRange(
    DateTime(from.year, from.month, from.day),
    DateTime(to.year, to.month, to.day),
    label,
  );
}

ReportRange _rangeThisMonth() {
  final now = DateTime.now();
  return ReportRange(
    DateTime(now.year, now.month, 1),
    DateTime(now.year, now.month, now.day),
    'Bu ay',
  );
}

ReportRange _rangeLastMonth() {
  final now = DateTime.now();
  final firstOfThis = DateTime(now.year, now.month, 1);
  final lastOfPrev = firstOfThis.subtract(const Duration(days: 1));
  final firstOfPrev = DateTime(lastOfPrev.year, lastOfPrev.month, 1);
  return ReportRange(firstOfPrev, lastOfPrev, 'Geçen ay');
}

final selectedRangeProvider = StateProvider<ReportRange>(
    (_) => _rangeLastNDays(30, 'Son 30 gün'));

final reportProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final range = ref.watch(selectedRangeProvider);
  final fmt = DateFormat('yyyy-MM-dd');
  final resp = await ref.watch(dioProvider).get(
    '/reports/summary',
    queryParameters: {
      'from_date': fmt.format(range.fromDate),
      'to_date': fmt.format(range.toDate),
    },
  );
  return resp.data as Map<String, dynamic>;
});

final _tl = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
final _qtyFmt = NumberFormat('#,##0.##', 'tr_TR');
final _dayFmt = DateFormat('dd MMM', 'tr_TR');
final _monthFmt = DateFormat('MMM yyyy', 'tr_TR');

const _green = Color(0xFF0E6E4E);
const _red = Color(0xFFC62828);
const _orange = Color(0xFFE65100);
const _blue = Color(0xFF1565C0);

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reportProvider);
    final range = ref.watch(selectedRangeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Raporlar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed: () => ref.invalidate(reportProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          _RangeBar(active: range),
          Expanded(
            child: async.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Hata: $e')),
              data: (r) => _ReportBody(report: r, range: range),
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeBar extends ConsumerWidget {
  const _RangeBar({required this.active});
  final ReportRange active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ranges = <ReportRange>[
      _rangeLastNDays(7, 'Son 7 gün'),
      _rangeLastNDays(30, 'Son 30 gün'),
      _rangeLastNDays(90, 'Son 90 gün'),
      _rangeThisMonth(),
      _rangeLastMonth(),
      _rangeLastNDays(365, 'Son 1 yıl'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: const Color(0xFFF5F5F5),
      child: Row(
        children: [
          const Text('Tarih aralığı: ',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8,
              children: [
                for (final r in ranges)
                  ChoiceChip(
                    label: Text(r.label),
                    selected: r.label == active.label,
                    onSelected: (s) {
                      if (s) {
                        ref.read(selectedRangeProvider.notifier).state = r;
                      }
                    },
                  ),
              ],
            ),
          ),
          Text(
            '${DateFormat("dd.MM.yyyy").format(active.fromDate)} → '
            '${DateFormat("dd.MM.yyyy").format(active.toDate)}',
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.report, required this.range});
  final Map<String, dynamic> report;
  final ReportRange range;

  double _d(dynamic v) => (v as num?)?.toDouble() ?? 0;

  @override
  Widget build(BuildContext context) {
    final byPay = report['by_payment'] as Map<String, dynamic>? ?? {};
    final cats = (report['category_breakdown'] as List?) ?? [];
    final topCusts = (report['top_customers'] as List?) ?? [];
    final topProds = (report['top_products'] as List?) ?? [];
    final daily = (report['daily_sales'] as List?) ?? [];
    final monthly = (report['monthly_sales'] as List?) ?? [];

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Üst rakamlar — özet kartları
        _SectionTitle('Genel Özet', subtitle: range.label),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _StatCard(
              label: 'Toplam Satış',
              value: _tl.format(_d(report['total_sales'])),
              icon: Icons.trending_up,
              color: _green,
            ),
            _StatCard(
              label: 'Fatura Sayısı',
              value: '${report['invoice_count'] ?? 0}',
              icon: Icons.receipt_long,
              color: _blue,
            ),
            _StatCard(
              label: 'Tekil Müşteri',
              value: '${report['unique_customers'] ?? 0}',
              icon: Icons.people,
              color: _blue,
            ),
            _StatCard(
              label: 'Ortalama Fatura',
              value: report['invoice_count'] != null &&
                      (report['invoice_count'] as int) > 0
                  ? _tl.format(
                      _d(report['total_sales']) /
                          (report['invoice_count'] as int))
                  : '—',
              icon: Icons.calculate_outlined,
              color: _green,
            ),
            _StatCard(
              label: 'Açık Borç',
              value: _tl.format(_d(report['outstanding_debt'])),
              icon: Icons.schedule,
              color: _orange,
            ),
            _StatCard(
              label: 'Geciken Borç',
              value: _tl.format(_d(report['overdue_debt'])),
              icon: Icons.error_outline,
              color: _red,
            ),
            _StatCard(
              label: 'Düşük Stok Ürün',
              value: '${report['low_stock_products'] ?? 0}',
              icon: Icons.warning_amber,
              color: _orange,
            ),
          ],
        ),

        const SizedBox(height: 32),
        _SectionTitle('Ödeme Yöntemine Göre Dağılım',
            icon: Icons.pie_chart_outline),
        const SizedBox(height: 12),
        _PaymentBreakdown(
          kart: _d(byPay['kart']),
          nakit: _d(byPay['nakit']),
          borc: _d(byPay['borc']),
          total: _d(report['total_sales']),
        ),

        const SizedBox(height: 32),
        if (topProds.isNotEmpty) ...[
          _SectionTitle('En Çok Satan Ürünler',
              icon: Icons.emoji_events_outlined,
              subtitle: '${topProds.length} ürün'),
          const SizedBox(height: 12),
          _TopProductsTable(products: topProds.cast<Map<String, dynamic>>()),
          const SizedBox(height: 32),
        ],

        if (topCusts.isNotEmpty) ...[
          _SectionTitle('En Çok Alan Müşteriler',
              icon: Icons.shopping_cart_outlined,
              subtitle: '${topCusts.length} müşteri'),
          const SizedBox(height: 12),
          _TopCustomersTable(
              customers: topCusts.cast<Map<String, dynamic>>()),
          const SizedBox(height: 32),
        ],

        if (cats.isNotEmpty) ...[
          _SectionTitle('Kategori Dağılımı', icon: Icons.category_outlined),
          const SizedBox(height: 12),
          _CategoryTable(categories: cats.cast<Map<String, dynamic>>()),
          const SizedBox(height: 32),
        ],

        if (monthly.isNotEmpty) ...[
          _SectionTitle('Aylık Satış Trendi',
              icon: Icons.calendar_month_outlined,
              subtitle: 'Tüm zamanlar'),
          const SizedBox(height: 12),
          _MonthlyChart(months: monthly.cast<Map<String, dynamic>>()),
          const SizedBox(height: 32),
        ],

        if (daily.isNotEmpty) ...[
          _SectionTitle('Günlük Satış',
              icon: Icons.show_chart, subtitle: range.label),
          const SizedBox(height: 12),
          _DailyChart(days: daily.cast<Map<String, dynamic>>()),
          const SizedBox(height: 48),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.icon, this.subtitle});
  final String title;
  final IconData? icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, color: _green, size: 22),
          const SizedBox(width: 8),
        ],
        Text(title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800)),
        if (subtitle != null) ...[
          const SizedBox(width: 12),
          Text('· $subtitle',
              style: const TextStyle(color: Colors.black54, fontSize: 13)),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                          color: Colors.black54, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentBreakdown extends StatelessWidget {
  const _PaymentBreakdown({
    required this.kart,
    required this.nakit,
    required this.borc,
    required this.total,
  });
  final double kart, nakit, borc, total;

  Widget _row(String label, IconData icon, double value, Color color) {
    final pct = total > 0 ? value / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              Text(_tl.format(value),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(width: 12),
              SizedBox(
                width: 60,
                child: Text(
                  '%${(pct * 100).toStringAsFixed(1)}',
                  textAlign: TextAlign.right,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _row('Kart', Icons.credit_card, kart, _blue),
            _row('Nakit', Icons.payments_outlined, nakit, _green),
            _row('Borç', Icons.schedule, borc, _red),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  child: Text('Toplam',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
                Text(_tl.format(total),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopProductsTable extends ConsumerWidget {
  const _TopProductsTable({required this.products});
  final List<Map<String, dynamic>> products;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxRev = products.isEmpty
        ? 0.0
        : (products.first['total_revenue'] as num).toDouble();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final p = products[i];
          final revenue = (p['total_revenue'] as num).toDouble();
          final qty = (p['quantity_sold'] as num).toDouble();
          final pct = maxRev > 0 ? revenue / maxRev : 0.0;
          final isFirst = i == 0;
          return InkWell(
            onTap: () => _showProductCustomers(context, ref, p),
            child: Container(
              color: isFirst ? const Color(0xFFFFF8E1) : null,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      '#${i + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isFirst ? Colors.amber.shade800 : Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['product_name'] as String,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 4,
                            backgroundColor: const Color(0xFFEEEEEE),
                            valueColor:
                                const AlwaysStoppedAnimation(_green),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${_qtyFmt.format(qty)} ${p['unit']}',
                      style: const TextStyle(
                          color: Colors.black54, fontSize: 13),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 110,
                    child: Text(
                      _tl.format(revenue),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.black38),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showProductCustomers(
      BuildContext context, WidgetRef ref, Map<String, dynamic> product) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ProductCustomersSheet(product: product),
    );
  }
}


class _ProductCustomersSheet extends ConsumerWidget {
  const _ProductCustomersSheet({required this.product});
  final Map<String, dynamic> product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = product['product_id'] as String;
    final asyncCustomers = ref.watch(_productCustomersProvider(id));
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_basket_outlined, color: _green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    product['product_name'] as String,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Bu ürünü en çok alan işletmeler',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: asyncCustomers.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Hata: $e')),
                data: (rows) {
                  if (rows.isEmpty) {
                    return const Center(child: Text('Henüz alım yok'));
                  }
                  final maxTot = (rows.first['total'] as num).toDouble();
                  return ListView.separated(
                    controller: scrollCtrl,
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final row = rows[i];
                      final tot = (row['total'] as num).toDouble();
                      final qty = (row['quantity'] as num).toDouble();
                      final pct = maxTot > 0 ? tot / maxTot : 0.0;
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: _blue.withOpacity(0.15),
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                                color: _blue, fontWeight: FontWeight.w700),
                          ),
                        ),
                        title: Text(row['customer_name'] as String,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 4,
                              backgroundColor: const Color(0xFFEEEEEE),
                              valueColor:
                                  const AlwaysStoppedAnimation(_blue),
                            ),
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _tl.format(tot),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '${_qtyFmt.format(qty)} ${product['unit']}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            ),
                          ],
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
}


final _productCustomersProvider =
    FutureProvider.family.autoDispose<List<Map<String, dynamic>>, String>(
        (ref, productId) async {
  final resp = await ref
      .watch(dioProvider)
      .get('/reports/products/$productId/top-customers');
  return (resp.data as List).cast<Map<String, dynamic>>();
});


final _customerProductsProvider =
    FutureProvider.family.autoDispose<List<Map<String, dynamic>>, String>(
        (ref, customerId) async {
  final resp = await ref
      .watch(dioProvider)
      .get('/reports/customers/$customerId/top-products');
  return (resp.data as List).cast<Map<String, dynamic>>();
});

class _TopCustomersTable extends ConsumerWidget {
  const _TopCustomersTable({required this.customers});
  final List<Map<String, dynamic>> customers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxTotal = customers.isEmpty
        ? 0.0
        : (customers.first['total'] as num).toDouble();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: customers.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final c = customers[i];
          final total = (c['total'] as num).toDouble();
          final invoiceCount = c['invoice_count'] as int? ?? 0;
          final pct = maxTotal > 0 ? total / maxTotal : 0.0;
          final isFirst = i == 0;
          return InkWell(
            onTap: () => _showCustomerProducts(context, ref, c),
            child: Container(
              color: isFirst ? const Color(0xFFFFF8E1) : null,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      '#${i + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isFirst ? Colors.amber.shade800 : Colors.grey,
                      ),
                    ),
                  ),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: _green.withOpacity(0.15),
                    child: Text(
                      (c['customer_name'] as String).isNotEmpty
                          ? (c['customer_name'] as String)[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: _green, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c['customer_name'] as String,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 4,
                            backgroundColor: const Color(0xFFEEEEEE),
                            valueColor:
                                const AlwaysStoppedAnimation(_blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 80,
                    child: Text(
                      '$invoiceCount fatura',
                      style: const TextStyle(
                          color: Colors.black54, fontSize: 13),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 110,
                    child: Text(
                      _tl.format(total),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.black38),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCustomerProducts(
      BuildContext context, WidgetRef ref, Map<String, dynamic> customer) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CustomerProductsSheet(customer: customer),
    );
  }
}


class _CustomerProductsSheet extends ConsumerWidget {
  const _CustomerProductsSheet({required this.customer});
  final Map<String, dynamic> customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = customer['customer_id'] as String;
    final asyncProducts = ref.watch(_customerProductsProvider(id));
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storefront, color: _green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    customer['customer_name'] as String,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Bu işletmenin en çok aldığı ürünler',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: asyncProducts.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Hata: $e')),
                data: (rows) {
                  if (rows.isEmpty) {
                    return const Center(child: Text('Henüz alım yok'));
                  }
                  final maxTot = (rows.first['total'] as num).toDouble();
                  return ListView.separated(
                    controller: scrollCtrl,
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final row = rows[i];
                      final tot = (row['total'] as num).toDouble();
                      final qty = (row['quantity'] as num).toDouble();
                      final pct = maxTot > 0 ? tot / maxTot : 0.0;
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: _green.withOpacity(0.15),
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                                color: _green, fontWeight: FontWeight.w700),
                          ),
                        ),
                        title: Text(row['product_name'] as String,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 4,
                              backgroundColor: const Color(0xFFEEEEEE),
                              valueColor:
                                  const AlwaysStoppedAnimation(_green),
                            ),
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_tl.format(tot),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800)),
                            Text(
                              '${_qtyFmt.format(qty)} ${row['unit']}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            ),
                          ],
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
}

class _CategoryTable extends StatelessWidget {
  const _CategoryTable({required this.categories});
  final List<Map<String, dynamic>> categories;

  @override
  Widget build(BuildContext context) {
    final maxTotal = categories.isEmpty
        ? 0.0
        : (categories.first['total'] as num).toDouble();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final c = categories[i];
          final total = (c['total'] as num).toDouble();
          final qty = (c['quantity'] as num).toDouble();
          final pct = maxTotal > 0 ? total / maxTotal : 0.0;
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c['category_name'] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 4,
                          backgroundColor: const Color(0xFFEEEEEE),
                          valueColor:
                              const AlwaysStoppedAnimation(_orange),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('${_qtyFmt.format(qty)} adet/birim',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          color: Colors.black54, fontSize: 13)),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 110,
                  child: Text(
                    _tl.format(total),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  const _MonthlyChart({required this.months});
  final List<Map<String, dynamic>> months;

  @override
  Widget build(BuildContext context) {
    final maxTotal = months
        .map((m) => (m['total'] as num).toDouble())
        .fold<double>(0, (a, b) => a > b ? a : b);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            for (final m in months)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        _formatMonth(m['month'] as String),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: maxTotal > 0
                                  ? (m['total'] as num).toDouble() / maxTotal
                                  : 0,
                              minHeight: 22,
                              backgroundColor: const Color(0xFFF5F5F5),
                              valueColor:
                                  const AlwaysStoppedAnimation(_green),
                            ),
                          ),
                          Positioned.fill(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${m['invoice_count']} fatura',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    _tl.format(
                                        (m['total'] as num).toDouble()),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatMonth(String yyyymm) {
    try {
      final parts = yyyymm.split('-');
      final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]));
      return _monthFmt.format(dt);
    } catch (_) {
      return yyyymm;
    }
  }
}

class _DailyChart extends StatelessWidget {
  const _DailyChart({required this.days});
  final List<Map<String, dynamic>> days;

  @override
  Widget build(BuildContext context) {
    final maxTotal = days
        .map((m) => (m['total'] as num).toDouble())
        .fold<double>(0, (a, b) => a > b ? a : b);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final d in days)
                Expanded(
                  child: Tooltip(
                    message:
                        '${d['day']}\n${_tl.format((d['total'] as num).toDouble())}',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: maxTotal > 0
                                ? (140 *
                                    (d['total'] as num).toDouble() /
                                    maxTotal)
                                : 0,
                            decoration: BoxDecoration(
                              color: _green,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDay(d['day'] as String),
                            style: const TextStyle(
                                fontSize: 9, color: Colors.black54),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDay(String yyyymmdd) {
    try {
      return _dayFmt.format(DateTime.parse(yyyymmdd));
    } catch (_) {
      return yyyymmdd;
    }
  }
}
