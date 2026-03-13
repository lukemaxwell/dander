import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/main.dart';

void main() {
  testWidgets('DanderApp renders without throwing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DanderApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
