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
      floatingActionButton: cart.isEmpty
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
        data: (products) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(productsProvider),
          child: products.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 120),
                    Icon(Icons.inventory_2_outlined, size: 72),
                    SizedBox(height: 16),
                    Center(child: Text('Henüz ürün eklenmedi')),
                  ],
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: products.length,
                  itemBuilder: (_, i) => _ProductCard(
                    product: products[i],
                    onAdd: () {
                      ref.read(cartProvider.notifier).add(products[i]);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 1),
                          content: Text('${products[i].name} sepete eklendi'),
                        ),
                      );
                    },
                  ),
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
