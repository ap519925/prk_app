import 'package:flutter_test/flutter_test.dart';
import 'package:find_my_car/main.dart';

void main() {
  testWidgets('App builds and shows Prk title', (WidgetTester tester) async {
    await tester.pumpWidget(const FindMyCarApp());
    await tester.pumpAndSettle();

    // The redesigned home shows "Prk" in the app bar title.
    expect(find.text('Prk'), findsWidgets);
  });
}
