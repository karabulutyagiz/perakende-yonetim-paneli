import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/cart/providers/cart_provider.dart';
import '../auth/auth_controller.dart';
import '../../features/invoices/data/invoice_repository.dart';
import '../../features/orders/data/order_repository.dart';
import '../../features/products/data/product.dart';
import '../../features/products/data/product_repository.dart';
import '../../features/reports/data/report_repository.dart';

const bool kMarketingCapture = bool.fromEnvironment('MARKETING_CAPTURE');

class MarketingCapture {
  static final GlobalKey boundaryKey =
      GlobalKey(debugLabel: 'marketingCapture');
  static bool _started = false;

  static void maybeStart(BuildContext context, GoRouter router) {
    if (!kMarketingCapture || _started) return;
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _run(context, router);
    });
  }

  static Future<void> _run(BuildContext context, GoRouter router) async {
    final pixelRatio = View.of(context).devicePixelRatio;
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    final steps = <({String name, String path})>[
      (name: '01-products', path: '/'),
      (name: '02-cart', path: '/cart'),
      (name: '03-invoice', path: '/invoices'),
      (name: '04-reports', path: '/reports'),
    ];

    for (final step in steps) {
      router.go(step.path);
      await Future<void>.delayed(const Duration(milliseconds: 1800));
      await _writeScreenshot(step.name, pixelRatio);
    }

    await Future<void>.delayed(const Duration(milliseconds: 250));
    exit(0);
  }

  static Future<void> _writeScreenshot(String name, double pixelRatio) async {
    final boundary = boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final out = Directory('${dir.path}/marketing/tr');
    await out.create(recursive: true);
    await File('${out.path}/$name.png')
        .writeAsBytes(bytes.buffer.asUint8List());
  }
}

final marketingProviderOverrides = <Override>[
  authControllerProvider.overrideWith((ref) => AuthController.marketing()),
  productRepositoryProvider.overrideWithValue(MarketingProductRepository()),
  orderRepositoryProvider.overrideWithValue(MarketingOrderRepository()),
  invoiceRepositoryProvider.overrideWithValue(MarketingInvoiceRepository()),
  reportRepositoryProvider.overrideWithValue(MarketingReportRepository()),
  cartProvider.overrideWith((ref) {
    final controller = CartController();
    controller.add(marketingProducts[0], qty: 3);
    controller.add(marketingProducts[2], qty: 2);
    controller.add(marketingProducts[4], qty: 1);
    return controller;
  }),
];

final marketingProducts = <Product>[
  Product(
    id: 'p-001',
    name: 'Filtre Kahve 1 kg',
    description: 'Taze kavrulmuş çekirdek kahve',
    unit: 'paket',
    price: 420,
    stock: 48,
    categoryName: 'Kahve',
  ),
  Product(
    id: 'p-002',
    name: 'Bardak Karton 8 oz',
    unit: 'koli',
    price: 310,
    stock: 120,
    categoryName: 'Sarf',
  ),
  Product(
    id: 'p-003',
    name: 'Süt 1 Litre',
    unit: 'adet',
    price: 38,
    stock: 86,
    categoryName: 'Gıda',
  ),
  Product(
    id: 'p-004',
    name: 'Çikolata Sosu',
    unit: 'şişe',
    price: 145,
    stock: 9,
    categoryName: 'Sos',
  ),
  Product(
    id: 'p-005',
    name: 'Termal Rulo',
    unit: 'koli',
    price: 260,
    stock: 32,
    categoryName: 'Kasa',
  ),
  Product(
    id: 'p-006',
    name: 'Soğuk İçecek 24\'lü',
    unit: 'kasa',
    price: 520,
    stock: 17,
    categoryName: 'İçecek',
  ),
];

class MarketingProductRepository extends ProductRepository {
  MarketingProductRepository() : super(Dio());

  @override
  Future<List<Product>> list() async => marketingProducts;
}

class MarketingOrderRepository extends OrderRepository {
  MarketingOrderRepository() : super(Dio());

