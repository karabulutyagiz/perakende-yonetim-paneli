import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../core/api.dart';
import '../../core/ws.dart';
import '../categories/categories_page.dart';

final productsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final resp = await ref.watch(dioProvider).get('/products');
  return (resp.data as List).cast<Map<String, dynamic>>();
});

final _tl = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  StreamSubscription<WsEvent>? _wsSub;

  @override
  void initState() {
    super.initState();
    _wsSub = listenWsEvents(
      ref,
      const ['product.', 'stock.', 'category.', 'invoice.'],
      (_) => ref.invalidate(productsProvider),
    );
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(productsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürünler'),
        actions: [
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Yeni Ürün'),
            onPressed: () => _openEditor(context, ref, null),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (products) => Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                columns: const [
                  DataColumn(label: Text('Görsel')),
                  DataColumn(label: Text('Ad')),
                  DataColumn(label: Text('Kategori')),
                  DataColumn(label: Text('Birim')),
                  DataColumn(label: Text('Fiyat')),
                  DataColumn(label: Text('Stok')),
                  DataColumn(label: Text('')),
                ],
                rows: [
                  for (final p in products)
                    DataRow(cells: [
                      DataCell(
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: p['image_url'] != null
                              ? CachedNetworkImage(
                                  imageUrl: p['image_url'] as String,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.image_outlined),
                        ),
                      ),
                      DataCell(Text(p['name'] as String)),
                      DataCell(Text((p['category'] ?? {})['name'] ?? '—')),
                      DataCell(Text(p['unit'] as String)),
                      DataCell(Builder(builder: (_) {
                        final price = (p['price'] as num).toDouble();
                        final effective =
                            (p['effective_price'] as num?)?.toDouble() ?? price;
                        if (effective >= price) {
                          return Text(_tl.format(price));
                        }
                        // İndirimli: satış fiyatı + üstü çizili liste fiyatı.
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _tl.format(effective),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _tl.format(price),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        );
                      })),
                      DataCell(Text('${p['stock']}')),
                      DataCell(Row(children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _openEditor(context, ref, p),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await ref.read(dioProvider).delete('/products/${p['id']}');
                            ref.invalidate(productsProvider);
                          },
                        ),
                      ])),
                    ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openEditor(
      BuildContext ctx, WidgetRef ref, Map<String, dynamic>? existing) async {
    await showDialog(
      context: ctx,
      builder: (_) => ProductEditor(existing: existing),
    );
    ref.invalidate(productsProvider);
  }
}

class ProductEditor extends ConsumerStatefulWidget {
  const ProductEditor({super.key, this.existing});
  final Map<String, dynamic>? existing;

