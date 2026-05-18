import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api.dart';

class TenantItem {
  TenantItem({
    required this.id,
    required this.name,
    required this.contactEmail,
    required this.contactPhone,
    required this.logoUrl,
    required this.status,
    required this.isActive,
    required this.paidUntil,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? contactEmail;
  final String? contactPhone;
  final String? logoUrl;
  final String status;
  final bool isActive;
  final DateTime? paidUntil;
  final DateTime? createdAt;

  factory TenantItem.fromJson(Map<String, dynamic> j) => TenantItem(
        id: j['id'] as String,
        name: j['name'] as String,
        contactEmail: j['contact_email'] as String?,
        contactPhone: j['contact_phone'] as String?,
        logoUrl: j['logo_url'] as String?,
        status: j['status'] as String,
        isActive: j['is_active'] as bool,
        paidUntil: j['paid_until'] == null
            ? null
            : DateTime.tryParse(j['paid_until'] as String),
        createdAt: DateTime.tryParse((j['created_at'] ?? '') as String),
      );
}

class SudoPage extends ConsumerStatefulWidget {
  const SudoPage({super.key});

  @override
  ConsumerState<SudoPage> createState() => _SudoPageState();
}

class _SudoPageState extends ConsumerState<SudoPage> {
  List<TenantItem> _items = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioProvider);
      final qp = <String, dynamic>{};
      if (_filter != 'all') qp['status_filter'] = _filter;
      final resp = await dio.get('/sudo/tenants', queryParameters: qp);
      final list = (resp.data as List)
          .map((e) => TenantItem.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _items = list;
      });
    } catch (e) {
      setState(() => _error = 'Yüklenemedi');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _action(String id, String action) async {
    final dio = ref.read(dioProvider);
    try {
      if (action == 'delete') {
        final ok = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('İşletmeyi sil?'),
                content: const Text(
                    'Tüm verileri (ürünler, müşteriler, faturalar, borçlar) silinir. Geri alınamaz.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Vazgeç')),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Sil'),
                  ),
                ],
              ),
            ) ??
            false;
        if (!ok) return;
        await dio.delete('/sudo/tenants/$id');
      } else {
        await dio.post('/sudo/tenants/$id/$action');
      }
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşlem başarısız')),
        );
      }
    }
  }

  Future<void> _openCreateTenantDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameCtl = TextEditingController();
    final emailCtl = TextEditingController();
    final fullNameCtl = TextEditingController();
    final phoneCtl = TextEditingController();
    final logoCtl = TextEditingController();
    bool submitting = false;
    String? errorText;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            Future<void> submit() async {
              if (!formKey.currentState!.validate()) return;
              setLocal(() {
                submitting = true;
                errorText = null;
              });
              try {
                final dio = ref.read(dioProvider);
                final resp = await dio.post('/sudo/tenants', data: {
                  'business_name': nameCtl.text.trim(),
                  'owner_email': emailCtl.text.trim(),
                  'owner_full_name': fullNameCtl.text.trim(),
                  if (phoneCtl.text.trim().isNotEmpty)
                    'contact_phone': phoneCtl.text.trim(),
                  if (logoCtl.text.trim().isNotEmpty)
                    'logo_url': logoCtl.text.trim(),
                });
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                final body = resp.data as Map<String, dynamic>;
                await _showGeneratedPasswordDialog(
                  tenantName: body['tenant']['name'] as String,
                  ownerEmail: body['owner_email'] as String,
                  password: body['generated_password'] as String,
                );
                await _load();
              } on DioException catch (e) {
                String msg = 'İşlem başarısız';
                final data = e.response?.data;
                if (data is Map && data['detail'] is String) {
                  msg = data['detail'] as String;
                } else if (e.response?.statusCode == 409) {
                  msg = 'Bu e-posta zaten kayıtlı';
                }
                setLocal(() {
                  submitting = false;
                  errorText = msg;
                });
              } catch (_) {
                setLocal(() {
                  submitting = false;
                  errorText = 'Beklenmeyen hata';
                });
              }
            }

            return AlertDialog(
              title: const Text('Yeni İşletme'),
              content: SizedBox(
                width: 480,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameCtl,
                          decoration: const InputDecoration(
                            labelText: 'İşletme adı',
                            hintText: 'Ör: Yıldız Market',
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (v == null || v.trim().length < 2) {
                              return 'En az 2 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: fullNameCtl,
                          decoration: const InputDecoration(
                            labelText: 'Sahip ad-soyad',
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (v == null || v.trim().length < 2) {
                              return 'En az 2 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: emailCtl,
                          decoration: const InputDecoration(
                            labelText: 'Sahip e-posta',
                            hintText: 'orn@firma.com',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            final s = (v ?? '').trim();
                            if (!s.contains('@') || !s.contains('.')) {
                              return 'Geçerli e-posta';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: phoneCtl,
                          decoration: const InputDecoration(
                            labelText: 'Telefon (opsiyonel)',
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: logoCtl,
                          decoration: const InputDecoration(
                            labelText: 'Logo URL (opsiyonel)',
                            hintText: 'https://...',
                          ),
                          keyboardType: TextInputType.url,
                        ),
                        if (errorText != null) ...[
                          const SizedBox(height: 12),
                          Text(errorText!,
                              style: const TextStyle(color: Colors.red)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Vazgeç'),
                ),
                FilledButton.icon(
                  icon: submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: const Text('Oluştur'),
                  onPressed: submitting ? null : submit,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openCreateMarketDialog() async {
    final wholesalers = _items
        .where((t) => t.status == 'approved' && t.isActive)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (wholesalers.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Önce aktif bir toptancı oluşturun')),
        );
      }
      return;
    }

    final formKey = GlobalKey<FormState>();
    final marketNameCtl = TextEditingController();
    final ownerNameCtl = TextEditingController();
    final emailCtl = TextEditingController();
    final phoneCtl = TextEditingController();
    final addressCtl = TextEditingController();
    TenantItem selectedWholesaler = wholesalers.first;
    bool submitting = false;
    String? errorText;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            Future<void> submit() async {
              if (!formKey.currentState!.validate()) return;
              setLocal(() {
                submitting = true;
                errorText = null;
              });
              try {
                final dio = ref.read(dioProvider);
                final resp = await dio.post('/sudo/markets', data: {
                  'market_name': marketNameCtl.text.trim(),
                  'wholesaler_tenant_id': selectedWholesaler.id,
                  'owner_email': emailCtl.text.trim(),
                  'owner_full_name': ownerNameCtl.text.trim(),
                  if (phoneCtl.text.trim().isNotEmpty)
                    'contact_phone': phoneCtl.text.trim(),
                  if (addressCtl.text.trim().isNotEmpty)
                    'address': addressCtl.text.trim(),
                });
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                final body = resp.data as Map<String, dynamic>;
                await _showGeneratedMarketPasswordDialog(
                  marketName: body['market_name'] as String,
                  wholesalerName: body['wholesaler_name'] as String,
                  ownerEmail: body['owner_email'] as String,
                  password: body['generated_password'] as String,
                );
              } on DioException catch (e) {
                String msg = 'İşlem başarısız';
                final data = e.response?.data;
                if (data is Map && data['detail'] is String) {
                  msg = data['detail'] as String;
                } else if (e.response?.statusCode == 409) {
                  msg = 'Bu e-posta zaten kayıtlı';
                }
                setLocal(() {
                  submitting = false;
                  errorText = msg;
                });
              } catch (_) {
                setLocal(() {
                  submitting = false;
                  errorText = 'Beklenmeyen hata';
                });
              }
            }

            return AlertDialog(
              title: const Text('Yeni Market'),
              content: SizedBox(
                width: 520,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: selectedWholesaler.id,
                          decoration: const InputDecoration(
                            labelText: 'Bağlı toptancı',
                          ),
                          items: [
                            for (final wholesaler in wholesalers)
                              DropdownMenuItem(
                                value: wholesaler.id,
                                child: Text(wholesaler.name),
                              ),
                          ],
                          onChanged: submitting
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  setLocal(() {
                                    selectedWholesaler = wholesalers.firstWhere(
                                      (t) => t.id == value,
                                    );
                                  });
                                },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: marketNameCtl,
                          decoration: const InputDecoration(
                            labelText: 'Market adı',
                            hintText: 'Ör: Çınar Market',
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (v) => (v == null || v.trim().length < 2)
                              ? 'En az 2 karakter'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: ownerNameCtl,
                          decoration: const InputDecoration(
                            labelText: 'Yetkili ad-soyad',
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (v) => (v == null || v.trim().length < 2)
                              ? 'En az 2 karakter'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: emailCtl,
                          decoration: const InputDecoration(
                            labelText: 'Giriş e-postası',
                            hintText: 'market@firma.com',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            final s = (v ?? '').trim();
                            if (!s.contains('@') || !s.contains('.')) {
                              return 'Geçerli e-posta';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: phoneCtl,
                          decoration: const InputDecoration(
                            labelText: 'Telefon (opsiyonel)',
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: addressCtl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Adres (opsiyonel)',
                          ),
                        ),
                        if (errorText != null) ...[
                          const SizedBox(height: 12),
                          Text(errorText!,
                              style: const TextStyle(color: Colors.red)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Vazgeç'),
                ),
                FilledButton.icon(
                  icon: submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.storefront_outlined),
                  label: const Text('Market oluştur'),
                  onPressed: submitting ? null : submit,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showGeneratedMarketPasswordDialog({
    required String marketName,
    required String wholesalerName,
    required String ownerEmail,
    required String password,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Color(0xFF0E6E4E)),
            SizedBox(width: 8),
            Text('Market oluşturuldu'),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(marketName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 4),
              Text('Bağlı toptancı: $wholesalerName',
                  style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 4),
              Text('Giriş: $ownerEmail',
                  style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  border: Border.all(color: const Color(0xFFFFB300)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFFF8F00)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Bu parola yalnızca bir kez gösterilir. Şimdi kopyala ve markete ilet.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      password,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: 'Kopyala',
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: password));
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                              content: Text('Parola panoya kopyalandı')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Future<void> _showGeneratedPasswordDialog({
    required String tenantName,
    required String ownerEmail,
    required String password,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Color(0xFF0E6E4E)),
            SizedBox(width: 8),
            Text('İşletme oluşturuldu'),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tenantName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 4),
              Text('Sahip: $ownerEmail',
                  style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  border: Border.all(color: const Color(0xFFFFB300)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFFF8F00)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Bu parola yalnızca BİR KEZ gösterilir. Şimdi kopyala ve müşteriye ilet.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      password,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: 'Kopyala',
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: password));
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                              content: Text('Parola panoya kopyalandı')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Widget _paidUntilBadge(DateTime paidUntil) {
    final now = DateTime.now();
    final remaining =
        paidUntil.difference(DateTime(now.year, now.month, now.day)).inDays;
    Color bg;
    Color fg;
    String label;
    if (remaining < 0) {
      bg = const Color(0xFFFFEBEE);
      fg = Colors.red.shade800;
      label = 'Süresi doldu (${DateFormat('dd.MM.yyyy').format(paidUntil)})';
    } else if (remaining <= 7) {
      bg = const Color(0xFFFFF3E0);
      fg = const Color(0xFFE65100);
      label =
          '$remaining gün kaldı (${DateFormat('dd.MM.yyyy').format(paidUntil)})';
    } else {
      bg = const Color(0xFFE8F5E9);
      fg = const Color(0xFF1B5E20);
      label = 'Geçerli — ${DateFormat('dd.MM.yyyy').format(paidUntil)}';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style:
              TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 11)),
    );
  }

  Widget _logoThumb(String? url) {
    const size = 44.0;
    if (url == null || url.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFEFEFEF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.storefront_outlined, color: Colors.black38),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: const Color(0xFFFFEBEE),
          child: const Icon(Icons.broken_image_outlined, color: Colors.red),
        ),
      ),
    );
  }

  Future<void> _openEditTenantDialog(TenantItem t) async {
    final formKey = GlobalKey<FormState>();
    final nameCtl = TextEditingController(text: t.name);
    final phoneCtl = TextEditingController(text: t.contactPhone ?? '');
    final logoCtl = TextEditingController(text: t.logoUrl ?? '');
    DateTime? paidUntil = t.paidUntil;
    bool submitting = false;
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            Future<void> submit() async {
              if (!formKey.currentState!.validate()) return;
              setLocal(() {
                submitting = true;
                errorText = null;
              });
              try {
                final dio = ref.read(dioProvider);
                await dio.patch('/sudo/tenants/${t.id}', data: {
                  'name': nameCtl.text.trim(),
                  'contact_phone': phoneCtl.text.trim().isEmpty
                      ? null
                      : phoneCtl.text.trim(),
                  'logo_url':
                      logoCtl.text.trim().isEmpty ? null : logoCtl.text.trim(),
                  'paid_until': paidUntil == null
                      ? null
                      : '${paidUntil!.year.toString().padLeft(4, '0')}-'
                          '${paidUntil!.month.toString().padLeft(2, '0')}-'
                          '${paidUntil!.day.toString().padLeft(2, '0')}',
                });
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                await _load();
              } catch (_) {
                setLocal(() {
                  submitting = false;
                  errorText = 'Güncelleme başarısız';
                });
              }
            }

            return AlertDialog(
              title: Text('İşletme: ${t.name}'),
              content: SizedBox(
                width: 480,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtl,
                        decoration:
                            const InputDecoration(labelText: 'İşletme adı'),
                        validator: (v) => (v == null || v.trim().length < 2)
                            ? 'En az 2'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneCtl,
                        decoration: const InputDecoration(labelText: 'Telefon'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: logoCtl,
                        decoration: const InputDecoration(
                          labelText: 'Logo URL',
                          hintText: 'https://...',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Abonelik bitiş tarihi',
                                hintText: 'YYYY-AA-GG',
                              ),
                              child: Text(
                                paidUntil == null
                                    ? 'Belirsiz (kontrolsüz)'
                                    : DateFormat('dd.MM.yyyy')
                                        .format(paidUntil!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.calendar_today),
                            tooltip: 'Tarih seç',
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: paidUntil ??
                                    DateTime.now()
                                        .add(const Duration(days: 365)),
                                firstDate: DateTime(2024),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                setLocal(() => paidUntil = picked);
                              }
                            },
                          ),
                          if (paidUntil != null)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              tooltip: 'Temizle',
                              onPressed: () => setLocal(() => paidUntil = null),
                            ),
                        ],
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 12),
                        Text(errorText!,
                            style: const TextStyle(color: Colors.red)),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Vazgeç'),
                ),
                FilledButton(
                  onPressed: submitting ? null : submit,
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return const Color(0xFF0E6E4E);
      case 'suspended':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'pending':
        return 'Onay Bekliyor';
      case 'approved':
        return 'Onaylı';
      case 'suspended':
        return 'Askıda';
      default:
        return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd.MM.yyyy HH:mm');
    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'create_market_fab',
            onPressed: _openCreateMarketDialog,
            icon: const Icon(Icons.storefront_outlined),
            label: const Text('Yeni Market'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'create_tenant_fab',
            onPressed: _openCreateTenantDialog,
            icon: const Icon(Icons.add_business),
            label: const Text('Yeni İşletme'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.admin_panel_settings_outlined,
                    color: Color(0xFF0E6E4E)),
                const SizedBox(width: 8),
                const Text('Platform Yönetimi',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 22)),
                const Spacer(),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'all', label: Text('Tümü')),
                    ButtonSegment(value: 'pending', label: Text('Bekleyen')),
                    ButtonSegment(value: 'approved', label: Text('Onaylı')),
                    ButtonSegment(value: 'suspended', label: Text('Askıda')),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (s) {
                    setState(() => _filter = s.first);
                    _load();
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _load,
                  tooltip: 'Yenile',
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Çıkış',
                  onPressed: () async {
                    try {
                      await ref.read(dioProvider).post('/auth/logout');
                    } catch (_) {}
                    await ref.read(tokensProvider.notifier).clear();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            Expanded(
              child: _items.isEmpty && !_loading
                  ? const Center(child: Text('Kayıt yok'))
                  : ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final t = _items[i];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                _logoThumb(t.logoUrl),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            t.name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _statusColor(t.status)
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              _statusLabel(t.status),
                                              style: TextStyle(
                                                  color: _statusColor(t.status),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        [
                                          if (t.contactEmail != null)
                                            t.contactEmail!,
                                          if (t.contactPhone != null)
                                            t.contactPhone!,
                                          if (t.createdAt != null)
                                            'Kayıt: ${df.format(t.createdAt!.toLocal())}',
                                        ].join(' • '),
                                        style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 12),
                                      ),
                                      if (t.paidUntil != null) ...[
                                        const SizedBox(height: 4),
                                        _paidUntilBadge(t.paidUntil!),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: 'Düzenle',
                                  onPressed: () => _openEditTenantDialog(t),
                                ),
                                const SizedBox(width: 4),
                                if (t.status == 'pending')
                                  FilledButton.icon(
                                    icon: const Icon(Icons.check),
                                    label: const Text('Onayla'),
                                    onPressed: () => _action(t.id, 'approve'),
                                  ),
                                if (t.status == 'approved')
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.pause_circle),
                                    label: const Text('Askıya al'),
                                    onPressed: () => _action(t.id, 'suspend'),
                                  ),
                                if (t.status == 'suspended')
                                  FilledButton.icon(
                                    icon: const Icon(Icons.play_arrow),
                                    label: const Text('Tekrar aktif'),
                                    onPressed: () => _action(t.id, 'approve'),
                                  ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  tooltip: 'Sil',
                                  onPressed: () => _action(t.id, 'delete'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
