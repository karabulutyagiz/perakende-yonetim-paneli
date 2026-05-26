import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/formatters.dart';
import '../../orders/data/order_repository.dart';
import '../data/invoice_repository.dart';

final _receiptDt = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');

final invoiceDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, invoiceId) {
  return ref.watch(invoiceRepositoryProvider).getById(invoiceId);
});

class InvoiceReceiptScreen extends ConsumerStatefulWidget {
  const InvoiceReceiptScreen({super.key, required this.invoiceId});

  final String invoiceId;

  @override
  ConsumerState<InvoiceReceiptScreen> createState() =>
      _InvoiceReceiptScreenState();
}

class _InvoiceReceiptScreenState extends ConsumerState<InvoiceReceiptScreen> {
  final GlobalKey _receiptKey = GlobalKey();
  bool _savingImage = false;
  bool _sharingPdf = false;

  @override
  Widget build(BuildContext context) {
    final asyncInvoice = ref.watch(invoiceDetailProvider(widget.invoiceId));
    final orders = ref.watch(allOrdersProvider).valueOrNull ??
        const <Map<String, dynamic>>[];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Geri',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/invoices');
            }
          },
        ),
        title: Text(
          'Fatura dekontu',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
      body: asyncInvoice.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Text('Fatura yüklenemedi. Lütfen tekrar deneyin.'),
        ),
        data: (invoice) {
          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: _savingImage
                            ? null
                            : () => _saveImage(invoice, orders),
                        icon: _savingImage
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.photo_library_outlined),
                        label: const Text('Fotoğraflara kaydet'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _sharingPdf
                            ? null
                            : () => _sharePdf(invoice, orders),
                        icon: _sharingPdf
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('PDF paylaş'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(invoiceDetailProvider(widget.invoiceId)),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        RepaintBoundary(
                          key: _receiptKey,
                          child: _ReceiptCard(invoice: invoice, orders: orders),
                        ),
                      ],
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

  Future<void> _saveImage(
    Map<String, dynamic> invoice,
    List<Map<String, dynamic>> orders,
  ) async {
    setState(() => _savingImage = true);
    try {
      final allowed = await _ensureGalleryPermission();
      if (!allowed) {
        _showMessage(
            'Fotoğraf izni reddedildi. Ayarlar → ParaSende → Fotoğraflar.');
        return;
      }
      final pngBytes = await _captureReceiptPng();
      if (pngBytes == null) {
        _showMessage('Dekont görseli hazırlanamadı');
        return;
      }
      final orderNumber = _invoiceOrderNumber(invoice, orders);
      final result = await ImageGallerySaverPlus.saveImage(
        pngBytes,
        quality: 100,
        name: 'fatura-$orderNumber',
      );
      if (_saveSucceeded(result)) {
        _showMessage('Dekont fotoğraflara kaydedildi');
      } else {
        // Galeri kaydetme başarısız oldu — yedek olarak PDF'i tmp'ye yazıp
        // sistem paylaş arayüzünü aç (kullanıcı oradan kaydet'e dokunabilir).
        await _shareImageFallback(pngBytes, orderNumber);
      }
    } catch (e) {
      _showMessage('Dekont kaydedilemedi: $e');
    } finally {
      if (mounted) setState(() => _savingImage = false);
    }
  }

  Future<void> _shareImageFallback(Uint8List pngBytes, String orderNumber) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/fatura-$orderNumber.png');
      await file.writeAsBytes(pngBytes, flush: true);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Sipariş #$orderNumber dekontu',
        sharePositionOrigin: _shareOriginRect(),
      );
    } catch (e) {
      _showMessage('Dekont kaydedilemedi: $e');
    }
  }

  Future<void> _sharePdf(
    Map<String, dynamic> invoice,
    List<Map<String, dynamic>> orders,
  ) async {
    setState(() => _sharingPdf = true);
    try {
      final pngBytes = await _captureReceiptPng();
      if (pngBytes == null) {
        _showMessage('PDF hazırlanamadı');
        return;
      }
      final doc = pw.Document();
      final memoryImage = pw.MemoryImage(pngBytes);
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (_) =>
              pw.Center(child: pw.Image(memoryImage, fit: pw.BoxFit.contain)),
        ),
      );
      final dir = await getTemporaryDirectory();
      final orderNumber = _invoiceOrderNumber(invoice, orders);
      final file = File('${dir.path}/fatura-$orderNumber.pdf');
      await file.writeAsBytes(await doc.save(), flush: true);
      final shareOrigin = _shareOriginRect();
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Sipariş #$orderNumber faturası',
        sharePositionOrigin: shareOrigin,
      );
    } catch (e) {
      _showMessage('PDF paylaşılamadı: $e');
    } finally {
      if (mounted) setState(() => _sharingPdf = false);
    }
  }

  Future<Uint8List?> _captureReceiptPng() async {
    await Future.delayed(const Duration(milliseconds: 50));
    final boundary = _receiptKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;
    if (boundary.debugNeedsPaint) {
      await Future.delayed(const Duration(milliseconds: 50));
      return _captureReceiptPng();
    }
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  Future<bool> _ensureGalleryPermission() async {
    if (Platform.isIOS) {
      var status = await Permission.photosAddOnly.status;
      if (!status.isGranted && !status.isLimited) {
        status = await Permission.photosAddOnly.request();
      }
      if (status.isGranted || status.isLimited) {
        return true;
      }
      final fullStatus = await Permission.photos.request();
      return fullStatus.isGranted || fullStatus.isLimited;
    }
    if (Platform.isAndroid) {
      final sdk = await _androidSdkInt();
      if (sdk != null && sdk >= 33) {
        final status = await Permission.photos.request();
        return status.isGranted || status.isLimited;
      }
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true;
  }

  Rect _shareOriginRect() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) {
      return const Rect.fromLTWH(0, 0, 1, 1);
    }
    return box.localToGlobal(Offset.zero) & box.size;
  }

  bool _saveSucceeded(dynamic result) {
    if (result is bool) return result;
    if (result is Map) {
      final success = result['isSuccess'];
      if (success is bool) return success;
      final filePath = result['filePath'] ?? result['savedFilePath'];
      if (filePath is String && filePath.isNotEmpty) return true;
    }
    return false;
  }

  Future<int?> _androidSdkInt() async {
    if (!Platform.isAndroid) return null;
    try {
      const channel = MethodChannel('app.device_info');
      return await channel.invokeMethod<int>('sdkInt');
    } catch (_) {
      return null;
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.invoice, required this.orders});

  final Map<String, dynamic> invoice;
  final List<Map<String, dynamic>> orders;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customer = invoice['customer'] as Map<String, dynamic>?;
    final items =
        (invoice['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final createdAt = DateTime.tryParse(invoice['created_at'] as String? ?? '');
    final orderNumber = _invoiceOrderNumber(invoice, orders);
    final businessName = customer?['name'] as String? ?? 'Müşteri';
    final contactName = customer?['account_full_name'] as String?;
    final note = invoice['note'] as String?;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sipariş faturası',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sipariş #$orderNumber',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _InfoRow(label: 'Dükkan', value: businessName, prominent: true),
          if (contactName != null && contactName.isNotEmpty)
            _InfoRow(label: 'Yetkili', value: contactName),
          if (createdAt != null)
            _InfoRow(
                label: 'Tarih', value: _receiptDt.format(createdAt.toLocal())),
          _InfoRow(
              label: 'Ödeme',
              value: _paymentLabel(invoice['payment_method'] as String?)),
          const SizedBox(height: 18),
          Text(
            'Ürünler',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          for (final item in items)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['product_name'] as String? ?? 'Urun',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text('${item['quantity']} ${item['unit'] ?? ''}'),
                        const SizedBox(height: 2),
                        Text(
                          'Birim: ${formatCurrency((item['unit_price'] as num).toDouble())}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    formatCurrency((item['line_total'] as num).toDouble()),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(label: 'Not', value: note),
          ],
          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 18),
          _AmountSummaryRow(
            label: 'Nakit',
            value: formatCurrency((invoice['cash_amount'] as num).toDouble()),
          ),
          _AmountSummaryRow(
            label: 'Kart',
            value: formatCurrency((invoice['card_amount'] as num).toDouble()),
          ),
          _AmountSummaryRow(
            label: 'Borç',
            value: formatCurrency((invoice['debt_amount'] as num).toDouble()),
          ),
          const SizedBox(height: 8),
          _AmountSummaryRow(
            label: 'Genel toplam',
            value: formatCurrency((invoice['total'] as num).toDouble()),
            highlight: true,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.prominent = false,
  });

  final String label;
  final String value;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: (prominent
                    ? theme.textTheme.titleMedium
                    : theme.textTheme.bodyLarge)
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _AmountSummaryRow extends StatelessWidget {
  const _AmountSummaryRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: highlight
                ? theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)
                : theme.textTheme.bodyLarge,
          ),
          const Spacer(),
          Text(
            value,
            style: highlight
                ? theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  )
                : theme.textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

