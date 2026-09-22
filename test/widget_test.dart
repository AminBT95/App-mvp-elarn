import 'package:flutter_test/flutter_test.dart';
import 'package:linguapath_mvp/main.dart';

void main() {
  testWidgets('shows LinguaPath welcome', (tester) async {
    await tester.pumpWidget(const LinguaPathApp());
    expect(find.text('LinguaPath'), findsWidgets);
    expect(find.text('Start learning'), findsOneWidget);
  });
}
