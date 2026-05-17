import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wikato/app.dart';

void main() {
  testWidgets('Wikato app boots to splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const WikatoApp());
    await tester.pump();

    expect(find.text('Wikato'), findsOneWidget);
    expect(find.byIcon(Icons.language_rounded), findsOneWidget);
  });
}