  @override
  Future<List<Map<String, dynamic>>> listAll() async => marketingOrders;

  @override
  Future<List<Map<String, dynamic>>> listMine() async => marketingOrders;

  @override
  Future<void> create(Cart cart, {String? note}) async {}
}

class MarketingInvoiceRepository extends InvoiceRepository {
  MarketingInvoiceRepository() : super(Dio());

  @override
  Future<List<Map<String, dynamic>>> list() async => marketingInvoices;
}

class MarketingReportRepository extends ReportRepository {
  MarketingReportRepository() : super(Dio());

  @override
  Future<ReportSummary> summary({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final today = DateTime.now();
    return ReportSummary(
      totalSales: 186420,
      invoiceCount: 42,
      uniqueCustomers: 18,
      kart: 96400,
      nakit: 58420,
      borc: 31600,
      outstandingDebt: 24600,
      overdueDebt: 8200,
      lowStock: 3,
      topCustomers: const [
        MapEntry('Mavi Kafe', 42800),
        MapEntry('Ada Market', 36500),
        MapEntry('Köşe Büfe', 24100),
      ],
      dailySales: [
        for (var i = 13; i >= 0; i--)
          MapEntry(today.subtract(Duration(days: i)), 4200 + ((14 - i) * 730)),
      ],
      categoryBreakdown: const [
        MapEntry('Kahve', 74200),
        MapEntry('Sarf', 38500),
        MapEntry('İçecek', 51200),
      ],
      topProducts: [
        TopProductSummary(
          productId: 'p-001',
          productName: 'Filtre Kahve 1 kg',
          unit: 'paket',
          totalRevenue: 58800,
          quantitySold: 140,
        ),
        TopProductSummary(
          productId: 'p-006',
          productName: 'Soğuk İçecek 24\'lü',
          unit: 'kasa',
          totalRevenue: 36400,
          quantitySold: 70,
        ),
      ],
    );
  }
}

final marketingOrders = <Map<String, dynamic>>[
  {
    'id': '11111111-1111-1111-1111-111111111111',
    'order_number': '24003128',
    'created_at':
        DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
    'status': 'pending',
    'total': 2696,
    'customer': {'name': 'Mavi Kafe', 'account_full_name': 'Ayşe Yılmaz'},
    'items': [
      {'product_name': 'Filtre Kahve 1 kg', 'quantity': 3, 'unit_price': 420},
      {'product_name': 'Süt 1 Litre', 'quantity': 8, 'unit_price': 38},
      {'product_name': 'Termal Rulo', 'quantity': 1, 'unit_price': 260},
    ],
  },
  {
    'id': '22222222-2222-2222-2222-222222222222',
    'order_number': '24003129',
    'created_at':
        DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
    'status': 'approved',
    'total': 1870,
    'customer': {'name': 'Ada Market', 'account_full_name': 'Mehmet Kaya'},
    'items': [
      {'product_name': 'Bardak Karton 8 oz', 'quantity': 2, 'unit_price': 310},
      {'product_name': 'Soğuk İçecek 24\'lü', 'quantity': 2, 'unit_price': 520},
    ],
  },
];

final marketingInvoices = <Map<String, dynamic>>[
  {
    'id': '33333333-3333-3333-3333-333333333333',
    'order_id': '11111111-1111-1111-1111-111111111111',
    'order_number': '24003128',
    'created_at':
        DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
    'total': 2696,
    'cash_amount': 1000,
    'card_amount': 1200,
    'debt_amount': 496,
    'customer': {'name': 'Mavi Kafe', 'account_full_name': 'Ayşe Yılmaz'},
  },
  {
    'id': '44444444-4444-4444-4444-444444444444',
    'order_id': '22222222-2222-2222-2222-222222222222',
    'order_number': '24003129',
    'created_at':
        DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    'total': 1870,
    'cash_amount': 0,
    'card_amount': 1870,
    'debt_amount': 0,
    'customer': {'name': 'Ada Market', 'account_full_name': 'Mehmet Kaya'},
  },
];
