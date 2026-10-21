import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitaltrack/core/providers/providers.dart';
import 'package:vitaltrack/screens/charts/charts_screen.dart';

void main() {
  testWidgets('chart range and metric controls remain available without data', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          readingsProvider.overrideWith((_) async => []),
        ],
        child: const MaterialApp(home: ChartsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('7 Days'), findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);
    expect(find.text('Systolic'), findsOneWidget);
    expect(find.text('No chart data'), findsOneWidget);
  });
}
