import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import 'debt.dart';

class DebtRepository {
  DebtRepository(this._dio);
  final Dio _dio;

  Future<List<Debt>> list({String? customerId}) async {
    final resp = await _dio.get('/debts', queryParameters: {
      if (customerId != null) 'customer_id': customerId,
    });
    return (resp.data as List)
        .map((e) => Debt.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CustomerDebtSummary>> summary() async {
    final resp = await _dio.get('/debts/summary');
    return (resp.data as List)
        .map((e) => CustomerDebtSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> pay({required String customerId, required double amount}) async {
    await _dio.post('/debts/payments',
        data: {'customer_id': customerId, 'amount': amount});
  }
}

final debtRepositoryProvider = Provider<DebtRepository>(
  (ref) => DebtRepository(ref.watch(apiClientProvider)),
);

final debtSummaryProvider = FutureProvider<List<CustomerDebtSummary>>((ref) {
  return ref.watch(debtRepositoryProvider).summary();
});

final debtsProvider =
    FutureProvider.family<List<Debt>, String?>((ref, customerId) {
  return ref.watch(debtRepositoryProvider).list(customerId: customerId);
});

/// Tüm açık borçları, vade sırasına göre döndürür (en yakın = en üstte).
final allDebtsProvider = FutureProvider<List<Debt>>((ref) async {
  return ref.watch(debtRepositoryProvider).list();
});
