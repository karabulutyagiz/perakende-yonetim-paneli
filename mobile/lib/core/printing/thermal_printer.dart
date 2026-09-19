import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

/// Eşleştirilmiş bir Bluetooth fiş yazıcısı.
class ThermalDevice {
  const ThermalDevice({required this.name, required this.macAddress});

  final String name;
  final String macAddress;
}

/// Fiş yazıcısı kağıt genişliği.
enum ThermalPaper {
  mm58(PaperSize.mm58, 384),
  mm80(PaperSize.mm80, 576);

  const ThermalPaper(this.paperSize, this.dots);

  final PaperSize paperSize;

  /// Yazıcının bir satırdaki nokta sayısı — raster görsel bu genişliğe ölçeklenir.
  final int dots;

  String get label => this == ThermalPaper.mm58 ? '58 mm' : '80 mm';
}

class ThermalPrintException implements Exception {
  ThermalPrintException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// ESC/POS Bluetooth fiş yazıcısı sürücüsü.
///
/// Dekont metin olarak değil **raster görsel** olarak basılır: ucuz yazıcıların
/// çoğu Türkçe karakter code page'ini (CP857) desteklemediği için "ş/ğ/İ"
/// bozuk çıkıyor. Görsel basımda böyle bir sorun olmaz, düzen de ekrandakiyle
/// birebir aynı olur.
class ThermalPrinter {
  const ThermalPrinter();

  /// Telefonun Bluetooth'u açık mı?
  Future<bool> isBluetoothEnabled() async {
    try {
      return await PrintBluetoothThermal.bluetoothEnabled;
    } catch (_) {
      return false;
    }
  }

  /// Sisteme eşleştirilmiş yazıcılar. Eşleştirme telefonun Bluetooth
  /// ayarlarından yapılır; uygulama içinde tarama yapılmaz.
  Future<List<ThermalDevice>> pairedDevices() async {
    final devices = await PrintBluetoothThermal.pairedBluetooths;
    return [
      for (final d in devices)
        ThermalDevice(name: d.name, macAddress: d.macAdress),
    ];
  }

  /// Dekont PNG'sini verilen yazıcıya basar.
  ///
  /// [receiptPng] ekrandan yakalanan dekont görseli.
  Future<void> printReceipt({
    required ThermalDevice device,
    required Uint8List receiptPng,
    ThermalPaper paper = ThermalPaper.mm58,
  }) async {
    if (!await isBluetoothEnabled()) {
      throw ThermalPrintException(
        'Bluetooth kapalı. Telefonun Bluetooth ayarını açıp tekrar deneyin.',
      );
    }

    final connected = await PrintBluetoothThermal.connect(
      macPrinterAddress: device.macAddress,
    );
    if (!connected) {
      throw ThermalPrintException(
        '${device.name} yazıcısına bağlanılamadı. Yazıcı açık ve menzilde mi?',
      );
    }

    try {
      final bytes = await _buildReceiptBytes(receiptPng: receiptPng, paper: paper);
      final sent = await PrintBluetoothThermal.writeBytes(bytes);
      if (!sent) {
        throw ThermalPrintException('Fiş yazıcıya gönderilemedi');
      }
    } finally {
      // Bağlantıyı bırakmazsak bir sonraki baskı "meşgul" hatası verir.
      await PrintBluetoothThermal.disconnect;
    }
  }

  /// PNG'yi kağıt genişliğine ölçekleyip ESC/POS raster komutlarına çevirir.
  Future<List<int>> _buildReceiptBytes({
    required Uint8List receiptPng,
    required ThermalPaper paper,
  }) async {
    final decoded = img.decodeImage(receiptPng);
    if (decoded == null) {
      throw ThermalPrintException('Dekont görseli çözümlenemedi');
    }

    // Genişliği yazıcının nokta sayısına sabitle, oranı koru.
    final resized = img.copyResize(
      decoded,
      width: paper.dots,
      interpolation: img.Interpolation.average,
    );
    // Termal kafa siyah/beyaz basar; gri tonlama + kontrast okunurluğu artırır.
    final mono = img.grayscale(resized);

    final profile = await CapabilityProfile.load();
    final generator = Generator(paper.paperSize, profile);

    return [
      ...generator.reset(),
      ...generator.imageRaster(mono, align: PosAlign.center),
      ...generator.feed(2),
      ...generator.cut(),
    ];
  }
}
