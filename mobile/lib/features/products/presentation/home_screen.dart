import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_shell.dart';
import '../../cart/providers/cart_provider.dart';
import '../data/product.dart';
import '../data/product_repository.dart';

/// Ana ekran — ürün kataloğu. Getir tarzı: arama, kategori çipleri,
/// 2 kolonlu kartlar, altta yapışkan sepet çubuğu.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _search = TextEditingController();
  String? _selectedCategory; // null = Tümü

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Product> _applyFilters(List<Product> products) {
    var out = products;
    final q = _search.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      out = out.where((p) => p.name.toLowerCase().contains(q)).toList();
    }
    if (_selectedCategory != null) {
      out = out.where((p) => p.categoryName == _selectedCategory).toList();
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final async = ref.watch(productsProvider);

    return Scaffold(
      drawer: const AppDrawer(current: '/'),
      appBar: const PsAppBar(title: 'Ürünler', showCartAction: true),
      floatingActionButton: auth.isTenantOwner
          ? FloatingActionButton.extended(
              heroTag: 'add-product',
              onPressed: () => context.push('/products/new'),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Ürün ekle',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: const CartStickyBar(),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: 'Ürünler yüklenemedi. Lütfen tekrar deneyin.',
          onRetry: () => ref.invalidate(productsProvider),
        ),
        data: (products) {
          final categories = products
              .map((p) => p.categoryName)
              .whereType<String>()
              .toSet()
              .toList()
            ..sort();
          final filtered = _applyFilters(products);

          if (products.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(productsProvider),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: auth.isTenantOwner
                          ? 'Henüz ürün eklemedin'
                          : 'Henüz ürün yok',
                      subtitle: auth.isTenantOwner
                          ? 'İlk ürününü ekle, kataloğun burada görünsün.'
                          : 'Toptancın ürün ekleyince burada görünecek.',
                      actionLabel:
                          auth.isTenantOwner ? 'İlk ürünü ekle' : null,
                      onAction: auth.isTenantOwner
                          ? () => context.push('/products/new')
                          : null,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(productsProvider),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Arama
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                    child: TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Ürün ara',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _search.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  _search.clear();
                                  setState(() {});
                                },
                              ),
                      ),
                    ),
                  ),
                ),
                // Kategori çipleri
                if (categories.isNotEmpty)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 48,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        children: [
                          _CategoryChip(
                            label: 'Tümü',
                            selected: _selectedCategory == null,
                            onTap: () =>
                                setState(() => _selectedCategory = null),
                          ),
                          for (final c in categories)
                            _CategoryChip(
                              label: c,
                              selected: _selectedCategory == c,
                              onTap: () => setState(() =>
                                  _selectedCategory =
                                      _selectedCategory == c ? null : c),
                            ),
                        ],
                      ),
                    ),
                  ),
                if (filtered.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'Aradığın ürün bulunamadı',
                      subtitle: 'Farklı bir arama ya da kategori dene.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 220,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.70,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => ProductCard(
                          product: filtered[i],
                          canEdit: auth.isTenantOwner,
                          onAdd: () {
                            ref
                                .read(cartProvider.notifier)
                                .add(filtered[i]);
                          },
                          onEdit: auth.isTenantOwner
                              ? () => context.push(
                                    '/products/${filtered[i].id}/edit',
                                    extra: filtered[i],
                                  )
                              : null,
                        ),
                        childCount: filtered.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.line,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.text,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Getir tarzı ürün kartı: kare görsel, ad, fiyat, köşede yuvarlak + butonu.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onAdd,
    this.canEdit = false,
    this.onEdit,
  });

  final Product product;
  final VoidCallback onAdd;
  final bool canEdit;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outOfStock = product.stock <= 0;
    final lowStock = !outOfStock && product.stock <= 5;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: canEdit ? onEdit : (outOfStock ? null : onAdd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Görsel + üzerine ekle butonu
            AspectRatio(
              aspectRatio: 1.15,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: const Color(0xFFF0F2F1),
                    child: product.imageUrl == null
                        ? const Icon(
                            Icons.image_outlined,
                            size: 38,
                            color: AppColors.textMuted,
                          )
                        : CachedNetworkImage(
                            imageUrl: product.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.broken_image_outlined,
                              size: 38,
                              color: AppColors.textMuted,
                            ),
                          ),
                  ),
                  if (outOfStock)
                    Container(
                      color: Colors.white.withValues(alpha: 0.72),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.text.withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Tükendi',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ),
                  if (product.hasDiscount)
                    Positioned(
                      left: 8,
                      top: lowStock ? 32 : 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.discountLabel!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  if (lowStock)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Son ${product.stock.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF3D2E00),
                          ),
                        ),
                      ),
                    ),
                  // Sepete ekle — Getir tarzı köşe butonu
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Material(
                      color:
                          outOfStock ? AppColors.line : AppColors.primary,
                      shape: const CircleBorder(),
                      elevation: outOfStock ? 0 : 2,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: outOfStock ? null : onAdd,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (canEdit)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onEdit,
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.edit_rounded,
                              size: 17,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Bilgiler
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            formatCurrency(product.effectivePrice),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (product.hasDiscount) ...[
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              formatCurrency(product.price),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted,
                                decoration: TextDecoration.lineThrough,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Expanded(
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      outOfStock
                          ? 'Stokta yok'
                          : '${product.stock.toStringAsFixed(0)} ${product.unit}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: outOfStock
                            ? AppColors.danger
                            : AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
