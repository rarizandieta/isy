// Basic smoke test: mounts the app and verifies it renders.

import 'package:flutter_test/flutter_test.dart';

import 'package:isy/main.dart';

void main() {
  testWidgets('IsyApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const IsyApp());

    expect(find.text('Isy'), findsOneWidget);
  });
}
