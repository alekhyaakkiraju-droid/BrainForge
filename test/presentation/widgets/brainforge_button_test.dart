import 'package:brainforge/core/constants/app_spacing.dart';
import 'package:brainforge/presentation/widgets/brainforge_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('BrainForgeButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        _wrap(BrainForgeButton(label: 'Start', onPressed: () {})),
      );
      expect(find.text('Start'), findsOneWidget);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(
          BrainForgeButton(
            label: 'Go',
            icon: Icons.rocket_launch_rounded,
            onPressed: () {},
          ),
        ),
      );
      expect(find.byIcon(Icons.rocket_launch_rounded), findsOneWidget);
    });

    testWidgets('fires onPressed callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(BrainForgeButton(label: 'Tap', onPressed: () => tapped = true)),
      );
      await tester.tap(find.byType(BrainForgeButton));
      expect(tapped, isTrue);
    });

    testWidgets('shows loading indicator when isLoading=true', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BrainForgeButton(
            label: 'Load',
            isLoading: true,
            onPressed: null,
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Load'), findsNothing);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        _wrap(const BrainForgeButton(label: 'Off', onPressed: null)),
      );
      final btn = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(btn.onPressed, isNull);
    });

    testWidgets('meets 48dp minimum height', (tester) async {
      await tester.pumpWidget(
        _wrap(BrainForgeButton(label: 'H', onPressed: () {})),
      );
      final box = tester.renderObject<RenderBox>(
        find.byType(BrainForgeButton),
      );
      expect(box.size.height, greaterThanOrEqualTo(AppSpacing.minTouchTarget));
    });

    testWidgets('outlined variant renders OutlinedButton', (tester) async {
      await tester.pumpWidget(
        _wrap(
          BrainForgeButton(
            label: 'O',
            variant: BrainForgeButtonVariant.outlined,
            onPressed: () {},
          ),
        ),
      );
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('ghost variant renders TextButton', (tester) async {
      await tester.pumpWidget(
        _wrap(
          BrainForgeButton(
            label: 'G',
            variant: BrainForgeButtonVariant.ghost,
            onPressed: () {},
          ),
        ),
      );
      expect(find.byType(TextButton), findsOneWidget);
    });
  });
}
