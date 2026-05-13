import 'package:brainforge/core/constants/app_spacing.dart';
import 'package:brainforge/presentation/widgets/brainforge_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('BrainForgeCard', () {
    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(
        _wrap(const BrainForgeCard(child: Text('Quest'))),
      );
      expect(find.text('Quest'), findsOneWidget);
    });

    testWidgets('fires onTap callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          BrainForgeCard(
            onTap: () => tapped = true,
            child: const Text('Tap me'),
          ),
        ),
      );
      await tester.tap(find.byType(BrainForgeCard));
      expect(tapped, isTrue);
    });

    testWidgets('meets 48dp min height when tappable', (tester) async {
      await tester.pumpWidget(
        _wrap(
          BrainForgeCard(
            onTap: () {},
            child: const Text('X'),
          ),
        ),
      );
      final box = tester.renderObject<RenderBox>(
        find.byType(ConstrainedBox).first,
      );
      expect(
        box.constraints.minHeight,
        greaterThanOrEqualTo(AppSpacing.minTouchTarget),
      );
    });

    testWidgets('renders accent stripe when accentColor provided',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BrainForgeCard(
            accentColor: Colors.purple,
            child: Text('A'),
          ),
        ),
      );
      final containers =
          tester.widgetList<Container>(find.byType(Container));
      final stripe = containers.any(
        (c) =>
            c.constraints?.maxWidth == 6 ||
            (c.decoration is BoxDecoration &&
                (c.decoration! as BoxDecoration).color == Colors.purple),
      );
      expect(stripe, isTrue);
    });
  });
}
