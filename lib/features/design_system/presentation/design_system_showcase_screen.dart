import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/dirassty_theme.dart';
import '../../../core/theme/subject_colors.dart';

/// A living style guide: every design token rendered in one place. This is
/// the fastest way to catch a token that looks wrong before it ends up
/// scattered across real screens, and it's this app's placeholder home
/// route until the first real feature (auth) lands.
///
/// Kept as a [ConsumerWidget] — not [StatelessWidget] — from day one, so
/// wiring in the first provider later is a one-line change, not a rewrite.
class DesignSystemShowcaseScreen extends ConsumerWidget {
  const DesignSystemShowcaseScreen({super.key});

  static const String path = '/design-system';
  static const String name = 'designSystem';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dirassty — Design System')),
      body: ListView(
        padding: const EdgeInsets.all(DirasstySpace.lg),
        children: const [
          _Section(title: 'Colors', child: _ColorSwatches()),
          SizedBox(height: DirasstySpace.xl),
          _Section(title: 'Typography', child: _TypographyScale()),
          SizedBox(height: DirasstySpace.xl),
          _Section(title: 'Buttons', child: _ButtonsPreview()),
          SizedBox(height: DirasstySpace.xl),
          _Section(title: 'Subjects', child: _SubjectGrid()),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DirasstySpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: DirasstySpace.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _ColorSwatches extends StatelessWidget {
  const _ColorSwatches();

  static const Map<String, Color> _swatches = {
    'Primary': DirasstyColors.teal,
    'Primary dark': DirasstyColors.tealDark,
    'Secondary': DirasstyColors.ink,
    'Warning': DirasstyColors.goldStroke,
    'Danger': DirasstyColors.error,
    'Success': DirasstyColors.teal,
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: DirasstySpace.md,
      runSpacing: DirasstySpace.md,
      children: [
        for (final entry in _swatches.entries)
          Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: entry.value,
                  borderRadius: DirasstyRadius.smallR,
                ),
              ),
              const SizedBox(height: DirasstySpace.xs),
              Text(entry.key, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
      ],
    );
  }
}

class _TypographyScale extends StatelessWidget {
  const _TypographyScale();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('H1 · 32', style: TextStyle(fontSize: 32)),
        const Text('XL · 20', style: TextStyle(fontSize: 20)),
        const Text('MD · 16', style: TextStyle(fontSize: 16)),
        const Text('Base · 14', style: TextStyle(fontSize: 14)),
        const Text(
          'Muted · 12',
          style: TextStyle(
            fontSize: 12,
            color: DirasstyColors.textMuted,
          ),
        ),
        const SizedBox(height: DirasstySpace.sm),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            'الرياضيات — Cairo font, right-to-left',
            style: DirasstyType.arabicFont(
              const TextStyle(fontSize: 18),
            ),
          ),
        ),
      ],
    );
  }
}

class _ButtonsPreview extends StatelessWidget {
  const _ButtonsPreview();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: DirasstySpace.md,
      runSpacing: DirasstySpace.md,
      children: [
        ElevatedButton(onPressed: () {}, child: const Text('Primary')),
        OutlinedButton(onPressed: () {}, child: const Text('Secondary')),
        TextButton(onPressed: () {}, child: const Text('Text')),
        const ElevatedButton(onPressed: null, child: Text('Disabled')),
      ],
    );
  }
}

class _SubjectGrid extends StatelessWidget {
  const _SubjectGrid();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: DirasstySpace.sm,
      runSpacing: DirasstySpace.sm,
      children: [
        for (final entry in kSubjectMeta.entries)
          Chip(
            avatar: CircleAvatar(
              backgroundColor: entry.value.color,
              child:
                  Text(entry.value.icon, style: const TextStyle(fontSize: 12)),
            ),
            label: Directionality(
              textDirection:
                  entry.value.isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: Text(
                entry.value.isRtl ? entry.value.labelAr : entry.value.labelFr,
                style: entry.value.isRtl ? DirasstyType.arabicFont(null) : null,
              ),
            ),
          ),
      ],
    );
  }
}
