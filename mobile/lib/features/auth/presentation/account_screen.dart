import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_controller.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final meAsync = ref.watch(meProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hesabım'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
      ),
      body: meAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Text('Hesap bilgisi yüklenemedi.'),
        ),
        data: (me) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(me?.fullName ?? '—',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              )),
                          const SizedBox(height: 4),
                          Text(me?.email ?? '—',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              )),
                          if (me?.tenantName != null) ...[
                            const SizedBox(height: 8),
                            Text('İşletme: ${me!.tenantName}',
                                style: theme.textTheme.bodyMedium),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Çıkış yap'),
                    onPressed: () async {
                      await ref
                          .read(authControllerProvider.notifier)
                          .logout();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                  const SizedBox(height: 32),
                  Divider(color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    'Tehlikeli bölge',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    me?.role == 'tenant_owner'
                        ? 'Hesabınızı sildiğinizde işletmeniz, ürünler, müşteriler, '
                            'siparişler, faturalar, borçlar ve tüm kayıtlar kalıcı '
                            'olarak silinir. Bu işlem geri alınamaz.'
                        : 'Hesabınız ve oturum bilgileriniz kalıcı olarak silinir. '
                            'Bu işlem geri alınamaz.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.errorContainer,
                      foregroundColor: theme.colorScheme.onErrorContainer,
                    ),
                    icon: const Icon(Icons.delete_forever_rounded),
                    label: const Text('Hesabımı sil'),
                    onPressed: () => _confirmDelete(context, ref),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final passwordCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool loading = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final theme = Theme.of(ctx);
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Hesabı kalıcı sil')),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Bu işlem geri alınamaz. Devam etmek için parolanızı '
                        'girin ve onay alanına büyük harflerle "SİL" yazın.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Parolanız',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (v) => (v == null || v.length < 6)
                            ? 'Parolanızı girin'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Onay (SİL yazın)',
                          prefixIcon: Icon(Icons.delete_outline),
                        ),
                        validator: (v) => (v?.trim().toUpperCase() != 'SİL')
                            ? 'Onay için "SİL" yazın'
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: loading ? null : () => Navigator.pop(ctx, false),
                  child: const Text('Vazgeç'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  ),
                  onPressed: loading
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setState(() => loading = true);
                          final res = await ref
                              .read(authControllerProvider.notifier)
                              .deleteAccount(
                                password: passwordCtrl.text,
                                confirm: confirmCtrl.text.trim(),
                              );
                          if (!ctx.mounted) return;
                          if (res.ok) {
                            Navigator.pop(ctx, true);
                          } else {
                            setState(() => loading = false);
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(res.error ?? 'Silinemedi'),
                              ),
                            );
                          }
                        },
                  child: loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Kalıcı sil'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hesabınız silindi.')),
      );
      context.go('/login');
    }
  }
}
