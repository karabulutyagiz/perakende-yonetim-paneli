import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api.dart';
import 'core/app_router.dart';
import 'core/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Router başlamadan önce token'lar hazır olsun — aksi hâlde auth'lu kullanıcı
  // kısa süreliğine /login'e atılır.
  final prefs = await SharedPreferences.getInstance();
  final initial = AuthTokens(
    access: prefs.getString('gokce.admin.access'),
    refresh: prefs.getString('gokce.admin.refresh'),
  );
  runApp(
    ProviderScope(
      overrides: [
        tokensProvider.overrideWith((_) => AuthNotifier.seeded(initial)),
      ],
      child: const AdminApp(),
    ),
  );
}

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Toptan Panel',
      debugShowCheckedModeBanner: false,
      theme: adminTheme,
      routerConfig: router,
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [Locale('tr', 'TR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
