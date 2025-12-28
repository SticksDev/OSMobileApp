import 'package:flutter_test/flutter_test.dart';
import 'package:openshock_mobile/main.dart';

void main() {
  testWidgets('App loads splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const OpenShockApp());

    // Verify that the splash screen shows the app name
    expect(find.text('OpenShock'), findsOneWidget);
  });
}
