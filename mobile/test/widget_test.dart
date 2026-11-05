import 'package:flutter_test/flutter_test.dart';

import 'package:fashion_store/main.dart';

void main() {
  testWidgets('Aplikasi ME smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AplikasiME());
    expect(find.text('KATALOG'), findsOneWidget);
    expect(find.text('PESANAN'), findsOneWidget);
    expect(find.text('KELOLA'), findsOneWidget);
  });
}
