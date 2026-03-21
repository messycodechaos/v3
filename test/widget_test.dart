import 'package:flutter_test/flutter_test.dart';
import 'package:aa3333/main.dart'; // Ensure 'aa3333' is your project name

void main() {
  testWidgets('GuardianX App Load Test', (WidgetTester tester) async {
    await tester.pumpWidget(const GuardianXApp());
    expect(find.text('GUARDIAN X'), findsOneWidget);
  });
}