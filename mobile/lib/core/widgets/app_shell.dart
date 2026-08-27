import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../../features/cart/providers/cart_provider.dart';

/// Sol hamburger menü — tüm ana ekranlardan erişilir.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key, required this.current});

  /// Aktif route (ör. '/', '/orders') — seçili öğeyi vurgulamak için.
  final String current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final me = ref.watch(meProvider).valueOrNull;

    final items = auth.isCustomer
        ? const [
            _DrawerItem('/', Icons.storefront_rounded, 'Ürünler'),
            _DrawerItem('/cart', Icons.shopping_cart_rounded, 'Sepetim'),
            _DrawerItem('/orders', Icons.shopping_bag_rounded, 'Siparişlerim'),
            _DrawerItem('/account', Icons.person_rounded, 'Hesabım'),
          ]
        : const [
            _DrawerItem('/', Icons.storefront_rounded, 'Ürünler'),
            _DrawerItem('/orders', Icons.shopping_bag_rounded,
                'Gelen Siparişler'),
            _DrawerItem('/invoices', Icons.receipt_long_rounded, 'Faturalar'),
            _DrawerItem('/debts', Icons.schedule_rounded, 'Borçlar'),
            _DrawerItem('/reports', Icons.insights_rounded, 'Raporlar'),
            _DrawerItem('/account', Icons.person_rounded, 'Hesabım'),
          ];

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Üst kısım — işletme kimliği
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DrawerLogo(logoUrl: me?.tenantLogoUrl),
                  const SizedBox(height: 12),
                  Text(
                    me?.tenantName ?? 'ParaSende',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (me?.email != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      me!.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Menü öğeleri
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final item in items)
                    _DrawerTile(
                      item: item,
                      selected: current == item.route,
                      badge: item.route == '/cart'
                          ? ref.watch(cartProvider).itemCount
                          : null,
                    ),
                ],
              ),
            ),
            // Alt kısım — çıkış
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const Divider(),
                  const SizedBox(height: 4),
                  ListTile(
                    leading:
                        const Icon(Icons.logout_rounded, color: AppColors.danger),
                    title: const Text(
                      'Çıkış yap',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await ref.read(authControllerProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerLogo extends StatelessWidget {
  const _DrawerLogo({this.logoUrl});
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: (logoUrl != null && logoUrl!.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: logoUrl!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const _FallbackLogo(),
            )
          : const _FallbackLogo(),
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  const _FallbackLogo();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Image.asset(
        'assets/icon/parasende.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.storefront_rounded,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _DrawerItem {
  const _DrawerItem(this.route, this.icon, this.label);
  final String route;
  final IconData icon;
  final String label;
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.item,
    required this.selected,
    this.badge,
  });

  final _DrawerItem item;
  final bool selected;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        selected: selected,
        selectedTileColor: AppColors.primaryContainer,
        leading: Icon(
          item.icon,
          color: selected ? AppColors.primaryDark : AppColors.textMuted,
        ),
        title: Text(
          item.label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.primaryDark : AppColors.text,
          ),
        ),
        trailing: (badge != null && badge! > 0)
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3D2E00),
                  ),
                ),
              )
            : null,
        onTap: () {
          Navigator.of(context).pop();
          if (!selected) context.go(item.route);
        },
      ),
    );
  }
}

/// Standart üst bar: solda hamburger, ortada başlık, sağda aksiyonlar.
class PsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PsAppBar({
    super.key,
    required this.title,
    this.actions,
    this.bottom,
    this.showCartAction = false,
  });

  final String title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool showCartAction;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded),
          tooltip: 'Menü',
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: [
        ...?actions,
        if (showCartAction) const CartAppBarButton(),
        const SizedBox(width: 4),
      ],
      bottom: bottom,
    );
  }
}

/// Sepet ikonu + adet rozeti (app bar için).
class CartAppBarButton extends ConsumerWidget {
  const CartAppBarButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartProvider).itemCount;
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined),
          tooltip: 'Sepet',
          onPressed: () => context.push('/cart'),
        ),
        if (count > 0)
          Positioned(
            top: 6,
            right: 4,
            child: IgnorePointer(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 18),
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3D2E00),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Ekranın altına yapışan Getir tarzı sepet çubuğu.
class CartStickyBar extends ConsumerWidget {
  const CartStickyBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    if (cart.isEmpty) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/cart'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.shopping_cart_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${cart.itemCount} ürün',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        formatCurrency(cart.total),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'Sepete git',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ortak boş durum görünümü.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: AppColors.primaryDark),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textMuted),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ortak hata durumu görünümü.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 52, color: AppColors.textMuted),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              FilledButton(onPressed: onRetry, child: const Text('Tekrar dene')),
            ],
          ],
        ),
      ),
    );
  }
}
