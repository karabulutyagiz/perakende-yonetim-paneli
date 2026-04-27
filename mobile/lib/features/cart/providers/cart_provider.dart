import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../products/data/product.dart';

class CartLine {
  const CartLine(this.product, this.quantity);
  final Product product;
  final double quantity;
  double get total => product.price * quantity;

  CartLine copyWith({double? quantity}) =>
      CartLine(product, quantity ?? this.quantity);
}

class Cart {
  const Cart(this.lines);
  final List<CartLine> lines;

  double get total => lines.fold(0, (a, b) => a + b.total);
  int get itemCount => lines.length;
  bool get isEmpty => lines.isEmpty;
}

class CartController extends StateNotifier<Cart> {
  CartController() : super(const Cart([]));

  void add(Product p, {double qty = 1}) {
    final idx = state.lines.indexWhere((l) => l.product.id == p.id);
    final next = [...state.lines];
    if (idx >= 0) {
      next[idx] = next[idx].copyWith(quantity: next[idx].quantity + qty);
    } else {
      next.add(CartLine(p, qty));
    }
    state = Cart(next);
  }

  void updateQty(String productId, double qty) {
    if (qty <= 0) {
      remove(productId);
      return;
    }
    state = Cart([
      for (final l in state.lines)
        if (l.product.id == productId) l.copyWith(quantity: qty) else l,
    ]);
  }

  void remove(String productId) {
    state = Cart(state.lines.where((l) => l.product.id != productId).toList());
  }

  void clear() => state = const Cart([]);
}

final cartProvider = StateNotifierProvider<CartController, Cart>(
  (_) => CartController(),
);
