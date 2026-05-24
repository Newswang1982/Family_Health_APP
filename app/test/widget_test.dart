import 'package:flutter_test/flutter_test.dart';
import 'package:family_health/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FamilyHealthApp());
    expect(find.byType(FamilyHealthApp), findsOneWidget);
  });
}
