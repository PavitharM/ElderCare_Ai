import 'package:flutter_test/flutter_test.dart';
import 'package:elder_guard_app/main.dart';

void main() {
  testWidgets('ElderGuardApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ElderGuardApp());
    expect(find.text('ElderGuard AI'), findsOneWidget);
  });
}
