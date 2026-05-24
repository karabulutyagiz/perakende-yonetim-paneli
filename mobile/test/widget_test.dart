import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gokce_toptan/core/auth/auth_controller.dart';
import 'package:gokce_toptan/features/products/data/product.dart';
import 'package:gokce_toptan/features/products/data/product_repository.dart';
import 'package:gokce_toptan/main.dart';

void main() {
  testWidgets('Uygulama açılışta çizilir', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1080, 1920));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider
              .overrideWith((ref) => AuthController.marketing()),
          productRepositoryProvider
              .overrideWithValue(_EmptyProductRepository()),
        ],
        child: const ToptanApp(enableLiveSync: false),
      ),
    );
    await tester.pump();

    expect(find.byType(ToptanApp), findsOneWidget);
  });
}

class _EmptyProductRepository extends ProductRepository {
  _EmptyProductRepository() : super(Dio());

  @override
  Future<List<Product>> list() async => const [];
}
