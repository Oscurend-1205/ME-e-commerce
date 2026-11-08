import 'package:flutter_test/flutter_test.dart';

import 'package:fashion_store/main.dart';

void main() {
  testWidgets('Aplikasi ME smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AplikasiME());
    expect(find.text('BERANDA'), findsAtLeastNWidgets(1));
    expect(find.text('JELAJAH'), findsOneWidget);
    expect(find.text('PESANAN'), findsOneWidget);
    expect(find.text('AKUN'), findsOneWidget);
    expect(find.text('KELOLA'), findsOneWidget);
  });
}
