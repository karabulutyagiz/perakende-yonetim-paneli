import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/debts/presentation/debts_screen.dart';
import '../../features/invoices/presentation/invoice_create_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/products/presentation/home_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);
  const customerAllowedRoutes = {'/', '/cart', '/orders'};
  const tenantOwnerBlockedRoutes = <String>{};

  return GoRouter(
    initialLocation: '/',
    refreshListenable: _AuthListenable(ref),
    redirect: (ctx, state) {
      final loc = state.matchedLocation;
      final isPublic = loc == '/login';
      if (auth.status == AuthStatus.loading) {
        return null;
      }
      if (auth.status == AuthStatus.unauthenticated) {
        return isPublic ? null : '/login';
      }
      if (isPublic) {
        return '/';
      }

      if (auth.isCustomer && !customerAllowedRoutes.contains(loc)) {
        return '/';
      }

      if (auth.isTenantOwner && tenantOwnerBlockedRoutes.contains(loc)) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
      GoRoute(
          path: '/invoice/create',
          builder: (_, __) => const InvoiceCreateScreen()),
      GoRoute(path: '/orders', builder: (_, __) => const OrdersScreen()),
      GoRoute(path: '/debts', builder: (_, __) => const DebtsScreen()),
      GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
    ],
  );
});

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }
}