String _invoiceOrderNumber(
  Map<String, dynamic> invoice,
  List<Map<String, dynamic>> orders,
) {
  final orderNumber = invoice['order_number']?.toString();
  if (orderNumber != null && orderNumber.isNotEmpty) {
    return orderNumber;
  }
  final invoiceId = invoice['id']?.toString();
  if (invoiceId != null && invoiceId.isNotEmpty) {
    for (final order in orders) {
      if (order['invoice_id']?.toString() == invoiceId) {
        final explicit = order['order_number']?.toString();
        if (explicit != null && explicit.isNotEmpty) return explicit;
        final orderRaw = order['id']?.toString();
        if (orderRaw != null && orderRaw.isNotEmpty) {
          final value = BigInt.parse(orderRaw.replaceAll('-', ''), radix: 16);
          final digits = (value % BigInt.from(100000000)).toString();
          return digits.padLeft(8, '0');
        }
      }
    }
  }
  final orderId = invoice['order_id']?.toString();
  if (orderId != null && orderId.isNotEmpty) {
    final value = BigInt.parse(orderId.replaceAll('-', ''), radix: 16);
    final digits = (value % BigInt.from(100000000)).toString();
    return digits.padLeft(8, '0');
  }
  return '';
}

String _paymentLabel(String? method) => switch (method) {
      'nakit' => 'Nakit',
      'kart' => 'Kart',
      'borc' => 'Borç',
      _ => 'Bilinmiyor',
    };
