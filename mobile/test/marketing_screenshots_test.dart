import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gokce_toptan/core/marketing/marketing_capture.dart';
import 'package:gokce_toptan/core/theme/app_theme.dart';
import 'package:gokce_toptan/features/cart/presentation/cart_screen.dart';
import 'package:gokce_toptan/features/invoices/presentation/invoices_screen.dart';
import 'package:gokce_toptan/features/products/presentation/home_screen.dart';
import 'package:gokce_toptan/features/reports/presentation/reports_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const size = Size(430, 932);
  const selected = String.fromEnvironment('CAPTURE_SCREEN', defaultValue: '01');

  testWidgets('captures marketing screenshots from real app screens', (tester) async {
    await _loadRealFonts();
    await tester.binding.setSurfaceSize(size);

    final root = Directory.current.parent.path;
    final appleDir = Directory('$root/public/screenshots/apple/iphone/tr');
    final androidDir = Directory('$root/public/screenshots/android/phone/tr');
    appleDir.createSync(recursive: true);
    androidDir.createSync(recursive: true);

    final item = switch (selected) {
      '02' => (file: '02.png', screen: const CartScreen()),
      '03' => (file: '03.png', screen: const InvoicesScreen()),
      '04' => (file: '04.png', screen: const ReportsScreen()),
      _ => (file: '01.png', screen: const HomeScreen()),
    };

      final key = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          overrides: marketingProviderOverrides,
          child: RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: _captureTheme(),
              locale: const Locale('tr', 'TR'),
              supportedLocales: const [Locale('tr', 'TR')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: MediaQuery(
                data: const MediaQueryData(size: size, devicePixelRatio: 3),
                child: item.screen,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 800));

    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = data!.buffer.asUint8List();
    File('${appleDir.path}/${item.file}').writeAsBytesSync(bytes);
    File('${androidDir.path}/${item.file}').writeAsBytesSync(bytes);
    image.dispose();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.binding.setSurfaceSize(null);
  });
}

ThemeData _captureTheme() {
  final theme = AppTheme.light();
  return theme.copyWith(
    textTheme: theme.textTheme.apply(fontFamily: 'Roboto'),
    primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'Roboto'),
  );
}

Future<void> _loadRealFonts() async {
  final textFont = File('/System/Library/Fonts/Helvetica.ttc').readAsBytesSync();
  final iconsFont = File(
    '/Users/yagizkarabulut/development/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ).readAsBytesSync();

  await (FontLoader('Roboto')
        ..addFont(Future.value(ByteData.sublistView(textFont))))
      .load();
  await (FontLoader('.SF Pro Text')
        ..addFont(Future.value(ByteData.sublistView(textFont))))
      .load();
  await (FontLoader('Ahem')
        ..addFont(Future.value(ByteData.sublistView(textFont))))
      .load();
  await (FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.sublistView(iconsFont))))
      .load();
}
