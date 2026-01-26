import 'package:flutter_test/flutter_test.dart';
import 'package:aucorsa_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AucorsaApp());
    
    // Verify app title is present
    expect(find.text('Aucorsa - Líneas'), findsOneWidget);
  });
}
