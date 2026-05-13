import 'package:flutter/material.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/brainforge_widgets.dart';

/// Debug-only showcase of all BrainForge design-system components.
///
/// Accessible via the /design-system route in debug builds only.
/// Provides a living style guide for designers and developers.
class DesignSystemScreen extends StatelessWidget {
  const DesignSystemScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Design System'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _Section(title: 'Colors', child: _ColorPalette()),
              _Section(title: 'Typography', child: _TypographyScale()),
              _Section(title: 'BrainForgeButton', child: _ButtonShowcase()),
              _Section(title: 'BrainForgeCard', child: _CardShowcase()),
              _Section(
                title: 'BrainForgeProgressBar',
                child: _ProgressShowcase(),
              ),
              _Section(
                title: 'BrainForgeIconLabel',
                child: _IconLabelShowcase(),
              ),
            ],
          ),
        ),
      );
}

// ── Section wrapper ──────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      );
}

// ── Color palette ────────────────────────────────────────────────────────────

class _ColorPalette extends StatelessWidget {
  const _ColorPalette();

  @override
  Widget build(BuildContext context) {
    const swatches = <(String, Color)>[
      ('Primary', AppColors.primary),
      ('Primary Dark', AppColors.primaryDark),
      ('Secondary', AppColors.secondary),
      ('ScienceSpark', AppColors.scienceSpark),
      ('Success', AppColors.success),
      ('Warning', AppColors.warning),
      ('Error', AppColors.error),
      ('XP Gold', AppColors.xpGold),
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: swatches
          .map((s) => _ColorSwatch(label: s.$1, color: s.$2))
          .toList(),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
}

// ── Typography ───────────────────────────────────────────────────────────────

class _TypographyScale extends StatelessWidget {
  const _TypographyScale();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final styles = <(String, TextStyle?)>[
      ('displayLarge — Quest Title', tt.displayLarge),
      ('displayMedium — Screen Header', tt.displayMedium),
      ('headlineLarge — Section Title', tt.headlineLarge),
      ('headlineMedium — Card Title', tt.headlineMedium),
      ('bodyLarge — Primary Body', tt.bodyLarge),
      ('bodyMedium — Secondary Body', tt.bodyMedium),
      ('bodySmall — Caption', tt.bodySmall),
      ('labelLarge — Button Label', tt.labelLarge),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: styles
          .map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                s.$1,
                style: s.$2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
    );
  }
}

// ── Buttons ──────────────────────────────────────────────────────────────────

class _ButtonShowcase extends StatelessWidget {
  const _ButtonShowcase();

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          BrainForgeButton(
            label: 'Start Quest',
            icon: Icons.rocket_launch_rounded,
            onPressed: () {},
          ),
          BrainForgeButton(
            label: 'Outlined',
            icon: Icons.star_rounded,
            variant: BrainForgeButtonVariant.outlined,
            onPressed: () {},
          ),
          BrainForgeButton(
            label: 'Ghost',
            variant: BrainForgeButtonVariant.ghost,
            onPressed: () {},
          ),
          BrainForgeButton(
            label: 'ScienceSpark',
            icon: Icons.science_rounded,
            color: AppColors.scienceSpark,
            onPressed: () {},
          ),
          const BrainForgeButton(
            label: 'Loading…',
            isLoading: true,
            onPressed: null,
          ),
          const BrainForgeButton(
            label: 'Disabled',
            onPressed: null,
          ),
        ],
      );
}

// ── Cards ────────────────────────────────────────────────────────────────────

class _CardShowcase extends StatelessWidget {
  const _CardShowcase();

  @override
  Widget build(BuildContext context) => Column(
        children: [
          BrainForgeCard(
            accentColor: AppColors.primary,
            onTap: () {},
            child: const BrainForgeIconLabel(
              icon: Icons.menu_book_rounded,
              label: 'Math Quest — Multiplication',
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const BrainForgeCard(
            accentColor: AppColors.scienceSpark,
            child: BrainForgeIconLabel(
              icon: Icons.science_rounded,
              label: 'Daily Mystery: Why is the sky blue?',
              color: AppColors.scienceSpark,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const BrainForgeCard(
            accentColor: AppColors.warning,
            child: BrainForgeIconLabel(
              icon: Icons.emoji_events_rounded,
              label: 'Achievement Unlocked!',
              color: AppColors.warning,
            ),
          ),
        ],
      );
}

// ── Progress bars ────────────────────────────────────────────────────────────

class _ProgressShowcase extends StatelessWidget {
  const _ProgressShowcase();

  @override
  Widget build(BuildContext context) => const Column(
        children: [
          BrainForgeProgressBar(
            value: 0.72,
            label: 'Daily XP',
            icon: Icons.bolt_rounded,
            color: AppColors.xpGold,
          ),
          SizedBox(height: AppSpacing.md),
          BrainForgeProgressBar(
            value: 0.4,
            label: 'Element Collection',
            icon: Icons.science_rounded,
            color: AppColors.scienceSpark,
          ),
          SizedBox(height: AppSpacing.md),
          BrainForgeProgressBar(
            value: 1,
            label: 'Quest Complete!',
            icon: Icons.check_circle_rounded,
            color: AppColors.success,
          ),
          SizedBox(height: AppSpacing.md),
          BrainForgeProgressBar(
            value: 0.1,
            label: 'Getting started…',
            showPercentage: false,
          ),
        ],
      );
}

// ── Icon labels ──────────────────────────────────────────────────────────────

class _IconLabelShowcase extends StatelessWidget {
  const _IconLabelShowcase();

  @override
  Widget build(BuildContext context) => const Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.lg,
        children: [
          BrainForgeIconLabel(
            icon: Icons.bolt_rounded,
            label: '320 XP',
            color: AppColors.xpGold,
          ),
          BrainForgeIconLabel(
            icon: Icons.timer_rounded,
            label: '15 min',
            color: AppColors.primary,
          ),
          BrainForgeIconLabel(
            icon: Icons.science_rounded,
            label: 'Chemistry',
            color: AppColors.scienceSpark,
          ),
          BrainForgeIconLabel(
            icon: Icons.star_rounded,
            label: 'Level 5',
            color: AppColors.secondary,
            axis: Axis.vertical,
          ),
          BrainForgeIconLabel(
            icon: Icons.emoji_events_rounded,
            label: 'Champion',
            color: AppColors.xpGold,
            axis: Axis.vertical,
          ),
        ],
      );
}
