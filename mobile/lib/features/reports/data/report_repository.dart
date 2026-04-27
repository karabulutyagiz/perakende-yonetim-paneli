import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';

class ReportSummary {
  ReportSummary({
    required this.totalSales,
    required this.invoiceCount,
    required this.uniqueCustomers,
    required this.kart,
    required this.nakit,
    required this.borc,
    required this.outstandingDebt,
    required this.overdueDebt,
    required this.lowStock,
    required this.topCustomers,
    required this.dailySales,
    required this.categoryBreakdown,
  });

  final double totalSales;
  final int invoiceCount;
  final int uniqueCustomers;
  final double kart;
  final double nakit;
  final double borc;
  final double outstandingDebt;
  final double overdueDebt;
  final int lowStock;
  final List<MapEntry<String, double>> topCustomers;
  final List<MapEntry<DateTime, double>> dailySales;
  final List<MapEntry<String, double>> categoryBreakdown;

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    final pay = json['by_payment'] as Map<String, dynamic>;
    return ReportSummary(
      totalSales: (json['total_sales'] as num).toDouble(),
      invoiceCount: json['invoice_count'] as int,
      uniqueCustomers: json['unique_customers'] as int,
      kart: (pay['kart'] as num).toDouble(),
      nakit: (pay['nakit'] as num).toDouble(),
      borc: (pay['borc'] as num).toDouble(),
      outstandingDebt: (json['outstanding_debt'] as num).toDouble(),
      overdueDebt: (json['overdue_debt'] as num).toDouble(),
      lowStock: json['low_stock_products'] as int,
      topCustomers: [
        for (final e in (json['top_customers'] as List))
          MapEntry(e['customer_name'] as String, (e['total'] as num).toDouble()),
      ],
      dailySales: [
        for (final e in (json['daily_sales'] as List))
          MapEntry(
            DateTime.parse(e['day'] as String),
            (e['total'] as num).toDouble(),
          ),
      ],
      categoryBreakdown: [
        for (final e in (json['category_breakdown'] as List))
          MapEntry(e['category_name'] as String, (e['total'] as num).toDouble()),
      ],
    );
  }
}

class ReportRepository {
  ReportRepository(this._dio);
  final Dio _dio;

  Future<ReportSummary> summary() async {
    final resp = await _dio.get('/reports/summary');
    return ReportSummary.fromJson(resp.data as Map<String, dynamic>);
  }
}

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(ref.watch(apiClientProvider)),
);

final reportSummaryProvider = FutureProvider<ReportSummary>(
  (ref) => ref.watch(reportRepositoryProvider).summary(),
);
