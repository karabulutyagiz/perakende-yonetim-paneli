import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/formatters.dart';
import '../data/report_repository.dart';

final _rangeDateFormat = DateFormat('dd.MM.yyyy', 'tr_TR');

enum ReportRangePreset { sevenDays, thirtyDays, ninetyDays, custom }

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportRangePreset _selectedPreset = ReportRangePreset.thirtyDays;
  DateTimeRange? _customRange;

  ReportQuery get _query {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_selectedPreset == ReportRangePreset.custom && _customRange != null) {
      return ReportQuery(
        fromDate: DateTime(
          _customRange!.start.year,
          _customRange!.start.month,
          _customRange!.start.day,
        ),
        toDate: DateTime(
          _customRange!.end.year,
          _customRange!.end.month,
          _customRange!.end.day,
        ),
      );
    }

    final days = switch (_selectedPreset) {
      ReportRangePreset.sevenDays => 7,
      ReportRangePreset.thirtyDays => 30,
      ReportRangePreset.ninetyDays => 90,
      ReportRangePreset.custom => 30,
    };

    return ReportQuery(
      fromDate: today.subtract(Duration(days: days - 1)),
      toDate: today,
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(reportSummaryProvider(_query));
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black, size: 32),
        titleSpacing: 4,
        title: const _SectionHeaderTitle(title: 'Raporlar'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(
          child: Text('Raporlar yüklenemedi. Lütfen tekrar deneyin.'),
        ),
        data: (r) {
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(reportSummaryProvider(_query)),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _RangeFilterBar(
                  selectedPreset: _selectedPreset,
                  customRange: _customRange,
                  onClear: () {
                    setState(() {
                      _customRange = null;
                      _selectedPreset = ReportRangePreset.thirtyDays;
                    });
                  },
                  onPresetChanged: (preset) async {
                    if (preset == ReportRangePreset.custom) {
                      await _pickCustomRange(context);
                      return;
                    }
                    setState(() => _selectedPreset = preset);
                  },
                ),
                const SizedBox(height: 16),
                _StatGrid(
                  items: [
                    _Stat('Toplam satış', formatCurrency(r.totalSales),
                        Icons.trending_up),
                    _Stat('Fatura', '${r.invoiceCount}', Icons.receipt_long),
                    _Stat('Müşteri', '${r.uniqueCustomers}',
                        Icons.people_outline),
                    _Stat('Düşük stok', '${r.lowStock}', Icons.warning_amber),
                  ],
                  columns: isTablet ? 4 : 2,
                ),
                const SizedBox(height: 16),
                if (isTablet)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _ReportCardSection(
                          title: 'Ödeme dağılımı',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _PaymentStatGrid(
                                items: [
                                  _PaymentStat(
                                    'Kart',
                                    formatCurrency(r.kart),
                                    theme.colorScheme.primary,
                                    Icons.credit_card_rounded,
                                  ),
                                  _PaymentStat(
                                    'Nakit',
                                    formatCurrency(r.nakit),
                                    theme.colorScheme.tertiary,
                                    Icons.payments_rounded,
                                  ),
                                  _PaymentStat(
                                    'Borç',
                                    formatCurrency(r.borc),
                                    theme.colorScheme.error,
                                    Icons.schedule_rounded,
                                  ),
                                ],
                                columns: 2,
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Borçlar',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _DebtSummaryCard(
                                outstandingDebt:
                                    formatCurrency(r.outstandingDebt),
                                overdueDebt: formatCurrency(r.overdueDebt),
                                accentColor: theme.colorScheme.error,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ReportCardSection(
                          title: 'Satış akışı',
                          child: SizedBox(
                            height: 330,
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
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.12),
                                    ),
                                    spots: [
                                      for (var i = 0;
                                          i < r.dailySales.length;
                                          i++)
                                        FlSpot(i.toDouble(),
                                            r.dailySales[i].value),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else ...[
                  const _SectionTitle('Ödeme dağılımı'),
                  _PaymentStatGrid(
                    items: [
                      _PaymentStat(
                        'Kart',
                        formatCurrency(r.kart),
                        theme.colorScheme.primary,
                        Icons.credit_card_rounded,
                      ),
                      _PaymentStat(
                        'Nakit',
                        formatCurrency(r.nakit),
                        theme.colorScheme.tertiary,
                        Icons.payments_rounded,
                      ),
                      _PaymentStat(
                        'Borç',
                        formatCurrency(r.borc),
                        theme.colorScheme.error,
                        Icons.schedule_rounded,
                      ),
                    ],
                    columns: 1,
                  ),
                  const SizedBox(height: 16),
                  const _SectionTitle('Borçlar'),
                  _DebtSummaryCard(
                    outstandingDebt: formatCurrency(r.outstandingDebt),
                    overdueDebt: formatCurrency(r.overdueDebt),
                    accentColor: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  const _SectionTitle('Satış akışı'),
                  SizedBox(
                    height: 220,
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
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.12),
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
                const SizedBox(height: 16),
                if (isTablet)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _SalesDetailsSection(
                          products: r.topProducts,
                          rangeLabel: _rangeLabel,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            if (r.topCustomers.isNotEmpty)
                              _ReportCardSection(
                                title: 'En çok alışveriş yapan müşteriler',
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
                            if (r.topCustomers.isNotEmpty &&
                                r.categoryBreakdown.isNotEmpty)
                              const SizedBox(height: 16),
                            if (r.categoryBreakdown.isNotEmpty)
                              _ReportCardSection(
                                title: 'Kategori satış performansı',
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
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  _SalesDetailsSection(
                    products: r.topProducts,
                    rangeLabel: _rangeLabel,
                  ),
                  if (r.topCustomers.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const _SectionTitle('En çok alışveriş yapan müşteriler'),
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
                    const _SectionTitle('Kategori satış performansı'),
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
              ],
            ),
          );
        },
      ),
    );
  }

  String get _rangeLabel {
    if (_selectedPreset == ReportRangePreset.custom && _customRange != null) {
      return '${_rangeDateFormat.format(_customRange!.start)} - ${_rangeDateFormat.format(_customRange!.end)}';
    }

    return switch (_selectedPreset) {
      ReportRangePreset.sevenDays => 'son 7 gün',
      ReportRangePreset.thirtyDays => 'son 30 gün',
      ReportRangePreset.ninetyDays => 'son 90 gün',
      ReportRangePreset.custom => 'özel tarih aralığı',
    };
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final initialRange = _customRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 29)),
          end: now,
        );
    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (context) => _CustomRangeDialog(initialRange: initialRange),
    );
    if (picked == null || !mounted) return;

    setState(() {
      _customRange = picked;
      _selectedPreset = ReportRangePreset.custom;
    });
  }
}

