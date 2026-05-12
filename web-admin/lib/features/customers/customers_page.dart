import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api.dart';
import '../../core/ws.dart';

final customersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final resp = await ref.watch(dioProvider).get('/customers');
  return (resp.data as List).cast<Map<String, dynamic>>();
});

class CustomersPage extends ConsumerStatefulWidget {
  const CustomersPage({super.key});

  @override
  ConsumerState<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends ConsumerState<CustomersPage> {
  StreamSubscription<WsEvent>? _wsSub;

  @override
  void initState() {
    super.initState();
    _wsSub = listenWsEvents(
      ref,
      const ['customer.', 'debt.'],
      (_) => ref.invalidate(customersProvider),
    );
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(customersProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Müşteriler'),
        actions: [
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Yeni Müşteri'),
            onPressed: () => _edit(context, ref, null),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (list) => Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final c = list[i];
                return ListTile(
                  leading: CircleAvatar(child: Text((c['name'] as String)[0])),
                  title: Text(c['name'] as String),
                  subtitle: Text([
                    c['phone'],
                    c['address'],
                    if (c['has_account'] == true) c['account_email'],
                    if (c['has_account'] == true)
                      (c['account_is_active'] == true ? 'Hesap aktif' : 'Hesap pasif'),
                  ].where((e) => e != null && (e as String).isNotEmpty).join(' · ')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _edit(context, ref, c),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await ref.read(dioProvider).delete('/customers/${c['id']}');
                          ref.invalidate(customersProvider);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _edit(
      BuildContext ctx, WidgetRef ref, Map<String, dynamic>? existing) async {
    final name = TextEditingController(text: (existing?['name'] as String?) ?? '');
    final phone = TextEditingController(text: (existing?['phone'] as String?) ?? '');
    final address =
        TextEditingController(text: (existing?['address'] as String?) ?? '');
    final accountEmail =
        TextEditingController(text: (existing?['account_email'] as String?) ?? '');
    final accountPassword = TextEditingController();
    bool accountEnabled = (existing?['account_is_active'] as bool?) ?? true;
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
        title: Text(existing == null ? 'Yeni Müşteri' : 'Müşteri Düzenle'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Ad'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phone,
                decoration: const InputDecoration(labelText: 'Telefon'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: address,
                decoration: const InputDecoration(labelText: 'Adres'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              TextField(
                controller: accountEmail,
                decoration: const InputDecoration(labelText: 'Hesap e-postasi (opsiyonel)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: accountPassword,
                decoration: InputDecoration(
                  labelText: existing?['has_account'] == true
                      ? 'Yeni sifre (opsiyonel)'
                      : 'Hesap sifresi',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Hesap aktif'),
                value: accountEnabled,
                onChanged: (value) => setState(() => accountEnabled = value),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kaydet')),
        ],
      )),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    final data = {
      'name': name.text.trim(),
      'phone': phone.text.trim().isEmpty ? null : phone.text.trim(),
      'address': address.text.trim().isEmpty ? null : address.text.trim(),
      if (accountEmail.text.trim().isNotEmpty) 'account_email': accountEmail.text.trim(),
      if (accountPassword.text.trim().isNotEmpty) 'account_password': accountPassword.text.trim(),
      if (accountEmail.text.trim().isNotEmpty || existing?['has_account'] == true)
        'account_is_active': accountEnabled,
    };
    if (existing == null) {
      await ref.read(dioProvider).post('/customers', data: data);
    } else {
      await ref.read(dioProvider).put('/customers/${existing['id']}', data: data);
    }
    ref.invalidate(customersProvider);
  }
}
