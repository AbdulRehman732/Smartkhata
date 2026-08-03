import 'package:flutter_test/flutter_test.dart';
import 'package:smart_khata_app/main.dart';

void main() {
  testWidgets('Smart Khata Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartKhataApp(isLoggedIn: false));
    expect(find.byType(SmartKhataApp), findsOneWidget);
  });
}
