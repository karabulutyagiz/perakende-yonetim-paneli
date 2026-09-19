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
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/printing/thermal_printer.dart';
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
  final GlobalKey _thermalKey = GlobalKey();
  static const _thermalPrinter = ThermalPrinter();

  /// Termal fiş mantıksal genişliği. 58 mm yazıcı = 384 nokta, bu yüzden
  /// pixelRatio 1'de birebir eşleşir (80 mm için 1.5 ile yakalanır).
  static const double _thermalWidth = 384;
  bool _savingImage = false;
  bool _sharingPdf = false;
  bool _printing = false;
  bool _savingPdf = false;

  bool get _busy => _savingImage || _sharingPdf || _printing || _savingPdf;

  @override
  Widget build(BuildContext context) {
    final asyncInvoice = ref.watch(invoiceDetailProvider(widget.invoiceId));
    final orders = ref.watch(allOrdersProvider).valueOrNull ??
        const <Map<String, dynamic>>[];
    return Scaffold(
      appBar: AppBar(
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
        title: const Text('Fatura dekontu'),
      ),
      body: asyncInvoice.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Text('Fatura yüklenemedi. Lütfen tekrar deneyin.'),
        ),
        data: (invoice) {
          return SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: _busy
                                ? null
                                : () => _showPrintSheet(invoice, orders),
                            icon: _printing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child:
                                        CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.print_outlined),
                            label: const Text('Yazdır'),
                          ),
                          OutlinedButton.icon(
                            onPressed:
                                _busy ? null : () => _savePdf(invoice, orders),
                            icon: _savingPdf
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child:
                                        CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.picture_as_pdf_outlined),
                            label: const Text('PDF kaydet'),
                          ),
                          OutlinedButton.icon(
                            onPressed:
                                _busy ? null : () => _sharePdf(invoice, orders),
                            icon: _sharingPdf
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child:
                                        CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.ios_share_rounded),
                            label: const Text('Paylaş'),
                          ),
                          OutlinedButton.icon(
                            onPressed:
                                _busy ? null : () => _saveImage(invoice, orders),
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
                // Termal fiş — ekran dışında render edilir, sadece yazdırırken
                // görüntüsü yakalanır. A4 dekontu 58 mm'ye küçültmek okunmaz
                // olurdu; fiş yazıcısı için ayrı, dar ve düz bir düzen gerekli.
                Positioned(
                  left: -_thermalWidth * 2,
                  top: 0,
                  child: RepaintBoundary(
                    key: _thermalKey,
                    child: SizedBox(
                      width: _thermalWidth,
                      child: _ThermalReceiptCard(
                        invoice: invoice,
                        orders: orders,
                      ),
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
            'Fotoğraf izni reddedildi. Ayarlar → Zirve Toptan → Fotoğraflar.');
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

  /// Dekont görselini A4 PDF'e gömer. Yazdırma, kaydetme ve paylaşma
  /// aynı çıktıyı kullanır.
  Future<Uint8List?> _buildPdfBytes() async {
    final pngBytes = await _captureReceiptPng();
    if (pngBytes == null) return null;
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
    return doc.save();
  }

  Future<void> _sharePdf(
    Map<String, dynamic> invoice,
    List<Map<String, dynamic>> orders,
  ) async {
    setState(() => _sharingPdf = true);
    try {
      final bytes = await _buildPdfBytes();
      if (bytes == null) {
        _showMessage('PDF hazırlanamadı');
        return;
      }
      final dir = await getTemporaryDirectory();
      final orderNumber = _invoiceOrderNumber(invoice, orders);
      final file = File('${dir.path}/fatura-$orderNumber.pdf');
      await file.writeAsBytes(bytes, flush: true);
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

  /// Faturayı PDF olarak cihaza kaydeder — sistem "kaydet" diyaloğu açılır
  /// (Android: Dosyalar/İndirilenler, iOS: Dosyalar uygulaması).
  Future<void> _savePdf(
    Map<String, dynamic> invoice,
    List<Map<String, dynamic>> orders,
  ) async {
    setState(() => _savingPdf = true);
    try {
      final bytes = await _buildPdfBytes();
      if (bytes == null) {
        _showMessage('PDF hazırlanamadı');
        return;
      }
      final orderNumber = _invoiceOrderNumber(invoice, orders);
      // file_picker 11'de saveFile statik API.
      final path = await FilePicker.saveFile(
        dialogTitle: 'Faturayı PDF olarak kaydet',
        fileName: 'fatura-$orderNumber.pdf',
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        bytes: bytes,
      );
      if (path == null) return; // kullanıcı vazgeçti
      _showMessage('Fatura PDF olarak kaydedildi');
    } catch (e) {
      _showMessage('PDF kaydedilemedi: $e');
    } finally {
      if (mounted) setState(() => _savingPdf = false);
    }
  }

  /// "Yazdır" → sistem yazıcısı mı, Bluetooth fiş yazıcısı mı?
  Future<void> _showPrintSheet(
    Map<String, dynamic> invoice,
    List<Map<String, dynamic>> orders,
  ) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.print_rounded),
              title: const Text('Sistem yazıcısı'),
              subtitle: Text(
                Platform.isIOS
                    ? 'AirPrint destekli yazıcılar — A4 fatura'
                    : 'Wi-Fi / USB yazıcılar — A4 fatura',
              ),
              onTap: () => Navigator.pop(ctx, 'system'),
            ),
            ListTile(
              leading: const Icon(Icons.bluetooth_rounded),
              title: const Text('Bluetooth fiş yazıcısı'),
              subtitle: const Text('58/80 mm termal fiş'),
              onTap: () => Navigator.pop(ctx, 'thermal'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'system') {
      await _printSystem(invoice, orders);
    } else {
      await _printThermal();
    }
  }

  Future<void> _printSystem(
    Map<String, dynamic> invoice,
    List<Map<String, dynamic>> orders,
  ) async {
    setState(() => _printing = true);
    try {
      final bytes = await _buildPdfBytes();
      if (bytes == null) {
        _showMessage('Fatura yazdırmaya hazırlanamadı');
        return;
      }
      final orderNumber = _invoiceOrderNumber(invoice, orders);
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'fatura-$orderNumber',
      );
    } catch (e) {
      _showMessage('Yazdırılamadı: $e');
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  Future<void> _printThermal() async {
    setState(() => _printing = true);
    try {
      if (!await _thermalPrinter.isBluetoothEnabled()) {
        _showMessage(
          'Bluetooth kapalı. Telefonun Bluetooth ayarını açıp tekrar deneyin.',
        );
        return;
      }
      final devices = await _thermalPrinter.pairedDevices();
      if (!mounted) return;
      if (devices.isEmpty) {
        _showMessage(
          'Eşleştirilmiş fiş yazıcısı yok. Önce telefonun Bluetooth '
          'ayarlarından yazıcıyı eşleştirin.',
        );
        return;
      }

      final selection = await _pickThermalDevice(devices);
      if (!mounted || selection == null) return;

      final pngBytes = await _captureThermalPng(selection.paper);
      if (pngBytes == null) {
        _showMessage('Fiş görseli hazırlanamadı');
        return;
      }
      await _thermalPrinter.printReceipt(
        device: selection.device,
        receiptPng: pngBytes,
        paper: selection.paper,
      );
      _showMessage('Fiş yazıcıya gönderildi');
    } on ThermalPrintException catch (e) {
      _showMessage(e.message);
    } catch (e) {
      _showMessage('Fiş yazdırılamadı: $e');
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  Future<_ThermalSelection?> _pickThermalDevice(
    List<ThermalDevice> devices,
  ) async {
    var paper = ThermalPaper.mm58;
    return showModalBottomSheet<_ThermalSelection>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Text(
                    'Fiş yazıcısı seç',
                    style: Theme.of(ctx)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: SegmentedButton<ThermalPaper>(
                    segments: [
                      for (final p in ThermalPaper.values)
                        ButtonSegment(value: p, label: Text(p.label)),
                    ],
                    selected: {paper},
                    onSelectionChanged: (sel) =>
                        setSheetState(() => paper = sel.first),
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    itemCount: devices.length,
                    itemBuilder: (_, i) {
                      final d = devices[i];
                      return ListTile(
                        leading: const Icon(Icons.print_rounded),
                        title: Text(
                          d.name.isEmpty ? 'İsimsiz yazıcı' : d.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(d.macAddress),
                        onTap: () => Navigator.pop(
                          ctx,
                          _ThermalSelection(device: d, paper: paper),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Ekran dışındaki termal fişi, yazıcının nokta genişliğine denk gelen
  /// çözünürlükte yakalar.
  Future<Uint8List?> _captureThermalPng(ThermalPaper paper) async {
    final pixelRatio = paper.dots / _thermalWidth;
    return _captureBoundaryPng(_thermalKey, pixelRatio: pixelRatio);
  }

  Future<Uint8List?> _captureReceiptPng() =>
      _captureBoundaryPng(_receiptKey, pixelRatio: 3);

  Future<Uint8List?> _captureBoundaryPng(
    GlobalKey key, {
    required double pixelRatio,
    int attempt = 0,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    if (boundary.debugNeedsPaint) {
      // Henüz boyanmadıysa bir kare bekle; sonsuz döngüye girmesin.
      if (attempt >= 10) return null;
      return _captureBoundaryPng(key,
          pixelRatio: pixelRatio, attempt: attempt + 1);
    }
    final image = await boundary.toImage(pixelRatio: pixelRatio);
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

/// 58/80 mm termal fiş düzeni — saf siyah/beyaz, geniş punto, gölge/renk yok.
/// Yazıcı kafası gri tonları noktalayarak basar; bu yüzden her şey düz siyah.
class _ThermalReceiptCard extends StatelessWidget {
  const _ThermalReceiptCard({required this.invoice, required this.orders});

  final Map<String, dynamic> invoice;
  final List<Map<String, dynamic>> orders;

  static const _black = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    final customer = invoice['customer'] as Map<String, dynamic>?;
    final items =
        (invoice['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final createdAt = DateTime.tryParse(invoice['created_at'] as String? ?? '');
    final orderNumber = _invoiceOrderNumber(invoice, orders);
    final total = (invoice['total'] as num).toDouble();
    final discountTotal = (invoice['discount_total'] as num?)?.toDouble() ?? 0;
    final subtotal =
        (invoice['subtotal'] as num?)?.toDouble() ?? total + discountTotal;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      child: DefaultTextStyle(
        style: const TextStyle(
          color: _black,
          fontSize: 21,
          height: 1.25,
          fontWeight: FontWeight.w600,
        ),
        child: Column(
          // Yüksekliği sınırsız (ekran dışı) olduğu için min.
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Text(
                'ZİRVE TOPTAN',
                style: TextStyle(
                  color: _black,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Center(child: Text('SİPARİŞ FİŞİ')),
            const _ThermalDivider(),
            _ThermalRow(label: 'Fiş No', value: '#$orderNumber'),
            if (createdAt != null)
              _ThermalRow(
                label: 'Tarih',
                value: _receiptDt.format(createdAt.toLocal()),
              ),
            _ThermalRow(
              label: 'Müşteri',
              value: customer?['name'] as String? ?? '-',
            ),
            _ThermalRow(
              label: 'Ödeme',
              value: _paymentLabel(invoice['payment_method'] as String?),
            ),
            const _ThermalDivider(),
            for (final item in items) _ThermalItem(item: item),
            const _ThermalDivider(),
            if (discountTotal > 0) ...[
              _ThermalRow(
                label: 'Ara toplam',
                value: formatCurrency(subtotal),
              ),
              _ThermalRow(
                label: 'İndirim',
                value: '-${formatCurrency(discountTotal)}',
              ),
              const SizedBox(height: 4),
            ],
            _ThermalRow(label: 'Nakit', value: formatCurrency((invoice['cash_amount'] as num).toDouble())),
            _ThermalRow(label: 'Kart', value: formatCurrency((invoice['card_amount'] as num).toDouble())),
            _ThermalRow(label: 'Borç', value: formatCurrency((invoice['debt_amount'] as num).toDouble())),
            const _ThermalDivider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOPLAM',
                  style: TextStyle(
                    color: _black,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  formatCurrency(total),
                  style: const TextStyle(
                    color: _black,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Center(child: Text('Teşekkür ederiz')),
          ],
        ),
      ),
    );
  }
}

class _ThermalDivider extends StatelessWidget {
  const _ThermalDivider();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Divider(height: 1, thickness: 2, color: Color(0xFF000000)),
      );
}

class _ThermalRow extends StatelessWidget {
  const _ThermalRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label:'),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

class _ThermalItem extends StatelessWidget {
  const _ThermalItem({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final unitPrice = (item['unit_price'] as num).toDouble();
    final listPrice = (item['list_unit_price'] as num?)?.toDouble();
    final discounted = listPrice != null && listPrice > unitPrice;
    final quantity = (item['quantity'] as num).toDouble();
    final qtyLabel = quantity == quantity.roundToDouble()
        ? quantity.toStringAsFixed(0)
        : quantity.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            (item['product_name'] as String? ?? 'Ürün').toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF000000),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$qtyLabel ${item['unit'] ?? ''} x ${formatCurrency(unitPrice)}',
                ),
              ),
              Text(
                formatCurrency((item['line_total'] as num).toDouble()),
                style: const TextStyle(
                  color: Color(0xFF000000),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (discounted)
            Text(
              'İndirimsiz: ${formatCurrency(listPrice)}',
              style: const TextStyle(fontSize: 18),
            ),
        ],
      ),
    );
  }
}

/// Fiş yazıcısı seçimi + kağıt genişliği.
class _ThermalSelection {
  const _ThermalSelection({required this.device, required this.paper});
  final ThermalDevice device;
  final ThermalPaper paper;
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
    final total = (invoice['total'] as num).toDouble();
    final discountTotal = (invoice['discount_total'] as num?)?.toDouble() ?? 0;
    final subtotal =
        (invoice['subtotal'] as num?)?.toDouble() ?? total + discountTotal;

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
                        Builder(builder: (_) {
                          final unitPrice =
                              (item['unit_price'] as num).toDouble();
                          final listPrice =
                              (item['list_unit_price'] as num?)?.toDouble();
                          final discounted =
                              listPrice != null && listPrice > unitPrice;
                          return Row(
                            children: [
                              Text(
                                'Birim: ${formatCurrency(unitPrice)}',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (discounted) ...[
                                const SizedBox(width: 6),
                                Text(
                                  formatCurrency(listPrice),
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ],
                          );
                        }),
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
          if (discountTotal > 0) ...[
            _AmountSummaryRow(
              label: 'Ara toplam',
              value: formatCurrency(subtotal),
            ),
            _AmountSummaryRow(
              label: 'İndirim',
              value: '-${formatCurrency(discountTotal)}',
            ),
            const SizedBox(height: 8),
          ],
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
