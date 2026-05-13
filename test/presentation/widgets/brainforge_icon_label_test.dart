import 'package:brainforge/presentation/widgets/brainforge_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('BrainForgeIconLabel', () {
    testWidgets('renders icon and label', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BrainForgeIconLabel(
            icon: Icons.bolt_rounded,
            label: '320 XP',
          ),
        ),
      );
      expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);
      expect(find.text('320 XP'), findsOneWidget);
    });

    testWidgets('horizontal axis uses Row', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BrainForgeIconLabel(
            icon: Icons.star_rounded,
            label: 'Level 5',
          ),
        ),
      );
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('vertical axis uses Column', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BrainForgeIconLabel(
            icon: Icons.star_rounded,
            label: 'Level 5',
            axis: Axis.vertical,
          ),
        ),
      );
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('text is capped at 2 lines', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BrainForgeIconLabel(
            icon: Icons.info_rounded,
            label:
                'This is a very long label that should be capped',
          ),
        ),
      );
      final textWidget = tester.widget<Text>(find.byType(Text).last);
      expect(textWidget.maxLines, equals(2));
    });
  });
}
