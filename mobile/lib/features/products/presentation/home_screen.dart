import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/ws/ws_client.dart';
import '../../cart/providers/cart_provider.dart';
import '../../customers/data/customer_repository.dart';
import '../../debts/data/debt_repository.dart';
import '../data/product.dart';
import '../data/product_repository.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showTabletCartPanel = false;

  @override
  void initState() {
    super.initState();
    // WS'e bağlan — global canlı senkronizasyon
    Future.microtask(() async {
      await ref.read(wsClientProvider).connect();
      ref.read(wsClientProvider).stream.listen((event) {
        if (!mounted) return;
        final e = event.event;
        if (e.startsWith('product.') ||
            e == 'stock.changed' ||
            e.startsWith('category.')) {
          ref.invalidate(productsProvider);
        }
        if (e.startsWith('customer.')) {
          ref.invalidate(customersProvider);
        }
        if (e.startsWith('invoice.') || e.startsWith('debt.')) {
          ref.invalidate(allDebtsProvider);
          ref.invalidate(debtSummaryProvider);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(productsProvider);
    final cart = ref.watch(cartProvider);
    final auth = ref.watch(authControllerProvider);
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 900;

    if (!isTablet && _showTabletCartPanel) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _showTabletCartPanel = false);
        }
      });
    }

    final meAsync = ref.watch(meProvider);
    final tenantName = meAsync.maybeWhen(
      data: (m) => m?.tenantName,
      orElse: () => null,
    );
    final logoUrl = meAsync.maybeWhen(
      data: (m) => m?.tenantLogoUrl,
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (logoUrl != null && logoUrl.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: logoUrl,
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.storefront_rounded, size: 24),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tenantName ?? 'Toptan panel',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Ürünler',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (auth.isTenantOwner)
            IconButton(
              icon: const Icon(Icons.insights_rounded),
              tooltip: 'Raporlar',
              onPressed: () => context.push('/reports'),
            ),
          if (auth.isTenantOwner)
            IconButton(
              icon: const Icon(Icons.receipt_long_rounded),
              tooltip: 'Borçlar',
              onPressed: () => context.push('/debts'),
            ),
          if (auth.isCustomer)
            IconButton(
              icon: const Icon(Icons.shopping_bag_outlined),
              tooltip: 'Siparişlerim',
              onPressed: () => context.push('/orders'),
            ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Çıkış',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      floatingActionButton: isTablet || cart.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/cart'),
              icon: const Icon(Icons.shopping_cart_rounded),
              label: Text(
                '${cart.itemCount} ürün · ${formatCurrency(cart.total)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64),
                const SizedBox(height: 12),
                const Text(
                  'Ürünler yüklenemedi. Lütfen tekrar deneyin.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(productsProvider),
                  child: const Text('Tekrar dene'),
                ),
              ],
            ),
          ),
        ),
        data: (products) => isTablet
            ? Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: _TabletTopBar(
                            auth: auth,
                            cart: cart,
                            showSummary: _showTabletCartPanel,
                            onToggleSummary: () {
                              setState(
                                () => _showTabletCartPanel =
                                    !_showTabletCartPanel,
                              );
                            },
                          ),
                        ),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () async =>
                                ref.invalidate(productsProvider),
                            child: _ProductsGrid(
                              products: products,
                              onAdd: (product) {
                                ref.read(cartProvider.notifier).add(product);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    duration: const Duration(seconds: 1),
                                    content:
                                        Text('${product.name} sepete eklendi'),
                                  ),
                                );
                              },
                              maxCrossAxisExtent: 260,
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: _showTabletCartPanel
                        ? _TabletCartPanel(auth: auth, cart: cart)
                        : const SizedBox.shrink(),
                  ),
                ],
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(productsProvider),
                child: _ProductsGrid(
                  products: products,
                  onAdd: (product) {
                    ref.read(cartProvider.notifier).add(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        duration: const Duration(seconds: 1),
                        content: Text('${product.name} sepete eklendi'),
                      ),
                    );
                  },
                  maxCrossAxisExtent: 220,
                  padding: const EdgeInsets.all(12),
                ),
              ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış yap'),
        content: const Text('Çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hayır'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Evet'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }
}

class _TabletTopBar extends StatelessWidget {
  const _TabletTopBar({
    required this.auth,
    required this.cart,
    required this.showSummary,
    required this.onToggleSummary,
  });

