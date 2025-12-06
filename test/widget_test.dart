import 'package:flutter_test/flutter_test.dart';
import 'package:coomer_downloader/main.dart';

void main() {
  testWidgets('App starts correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const CoomerApp());
    expect(find.text('Coomer'), findsOneWidget);
  });
}
