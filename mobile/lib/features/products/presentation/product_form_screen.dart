import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../data/product.dart';
import '../data/product_repository.dart';

const _commonUnits = ['adet', 'kg', 'lt', 'koli', 'paket', 'kasa', 'şişe'];

/// Ürün ekleme / düzenleme — tenant_owner için telefon öncelikli tam ekran form.
class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.product});

  /// null → yeni ürün; dolu → düzenleme.
  final Product? product;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _description;
  late String _unit;
  String? _categoryId;
  bool _saving = false;

  Uint8List? _pickedImageBytes;
  String? _pickedImageName;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _price = TextEditingController(
      text: p == null ? '' : _trimZeros(p.price),
    );
    _stock = TextEditingController(
      text: p == null ? '' : _trimZeros(p.stock),
    );
    _description = TextEditingController(text: p?.description ?? '');
    _unit = p?.unit ?? 'adet';
    _categoryId = p?.categoryId;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _stock.dispose();
    _description.dispose();
    super.dispose();
  }

  String _trimZeros(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Fotoğraf çek'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Galeriden seç'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 82,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedImageBytes = bytes;
        _pickedImageName = picked.name;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fotoğraf seçilemedi')),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final price =
        double.tryParse(_price.text.trim().replaceAll(',', '.')) ?? 0;
    final stock =
        double.tryParse(_stock.text.trim().replaceAll(',', '.')) ?? 0;

    setState(() => _saving = true);
    final repo = ref.read(productRepositoryProvider);
    try {
      String? imageKey;
      if (_pickedImageBytes != null) {
        imageKey = await repo.uploadImage(
          bytes: _pickedImageBytes!,
          filename: _pickedImageName ?? 'photo.jpg',
        );
      }

      if (_isEdit) {
        await repo.update(
          widget.product!.id,
          name: _name.text.trim(),
          unit: _unit,
          price: price,
          stock: stock,
          description: _description.text.trim(),
          categoryId: _categoryId,
          imageKey: imageKey, // null ise mevcut fotoğraf korunur
        );
      } else {
        await repo.create(
          name: _name.text.trim(),
          unit: _unit,
          price: price,
          stock: stock,
          description: _description.text.trim(),
          categoryId: _categoryId,
          imageKey: imageKey,
        );
      }
      ref.invalidate(productsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Ürün güncellendi' : 'Ürün eklendi'),
        ),
      );
      context.pop();
    } on DioException catch (e) {
      if (!mounted) return;
      String msg = _isEdit ? 'Ürün güncellenemedi' : 'Ürün eklenemedi';
      final data = e.response?.data;
      if (data is Map && data['detail'] is String) {
        msg = data['detail'] as String;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sunucuya ulaşılamadı')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ürünü sil'),
        content: Text(
          '"${widget.product!.name}" kalıcı olarak silinecek. Emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _saving = true);
    try {
      await ref.read(productRepositoryProvider).delete(widget.product!.id);
      ref.invalidate(productsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ürün silindi')),
      );
      context.pop();
    } on DioException catch (e) {
      if (!mounted) return;
      String msg = 'Ürün silinemedi';
      final data = e.response?.data;
      if (data is Map && data['detail'] is String) {
        msg = data['detail'] as String;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      setState(() => _saving = false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sunucuya ulaşılamadı')),
      );
      setState(() => _saving = false);
    }
  }

  Future<void> _addCategory() async {
    final ctl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni kategori'),
        content: TextField(
          controller: ctl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Kategori adı'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctl.text.trim()),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      final created =
          await ref.read(productRepositoryProvider).createCategory(name);
      ref.invalidate(categoriesProvider);
      setState(() => _categoryId = created.id);
    } on DioException catch (e) {
      if (!mounted) return;
      String msg = 'Kategori eklenemedi';
      final data = e.response?.data;
      if (data is Map && data['detail'] is String) {
        msg = data['detail'] as String;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ref.watch(categoriesProvider);

    final existingImageUrl = widget.product?.imageUrl;
    final units = {..._commonUnits, _unit}.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Ürünü düzenle' : 'Yeni ürün'),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: 'Ürünü sil',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _saving ? null : _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Fotoğraf alanı
            Center(
              child: GestureDetector(
                onTap: _saving ? null : _pickImage,
                child: Container(
                  width: 148,
                  height: 148,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.line, width: 1.4),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _pickedImageBytes != null
                      ? Image.memory(_pickedImageBytes!, fit: BoxFit.cover)
                      : (existingImageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: existingImageUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  const _PhotoPlaceholder(),
                            )
                          : const _PhotoPlaceholder()),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _saving ? null : _pickImage,
                icon: const Icon(Icons.photo_camera_rounded, size: 18),
                label: Text(
                  (_pickedImageBytes != null || existingImageUrl != null)
                      ? 'Fotoğrafı değiştir'
                      : 'Fotoğraf ekle',
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Ürün adı *',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ürün adı zorunlu' : null,
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Fiyat (₺) *',
                      prefixIcon: Icon(Icons.sell_outlined),
                    ),
                    validator: (v) {
                      final d = double.tryParse(
                          (v ?? '').trim().replaceAll(',', '.'));
                      if (d == null || d < 0) return 'Geçerli fiyat girin';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _stock,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Stok *',
                      prefixIcon: Icon(Icons.numbers_rounded),
                    ),
                    validator: (v) {
                      final d = double.tryParse(
                          (v ?? '').trim().replaceAll(',', '.'));
                      if (d == null || d < 0) return 'Geçerli stok girin';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Birim seçimi
            Text(
              'Birim',
              style:
                  theme.textTheme.titleSmall?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final u in units)
                  ChoiceChip(
                    label: Text(u),
                    selected: _unit == u,
                    onSelected: (_) => setState(() => _unit = u),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Başka'),
                  onPressed: () async {
                    final ctl = TextEditingController();
                    final custom = await showDialog<String>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Özel birim'),
                        content: TextField(
                          controller: ctl,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: 'Birim (ör. çuval)',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Vazgeç'),
                          ),
                          FilledButton(
                            onPressed: () =>
                                Navigator.pop(ctx, ctl.text.trim()),
                            child: const Text('Kullan'),
                          ),
                        ],
                      ),
                    );
                    if (custom != null && custom.isNotEmpty) {
                      setState(() => _unit = custom);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Kategori seçimi
            Text(
              'Kategori',
              style:
                  theme.textTheme.titleSmall?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            categories.when(
              loading: () => const LinearProgressIndicator(minHeight: 2),
              error: (_, __) => const Text(
                'Kategoriler yüklenemedi',
                style: TextStyle(color: AppColors.textMuted),
              ),
              data: (list) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Kategorisiz'),
                    selected: _categoryId == null,
                    onSelected: (_) => setState(() => _categoryId = null),
                  ),
                  for (final c in list)
                    ChoiceChip(
                      label: Text(c.name),
                      selected: _categoryId == c.id,
                      onSelected: (_) => setState(() => _categoryId = c.id),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Yeni kategori'),
                    onPressed: _saving ? null : _addCategory,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Açıklama (opsiyonel)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(_isEdit ? 'Kaydet' : 'Ürünü ekle'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_a_photo_outlined, size: 34, color: AppColors.textMuted),
        SizedBox(height: 8),
        Text(
          'Fotoğraf ekle',
          style: TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
