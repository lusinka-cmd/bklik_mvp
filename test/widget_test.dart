import 'package:bklik_mvp/main.dart';
import 'package:bklik_mvp/screens/bklik_mvp_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Bklik MVP opens the first screen', (tester) async {
    await tester.pumpWidget(const BklikApp());
    await tester.pump();

    expect(find.byType(BklikMvpScreen), findsOneWidget);
  });
}
