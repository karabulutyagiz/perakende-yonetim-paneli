import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import 'customer.dart';

class CustomerRepository {
  CustomerRepository(this._dio);
  final Dio _dio;

  Future<List<Customer>> list() async {
    final resp = await _dio.get('/customers');
    return (resp.data as List)
        .map((e) => Customer.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final customerRepositoryProvider = Provider<CustomerRepository>(
  (ref) => CustomerRepository(ref.watch(apiClientProvider)),
);

final customersProvider = FutureProvider<List<Customer>>((ref) {
  return ref.watch(customerRepositoryProvider).list();
});
