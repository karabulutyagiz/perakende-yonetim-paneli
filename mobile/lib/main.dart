import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/auth/auth_controller.dart';
import 'core/marketing/marketing_capture.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/ws/live_sync.dart';

void main() {
  runApp(ProviderScope(
    overrides: kMarketingCapture ? marketingProviderOverrides : const [],
    child: const ToptanApp(),
  ));
}

class ToptanApp extends ConsumerWidget {
  const ToptanApp({super.key, this.enableLiveSync = true});

  final bool enableLiveSync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (enableLiveSync && !kMarketingCapture) {
      ref.watch(liveSyncProvider);
    }
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'ParaSende',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      themeMode: ThemeMode.light,
      routerConfig: router,
      builder: (context, child) {
        final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
        final isLoading =
            ref.watch(authControllerProvider).status == AuthStatus.loading;
        if (!isLoading) {
          MarketingCapture.maybeStart(context, router);
        }
        return RepaintBoundary(
          key: MarketingCapture.boundaryKey,
          child: Theme(
            data: AppTheme.light(isTablet: isTablet),
            child: isLoading
                ? const _BootSplash()
                : (child ?? const SizedBox.shrink()),
          ),
        );
      },
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

class _BootSplash extends StatelessWidget {
  const _BootSplash();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image(
              image: AssetImage('assets/icon/parasende.png'),
              width: 96,
              height: 96,
            ),
            SizedBox(height: 16),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
