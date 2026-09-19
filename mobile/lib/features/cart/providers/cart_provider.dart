import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../products/data/product.dart';

class CartLine {
  const CartLine(this.product, this.quantity);
  final Product product;
  final double quantity;

  /// Müşterinin ödeyeceği satır tutarı (ürün indirimi düşülmüş).
  double get total => product.effectivePrice * quantity;

  /// İndirim uygulanmamış liste tutarı.
  double get listTotal => product.price * quantity;

  /// Bu satırda yapılan indirim (0 = indirim yok).
  double get discountTotal => listTotal - total;

  CartLine copyWith({double? quantity}) =>
      CartLine(product, quantity ?? this.quantity);
}

class Cart {
  const Cart(this.lines);
  final List<CartLine> lines;

  double get total => lines.fold(0, (a, b) => a + b.total);

  /// İndirim öncesi ara toplam.
  double get subtotal => lines.fold(0, (a, b) => a + b.listTotal);

  /// Sepetteki toplam indirim.
  double get discountTotal => subtotal - total;
  bool get hasDiscount => discountTotal > 0;

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
