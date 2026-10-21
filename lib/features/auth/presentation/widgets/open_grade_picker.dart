import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/grade.dart';
import '../../../../core/theme/dirassty_theme.dart';
import '../../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../courses/application/courses_providers.dart';
import 'auth_scaffold.dart';
import 'auth_segmented.dart';

/// Class picker shared by registration and Add child: the classes an admin
/// has opened (Curriculum page → `grades`), with the name and code the
/// admin saved ("2ème Collège · 2AS"), grouped by cycle tabs and laid out
/// as two-column cards (exam year marked). Cycles without an open class
/// are hidden. [grade] must be the already-resolved open class
/// ([openGradeOrNearest]); when none is open, a notice replaces the picker.
/// While the list loads, placeholders; offline, the static codes.
class OpenGradePicker extends ConsumerWidget {
  const OpenGradePicker({
    required this.label,
    required this.grade,
    required this.onChanged,
    this.lastOfCycleByDefault = false,
    this.minGrade = 1,
    this.note,
    super.key,
  });

  final String label;

  /// Null when no class is open.
  final int? grade;
  final ValueChanged<int> onChanged;

  /// On a cycle switch, select its last open year (the exam year — the
  /// likeliest self sign-up) instead of the first.
  final bool lastOfCycleByDefault;

  /// Classes below this aren't offered (self sign-up: [kMinSelfSignupGrade]).
  final int minGrade;

  /// Optional line under the cards.
  final String? note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final AsyncValue<List<GradeOption>> loaded = ref.watch(openGradesProvider);

    final Widget heading = AuthFieldLabel(label: label);
    if (loaded.isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          heading,
          const SizedBox(height: 10),
          const _CardsSkeleton(),
        ],
      );
    }

    final List<GradeOption> options = (loaded.valueOrNull ??
            [for (int g = 1; g <= 13; g++) GradeOption.fallback(g)])
        .where((g) => g.id >= minGrade)
        .toList();
    final int? selectedId = grade;
    final GradeOption? selected =
        options.where((g) => g.id == selectedId).firstOrNull;

    if (selected == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          heading,
          const SizedBox(height: 10),
          Text(
            l10n.noGradesOpen,
            style: type.label.copyWith(color: DirasstyColors.error),
          ),
        ],
      );
    }

    final List<GradeCycle> cycles = [
      for (final GradeCycle c in GradeCycle.values)
        if (options.any((g) => g.cycle == c)) c,
    ];
    final List<GradeOption> inCycle =
        options.where((g) => g.cycle == selected.cycle).toList();
    String cycleLabel(GradeCycle c) => switch (c) {
          GradeCycle.primaire => l10n.cyclePrimary,
          GradeCycle.college => l10n.cycleMiddle,
          GradeCycle.lycee => l10n.cycleHigh,
        };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        heading,
        const SizedBox(height: 10),
        if (cycles.length > 1) ...[
          AuthSegmented(
            pill: true,
            options: [for (final GradeCycle c in cycles) cycleLabel(c)],
            selected: cycles.indexOf(selected.cycle),
            onChanged: (i) {
              if (cycles[i] == selected.cycle) return;
              final List<GradeOption> next =
                  options.where((g) => g.cycle == cycles[i]).toList();
              onChanged(lastOfCycleByDefault ? next.last.id : next.first.id);
            },
          ),
          const SizedBox(height: DirasstySpace.md),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            const double gap = DirasstySpace.sm;
            final double width = (constraints.maxWidth - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final GradeOption g in inCycle)
                  SizedBox(
                    width: width,
                    child: _GradeCard(
                      option: g,
                      selected: g.id == selected.id,
                      onTap: () => onChanged(g.id),
                    ),
                  ),
              ],
            );
          },
        ),
        if (note != null) ...[
          const SizedBox(height: DirasstySpace.sm),
          Text(note!, style: type.label.copyWith(fontWeight: FontWeight.w400)),
        ],
      ],
    );
  }
}

class _GradeCard extends StatelessWidget {
  const _GradeCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final GradeOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final String? exam = switch (option.exam) {
      'Concours' => l10n.examConcours,
      'Brevet' => l10n.examBrevet,
      'Bac' => l10n.examBac,
      _ => null,
    };
    return Semantics(
      button: true,
      selected: selected,
      label: option.label,
      child: AnimatedContainer(
        duration: context.reduceMotion ? Duration.zero : DirasstyMotion.fast,
        decoration: BoxDecoration(
          color: selected ? DirasstyColors.tealTint : DirasstyColors.surface,
          borderRadius: DirasstyRadius.cardR,
          border: Border.all(
            color: selected ? DirasstyColors.teal : DirasstyColors.line,
            width: selected ? 2 : 1.5,
          ),
          boxShadow: selected ? DirasstyShadow.level1 : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: DirasstyRadius.cardR,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                DirasstySpace.md,
                DirasstySpace.md,
                DirasstySpace.sm,
                DirasstySpace.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: DirasstySpace.sm,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? DirasstyColors.teal
                              : DirasstyColors.track,
                          borderRadius: DirasstyRadius.pillR,
                        ),
                        child: Text(
                          option.short,
                          textDirection: TextDirection.ltr,
                          style: type.label.copyWith(
                            color: selected ? Colors.white : DirasstyColors.ink,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      const Spacer(),
                      AnimatedOpacity(
                        opacity: selected ? 1 : 0,
                        duration: context.reduceMotion
                            ? Duration.zero
                            : DirasstyMotion.fast,
                        child: const Icon(
                          Icons.check_circle_rounded,
                          size: 20,
                          color: DirasstyColors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DirasstySpace.sm),
                  Text(
                    option.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: type.subheading.copyWith(
                      fontSize: 15,
                      color: selected
                          ? DirasstyColors.tealDark
                          : DirasstyColors.ink,
                    ),
                  ),
                  if (exam != null) ...[
                    const SizedBox(height: DirasstySpace.xs),
                    Row(
                      children: [
                        const Icon(
                          Icons.workspace_premium_rounded,
                          size: 14,
                          color: DirasstyColors.goldStroke,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            exam,
                            overflow: TextOverflow.ellipsis,
                            style: type.label.copyWith(
                              color: DirasstyColors.goldStroke,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardsSkeleton extends StatelessWidget {
  const _CardsSkeleton();

  @override
  Widget build(BuildContext context) => Row(
        children: [
          for (int i = 0; i < 2; i++) ...[
            if (i > 0) const SizedBox(width: DirasstySpace.sm),
            Expanded(
              child: Container(
                height: 84,
                decoration: const BoxDecoration(
                  color: DirasstyColors.skeleton,
                  borderRadius: DirasstyRadius.cardR,
                ),
              ),
            ),
          ],
        ],
      );
}