class _RangeFilterBar extends StatelessWidget {
  const _RangeFilterBar({
    required this.selectedPreset,
    required this.customRange,
    required this.onClear,
    required this.onPresetChanged,
  });

  final ReportRangePreset selectedPreset;
  final DateTimeRange? customRange;
  final VoidCallback onClear;
  final ValueChanged<ReportRangePreset> onPresetChanged;

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.of(context).size.width < 600;
    final options = <ReportRangePreset, String>{
      ReportRangePreset.sevenDays: 'Son 7 gün',
      ReportRangePreset.thirtyDays: 'Son 30 gün',
      ReportRangePreset.ninetyDays: 'Son 90 gün',
      ReportRangePreset.custom: customRange == null
          ? 'Tarih aralığı seç'
          : '${_rangeDateFormat.format(customRange!.start)} - ${_rangeDateFormat.format(customRange!.end)}',
    };
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isPhone ? 12 : 20),
        child: Wrap(
          spacing: isPhone ? 8 : 16,
          runSpacing: isPhone ? 8 : 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Dönem filtresi',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: isPhone ? 14 : 20,
                  ),
            ),
            for (final entry in options.entries)
              ChoiceChip(
                label: Text(entry.value),
                labelStyle: TextStyle(
                  fontSize: isPhone ? 11 : 17,
                  fontWeight: FontWeight.w700,
                ),
                selected: selectedPreset == entry.key,
                onSelected: (_) => onPresetChanged(entry.key),
                avatarBoxConstraints:
                    const BoxConstraints(minWidth: 0, minHeight: 0),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.symmetric(
                  horizontal: isPhone ? 10 : 18,
                  vertical: isPhone ? 8 : 16,
                ),
              ),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Temizle'),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(0, isPhone ? 36 : 64),
                padding: EdgeInsets.symmetric(
                  horizontal: isPhone ? 10 : 22,
                  vertical: isPhone ? 8 : 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeaderTitle extends StatelessWidget {
  const _SectionHeaderTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleLarge?.copyWith(
        color: Colors.black,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _SalesDetailsSection extends StatelessWidget {
  const _SalesDetailsSection(
      {required this.products, required this.rangeLabel});

  final List<TopProductSummary> products;
  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }
    return _ReportCardSection(
      title: 'Satış ayrıntıları',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final product in products.take(8)) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                product.productName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              subtitle: Text(
                '${_formatQuantity(product.quantitySold)} ${product.unit} satıldı',
              ),
              trailing: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 130),
                child: Text(
                  formatCurrency(product.totalRevenue),
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ),
            if (product != products.take(8).last) const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  String _formatQuantity(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }
}

class _CustomRangeDialog extends StatefulWidget {
  const _CustomRangeDialog({required this.initialRange});

  final DateTimeRange initialRange;

  @override
  State<_CustomRangeDialog> createState() => _CustomRangeDialogState();
}

class _CustomRangeDialogState extends State<_CustomRangeDialog> {
  late DateTime _startDate;
  late DateTime _endDate;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialRange.start;
    _endDate = widget.initialRange.end;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tarih aralığı seçin'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Başlangıç tarihi',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            _DateSelectionTile(
              value: _rangeDateFormat.format(_startDate),
              onTap: () => _pickDate(isStart: true),
            ),
            const SizedBox(height: 10),
            Text(
              'Bitiş tarihi',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            _DateSelectionTile(
              value: _rangeDateFormat.format(_endDate),
              onTap: () => _pickDate(isStart: false),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: _apply,
          child: const Text('Uygula'),
        ),
      ],
    );
  }

  void _apply() {
    if (_endDate.isBefore(_startDate)) {
      setState(() {
        _errorText = 'Bitiş tarihi, başlangıç tarihinden önce olamaz.';
      });
      return;
    }

    Navigator.of(context).pop(
      DateTimeRange(start: _startDate, end: _endDate),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final current = isStart ? _startDate : _endDate;
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => _MiniCalendarDialog(initialDate: current),
    );
    if (picked == null || !mounted) return;

    setState(() {
      if (isStart) {
        _startDate = DateTime(picked.year, picked.month, picked.day);
      } else {
        _endDate = DateTime(picked.year, picked.month, picked.day);
      }
      _errorText = null;
    });
  }
}

