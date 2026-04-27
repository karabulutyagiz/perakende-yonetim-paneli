import 'package:flutter/material.dart';
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
    required this.status,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? contactEmail;
  final String? contactPhone;
  final String status;
  final bool isActive;
  final DateTime? createdAt;

  factory TenantItem.fromJson(Map<String, dynamic> j) => TenantItem(
        id: j['id'] as String,
        name: j['name'] as String,
        contactEmail: j['contact_email'] as String?,
        contactPhone: j['contact_phone'] as String?,
        status: j['status'] as String,
        isActive: j['is_active'] as bool,
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
                                            padding: const EdgeInsets
                                                .symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _statusColor(t.status)
                                                  .withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              _statusLabel(t.status),
                                              style: TextStyle(
                                                  color:
                                                      _statusColor(t.status),
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
                                    ],
                                  ),
                                ),
                                if (t.status == 'pending')
                                  FilledButton.icon(
                                    icon: const Icon(Icons.check),
                                    label: const Text('Onayla'),
                                    onPressed: () =>
                                        _action(t.id, 'approve'),
                                  ),
                                if (t.status == 'approved')
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.pause_circle),
                                    label: const Text('Askıya al'),
                                    onPressed: () =>
                                        _action(t.id, 'suspend'),
                                  ),
                                if (t.status == 'suspended')
                                  FilledButton.icon(
                                    icon: const Icon(Icons.play_arrow),
                                    label: const Text('Tekrar aktif'),
                                    onPressed: () =>
                                        _action(t.id, 'approve'),
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
