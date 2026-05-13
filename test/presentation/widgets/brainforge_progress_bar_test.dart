import 'package:brainforge/presentation/widgets/brainforge_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('BrainForgeProgressBar', () {
    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BrainForgeProgressBar(value: 0.5, label: 'Daily XP'),
        ),
      );
      expect(find.text('Daily XP'), findsOneWidget);
    });

    testWidgets('shows percentage by default', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BrainForgeProgressBar(value: 0.75, label: 'XP'),
        ),
      );
      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('hides percentage when showPercentage=false', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BrainForgeProgressBar(
            value: 0.5,
            label: 'XP',
            showPercentage: false,
          ),
        ),
      );
      expect(find.text('50%'), findsNothing);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BrainForgeProgressBar(
            value: 0.3,
            label: 'XP',
            icon: Icons.bolt_rounded,
          ),
        ),
      );
      expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);
    });

    testWidgets('throws assertion for value > 1', (tester) async {
      expect(
        () => BrainForgeProgressBar(value: 1.1, label: 'Over'),
        throwsAssertionError,
      );
    });

    testWidgets('throws assertion for value < 0', (tester) async {
      expect(
        () => BrainForgeProgressBar(value: -0.1, label: 'Under'),
        throwsAssertionError,
      );
    });
  });
}
