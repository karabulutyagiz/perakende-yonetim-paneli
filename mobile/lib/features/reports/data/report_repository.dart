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
    required this.topProducts,
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
  final List<TopProductSummary> topProducts;

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
          MapEntry(
              e['customer_name'] as String, (e['total'] as num).toDouble()),
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
          MapEntry(
              e['category_name'] as String, (e['total'] as num).toDouble()),
      ],
      topProducts: [
        for (final e in (json['top_products'] as List))
          TopProductSummary.fromJson(e as Map<String, dynamic>),
      ],
    );
  }
}

class TopProductSummary {
  TopProductSummary({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.totalRevenue,
    required this.quantitySold,
  });

  final String productId;
  final String productName;
  final String unit;
  final double totalRevenue;
  final double quantitySold;

  factory TopProductSummary.fromJson(Map<String, dynamic> json) {
    return TopProductSummary(
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      unit: json['unit'] as String,
      totalRevenue: (json['total_revenue'] as num).toDouble(),
      quantitySold: (json['quantity_sold'] as num).toDouble(),
    );
  }
}

class ReportRepository {
  ReportRepository(this._dio);
  final Dio _dio;

  Future<ReportSummary> summary({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final resp = await _dio.get(
      '/reports/summary',
      queryParameters: {
        'from_date': _dateOnly(fromDate),
        'to_date': _dateOnly(toDate),
      },
    );
    return ReportSummary.fromJson(resp.data as Map<String, dynamic>);
  }

  String _dateOnly(DateTime date) => date.toIso8601String().split('T').first;
}

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(ref.watch(apiClientProvider)),
);

class ReportQuery {
  const ReportQuery({required this.fromDate, required this.toDate});

  final DateTime fromDate;
  final DateTime toDate;

  @override
  bool operator ==(Object other) {
    return other is ReportQuery &&
        other.fromDate == fromDate &&
        other.toDate == toDate;
  }

  @override
  int get hashCode => Object.hash(fromDate, toDate);
}

final reportSummaryProvider = FutureProvider.family<ReportSummary, ReportQuery>(
  (ref, query) => ref.watch(reportRepositoryProvider).summary(
        fromDate: query.fromDate,
        toDate: query.toDate,
      ),
);