class _DateSelectionTile extends StatelessWidget {
  const _DateSelectionTile({required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(child: Text(value)),
            const SizedBox(width: 12),
            const Icon(Icons.calendar_month_rounded),
          ],
        ),
      ),
    );
  }
}

class _MiniCalendarDialog extends StatefulWidget {
  const _MiniCalendarDialog({required this.initialDate});

  final DateTime initialDate;

  @override
  State<_MiniCalendarDialog> createState() => _MiniCalendarDialogState();
}

class _MiniCalendarDialogState extends State<_MiniCalendarDialog> {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;

  DateTime get _firstDate => DateTime(DateTime.now().year - 3, 1, 1);
  DateTime get _lastDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = _clampToBounds(widget.initialDate);
    _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      contentPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: _previousMonth,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      DateFormat('MMMM', 'tr_TR').format(_displayedMonth),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
                PopupMenuButton<int>(
                  initialValue: _displayedMonth.year,
                  tooltip: 'Yıl seç',
                  onSelected: _selectYear,
                  itemBuilder: (context) {
                    final years = [
                      for (int y = _lastDate.year; y >= _firstDate.year; y--) y,
                    ];
                    return [
                      for (final year in years)
                        PopupMenuItem<int>(
                          value: year,
                          child: Row(
                            children: [
                              Expanded(child: Text('$year')),
                              if (year == _displayedMonth.year)
                                const Icon(Icons.check_rounded, size: 18),
                            ],
                          ),
                        ),
                    ];
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${_displayedMonth.year}'),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down_rounded),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _nextMonth,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            CalendarDatePicker(
              initialDate: _selectedDate,
              firstDate: _firstDate,
              lastDate: _lastDate,
              currentDate: DateTime.now(),
              onDisplayedMonthChanged: (value) {
                setState(() {
                  _displayedMonth = DateTime(value.year, value.month);
                });
              },
              onDateChanged: (value) {
                setState(() {
                  _selectedDate = value;
                  _displayedMonth = DateTime(value.year, value.month);
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedDate),
          child: const Text('Seç'),
        ),
      ],
    );
  }

