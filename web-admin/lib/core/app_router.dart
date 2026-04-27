import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_page.dart';
import '../features/auth/signup_page.dart';
import '../features/categories/categories_page.dart';
import '../features/customers/customers_page.dart';
import '../features/debts/debts_page.dart';
import '../features/invoices/invoices_page.dart';
import '../features/products/products_page.dart';
import '../features/reports/reports_page.dart';
import '../features/sudo/sudo_page.dart';
import 'api.dart';
import 'ws.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/login',
    refreshListenable: _AuthListenable(ref),
    redirect: (ctx, state) {
      final tokens = ref.read(tokensProvider);
      final authed = tokens.isAuthenticated;
      final loc = state.matchedLocation;
      final publicRoutes = {'/login', '/signup'};
      if (!authed) {
        return publicRoutes.contains(loc) ? null : '/login';
      }
      // Authenticated — rol bazlı yönlendirme
      final isSudo = tokens.isPlatformOwner;
      if (publicRoutes.contains(loc)) {
        return isSudo ? '/sudo' : '/products';
      }
      if (isSudo && !loc.startsWith('/sudo')) return '/sudo';
      if (!isSudo && loc.startsWith('/sudo')) return '/products';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupPage()),
      GoRoute(path: '/sudo', builder: (_, __) => const SudoPage()),
      ShellRoute(
        builder: (ctx, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(path: '/products', builder: (_, __) => const ProductsPage()),
          GoRoute(path: '/categories', builder: (_, __) => const CategoriesPage()),
          GoRoute(path: '/customers', builder: (_, __) => const CustomersPage()),
          GoRoute(path: '/invoices', builder: (_, __) => const InvoicesPage()),
          GoRoute(path: '/debts', builder: (_, __) => const DebtsPage()),
          GoRoute(path: '/reports', builder: (_, __) => const ReportsPage()),
        ],
      ),
    ],
  );
  // WS'i router ile birlikte provider ağacında tut
  ref.read(wsClientProvider);
  return router;
});

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen<AuthTokens>(tokensProvider, (_, __) => notifyListeners());
  }
}

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.child});
  final Widget child;

  static const _destinations = <(String, IconData, IconData, String)>[
    ('/products', Icons.inventory_2_outlined, Icons.inventory_2, 'Ürünler'),
    ('/categories', Icons.category_outlined, Icons.category, 'Kategoriler'),
    ('/customers', Icons.people_outline, Icons.people, 'Müşteriler'),
    ('/invoices', Icons.receipt_long_outlined, Icons.receipt_long, 'Faturalar'),
    ('/debts', Icons.schedule_outlined, Icons.schedule, 'Borçlar'),
    ('/reports', Icons.insights_outlined, Icons.insights, 'Rapor'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = GoRouterState.of(context).matchedLocation;
    int idx = _destinations.indexWhere((d) => d.$1 == loc);
    if (idx < 0) idx = 0;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: true,
            selectedIndex: idx,
            onDestinationSelected: (i) => context.go(_destinations[i].$1),
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Icon(Icons.storefront_rounded, size: 42, color: Color(0xFF0E6E4E)),
                  SizedBox(height: 8),
                  Text('Toptan Perakende',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  Text('Yönetim Paneli',
                      style: TextStyle(fontSize: 11, color: Colors.black54)),
                ],
              ),
            ),
            trailing: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Çıkış',
                onPressed: () async {
                  try {
                    await ref.read(dioProvider).post('/auth/logout');
                  } catch (_) {
                    // backend erişilemezse bile lokal temizlik yap
                  }
                  await ref.read(tokensProvider.notifier).clear();
                  if (context.mounted) context.go('/login');
                },
              ),
            ),
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.$2),
                  selectedIcon: Icon(d.$3),
                  label: Text(d.$4),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