  @override
  ConsumerState<ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends ConsumerState<ProductEditor> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _unit = TextEditingController(text: 'adet');
  final _price = TextEditingController();
  final _stock = TextEditingController();
  final _discount = TextEditingController();
  String? _categoryId;
  String? _imageKey;
  String? _imagePreviewUrl;
  /// null = indirim yok, 'percent' = yüzde, 'amount' = sabit TL.
  String? _discountType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _name.text = e['name'] as String;
      _description.text = (e['description'] as String?) ?? '';
      _unit.text = e['unit'] as String;
      _price.text = '${e['price']}';
      _stock.text = '${e['stock']}';
      _categoryId = (e['category'] ?? {})['id'] as String?;
      _imageKey = e['image_key'] as String?;
      _imagePreviewUrl = e['image_url'] as String?;
      _discountType = e['discount_type'] as String?;
      if (_discountType != null) {
        _discount.text = '${e['discount_value']}';
      }
    }
  }

  /// Backend'deki compute_effective_price ile aynı kural.
  double get _previewPrice {
    final price = _parseNum(_price.text) ?? 0;
    final value = _parseNum(_discount.text) ?? 0;
    if (_discountType == null || value <= 0) return price;
    final discount = _discountType == 'percent'
        ? price * (value > 100 ? 100 : value) / 100
        : (value > price ? price : value);
    final effective = price - discount;
    return effective < 0 ? 0 : double.parse(effective.toStringAsFixed(2));
  }

  Future<void> _uploadImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.first.bytes == null) return;
      final file = result.files.first;
      final dio = ref.read(dioProvider);
      final resp = await dio.post('/products/upload-url', data: {
        'filename': file.name,
        'content_type': 'image/${file.extension}',
      });
      final url = resp.data['upload_url'] as String;
      final key = resp.data['key'] as String;
      final put = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'image/${file.extension}'},
        body: file.bytes,
      );
      if (put.statusCode >= 200 && put.statusCode < 300) {
        setState(() => _imageKey = key);
      } else {
        _snack('Yükleme hatası: ${put.statusCode}');
      }
    } catch (e) {
      _snack('Görsel yüklenemedi: $e (AWS yapılandırılmadıysa atla)');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  double? _parseNum(String s) {
    final t = s.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      _snack('Ad zorunlu');
      return;
    }
    if (_unit.text.trim().isEmpty) {
      _snack('Birim zorunlu');
      return;
    }
    final price = _parseNum(_price.text);
    if (price == null) {
      _snack('Geçerli bir fiyat girin');
      return;
    }
    final stock = _parseNum(_stock.text);
    if (stock == null) {
      _snack('Geçerli bir stok girin');
      return;
    }

    // İndirim doğrulaması — backend de aynı kuralları uygular, burada
    // kullanıcıya daha hızlı geri bildirim veriyoruz.
    var discountValue = 0.0;
    if (_discountType != null) {
      final v = _parseNum(_discount.text);
      if (v == null || v <= 0) {
        _snack('İndirim değeri girin');
        return;
      }
      if (_discountType == 'percent' && v > 100) {
        _snack('Yüzde indirim 100\'den büyük olamaz');
        return;
      }
      if (_discountType == 'amount' && v > price) {
        _snack('TL indirimi ürün fiyatından büyük olamaz');
        return;
      }
      discountValue = v;
    }

    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);
      final body = {
        'name': _name.text.trim(),
        'description': _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        'unit': _unit.text.trim(),
        'price': price,
        'stock': stock,
        'category_id': _categoryId,
        'image_key': _imageKey,
        // discount_type null gönderilir → backend indirimi temizler.
        'discount_type': _discountType,
        'discount_value': discountValue,
      };
      if (widget.existing == null) {
        await dio.post('/products', data: body);
      } else {
        await dio.put('/products/${widget.existing!['id']}', data: body);
      }
      if (mounted) Navigator.pop(context);
    } on DioException catch (e) {
      final detail = e.response?.data is Map
          ? (e.response!.data['detail']?.toString() ?? e.message)
          : e.message;
      _snack('Kaydedilemedi: $detail');
    } catch (e) {
      _snack('Beklenmeyen hata: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider);
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.existing == null ? 'Yeni Ürün' : 'Ürünü Düzenle',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _uploadImage,
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black.withOpacity(0.08)),
                    ),
                    child: _imagePreviewUrl != null && _imageKey != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: _imagePreviewUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _imageKey == null
                                    ? Icons.cloud_upload_outlined
                                    : Icons.check_circle_outline,
                                size: 36,
                              ),
                              const SizedBox(height: 8),
                              Text(_imageKey == null
                                  ? 'Görsel yüklemek için tıkla'
                                  : 'Görsel yüklendi'),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Ad'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _description,
                  decoration: const InputDecoration(labelText: 'Açıklama'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _unit,
                        decoration: const InputDecoration(labelText: 'Birim (adet/kg/lt)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _price,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(labelText: 'Fiyat (₺)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _stock,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Stok'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // İndirim — ürün kartında tanımlanır, her satışta uygulanır.
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _discountType,
                        decoration: const InputDecoration(labelText: 'İndirim'),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('— Yok —')),
                          DropdownMenuItem(
                              value: 'percent', child: Text('Yüzde (%)')),
                          DropdownMenuItem(
                              value: 'amount', child: Text('Tutar (₺)')),
                        ],
                        onChanged: (v) => setState(() {
                          _discountType = v;
                          if (v == null) _discount.clear();
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _discount,
                        enabled: _discountType != null,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: _discountType == 'amount'
                              ? 'İndirim tutarı (₺)'
                              : 'İndirim oranı (%)',
                        ),
                      ),
                    ),
                  ],
                ),
                if (_discountType != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Satış fiyatı: ${_previewPrice.toStringAsFixed(2)} ₺'
                      '   (liste: ${(_parseNum(_price.text) ?? 0).toStringAsFixed(2)} ₺)',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                cats.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => const SizedBox(),
                  data: (list) => DropdownButtonFormField<String>(
                    value: _categoryId,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('— Kategorisiz —')),
                      for (final c in list)
                        DropdownMenuItem(value: c['id'] as String, child: Text(c['name'] as String)),
                    ],
                    onChanged: (v) => setState(() => _categoryId = v),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('İptal'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Kaydet'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