  final AuthState auth;
  final Cart cart;
  final bool showSummary;
  final VoidCallback onToggleSummary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auth.isCustomer ? 'Sipariş yönetimi' : 'Satış yönetimi',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cart.isEmpty
                        ? 'Henüz seçili ürün yok'
                        : '${cart.itemCount} ürün seçildi · ${formatCurrency(cart.total)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: onToggleSummary,
              icon: Icon(
                showSummary
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              label: Text(
                showSummary
                    ? (auth.isCustomer
                        ? 'Sipariş özetini gizle'
                        : 'Sepet özetini gizle')
                    : (auth.isCustomer
                        ? 'Sipariş özetini göster'
                        : 'Sepet özetini göster'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductsGrid extends StatelessWidget {
  const _ProductsGrid({
    required this.products,
    required this.onAdd,
    required this.maxCrossAxisExtent,
    required this.padding,
  });

  final List<Product> products;
  final ValueChanged<Product> onAdd;
  final double maxCrossAxisExtent;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return ListView(
        padding: padding,
        children: const [
          SizedBox(height: 120),
          Icon(Icons.inventory_2_outlined, size: 72),
          SizedBox(height: 16),
          Center(child: Text('Henüz ürün eklenmedi')),
        ],
      );
    }

    return GridView.builder(
      padding: padding,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxCrossAxisExtent,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) => _ProductCard(
        product: products[i],
        onAdd: () => onAdd(products[i]),
      ),
    );
  }
}

class _TabletCartPanel extends ConsumerWidget {
  const _TabletCartPanel({required this.auth, required this.cart});

  final AuthState auth;
  final Cart cart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      width: 360,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border:
            Border(left: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        left: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      auth.isCustomer ? 'Sipariş özeti' : 'Sepet özeti',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (!cart.isEmpty)
                    IconButton(
                      tooltip: 'Sepeti boşalt',
                      onPressed: () => ref.read(cartProvider.notifier).clear(),
                      icon: const Icon(Icons.delete_outline),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (cart.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shopping_cart_outlined, size: 64),
                          const SizedBox(height: 12),
                          Text(
                            auth.isCustomer
                                ? 'Sipariş vermek için ürün ekleyin'
                                : 'Fatura oluşturmak için ürün ekleyin',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                Expanded(
                  child: ListView.separated(
                    itemCount: cart.lines.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final line = cart.lines[i];
                      return Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                line.product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${formatCurrency(line.product.price)} / ${line.product.unit}',
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      formatCurrency(line.total),
                                      style:
                                          theme.textTheme.titleSmall?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  _TabletQtyStepper(
                                    value: line.quantity,
                                    onChanged: (v) => ref
                                        .read(cartProvider.notifier)
                                        .updateQty(line.product.id, v),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Toplam', style: theme.textTheme.titleMedium),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        formatCurrency(cart.total),
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      if (auth.isCustomer) {
                        context.push('/cart');
                        return;
                      }
                      context.push('/cart');
                    },
                    icon: Icon(
                      auth.isCustomer
                          ? Icons.shopping_bag_outlined
                          : Icons.receipt_long_rounded,
                    ),
                    label: Text(
                      auth.isCustomer ? 'Siparişi tamamla' : 'Sepeti aç',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TabletQtyStepper extends StatelessWidget {
  const _TabletQtyStepper({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          icon: const Icon(Icons.remove),
          onPressed: () => onChanged(value - 1),
        ),
        SizedBox(
          width: 42,
          child: Text(
            value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        IconButton.filledTonal(
          icon: const Icon(Icons.add),
          onPressed: () => onChanged(value + 1),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onAdd});
  final Product product;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: product.imageUrl == null
                ? Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.image_outlined, size: 40),
                  )
                : CachedNetworkImage(
                    imageUrl: product.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    errorWidget: (_, __, ___) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.broken_image_outlined, size: 40),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  'Stok: ${product.stock.toStringAsFixed(0)} ${product.unit}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  formatCurrency(product.price),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: product.stock > 0 ? onAdd : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(36),
                shape: const RoundedRectangleBorder(),
              ),
              child: Text(product.stock > 0 ? 'Sepete ekle' : 'Stokta yok'),
            ),
          ),
        ],
      ),
    );
  }
}
