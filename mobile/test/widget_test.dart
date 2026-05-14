import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gokce_toptan/main.dart';

void main() {
  testWidgets('Uygulama açılışta çizilir', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ToptanApp()));
    await tester.pump();

    expect(find.byType(ToptanApp), findsOneWidget);
  });
}