  void _previousMonth() {
    final candidate = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
    if (candidate.isBefore(DateTime(_firstDate.year, _firstDate.month))) return;
    setState(() {
      _displayedMonth = candidate;
      _selectedDate = _clampToBounds(DateTime(
        candidate.year,
        candidate.month,
        _selectedDate.day.clamp(
            1, DateUtils.getDaysInMonth(candidate.year, candidate.month)),
      ));
    });
  }

  void _nextMonth() {
    final candidate = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
    if (candidate.isAfter(DateTime(_lastDate.year, _lastDate.month))) return;
    setState(() {
      _displayedMonth = candidate;
      _selectedDate = _clampToBounds(DateTime(
        candidate.year,
        candidate.month,
        _selectedDate.day.clamp(
            1, DateUtils.getDaysInMonth(candidate.year, candidate.month)),
      ));
    });
  }

  void _selectYear(int year) {
    final month = _displayedMonth.month;
    final day =
        _selectedDate.day.clamp(1, DateUtils.getDaysInMonth(year, month));
    setState(() {
      _displayedMonth = DateTime(year, month);
      _selectedDate = _clampToBounds(DateTime(year, month, day));
      _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month);
    });
  }

  DateTime _clampToBounds(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    if (normalized.isBefore(_firstDate)) return _firstDate;
    if (normalized.isAfter(_lastDate)) return _lastDate;
    return normalized;
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
  const _StatGrid({required this.items, required this.columns});

  final List<_Stat> items;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveColumns = columns <= 1 ? 1 : columns;
        final gaps = 12.0 * (effectiveColumns - 1);
        final cardWidth = (constraints.maxWidth - gaps) / effectiveColumns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final it in items)
              SizedBox(
                width: cardWidth,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(it.icon,
                                color: theme.colorScheme.primary, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                it.label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
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

class _PaymentStat {
  const _PaymentStat(this.label, this.value, this.color, this.icon);

  final String label;
  final String value;
  final Color color;
  final IconData icon;
}

class _PaymentStatGrid extends StatelessWidget {
  const _PaymentStatGrid({required this.items, required this.columns});

  final List<_PaymentStat> items;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveColumns = columns <= 1 ? 1 : columns;
        final gaps = 12.0 * (effectiveColumns - 1);
        final cardWidth = (constraints.maxWidth - gaps) / effectiveColumns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final item in items)
              SizedBox(
                width: cardWidth,
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(item.icon, color: item.color, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          item.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: item.color,
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

class _DebtSummaryCard extends StatelessWidget {
  const _DebtSummaryCard({
    required this.outstandingDebt,
    required this.overdueDebt,
    required this.accentColor,
  });

  final String outstandingDebt;
  final String overdueDebt;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Açık toplam borç',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    outstandingDebt,
                    textAlign: TextAlign.end,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Geciken borç',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    overdueDebt,
                    textAlign: TextAlign.end,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCardSection extends StatelessWidget {
  const _ReportCardSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
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
