import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/parent.dart';
import '../../../../core/models/student.dart';
import '../../../../core/models/student_stats.dart';
import '../../../../core/models/subscription.dart';
import '../../../../core/text/study_time.dart';
import '../../../../core/theme/dirassty_theme.dart';
import '../../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../progress/application/progress_providers.dart';
import '../../../subscription/application/subscription_providers.dart';
import '../../application/parent_providers.dart';
import '../add_child_screen.dart';
import '../child_progress_screen.dart';
import 'child_card.dart';

/// Parent Home tab: greeting, the family's study time this week (ink
/// card), one [ChildCard] per child, then the dashed "Ajouter un enfant".
///
/// Deviation from ParentHome.dc.html: no notifications bell — there's no
/// notifications inbox yet (TODO(api), same as the student home).
///
/// design_handoff ParentHome.dc.html · DESIGN_SPEC §4 "Parent space".
class ParentHomeTab extends ConsumerWidget {
  const ParentHomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final Parent? parent = ref.watch(currentParentProvider).valueOrNull;
    final AsyncValue<List<Student>> students =
        ref.watch(studentsByParentProvider);
    final Map<String, Subscription> subs =
        ref.watch(latestSubscriptionsByStudentProvider).valueOrNull ?? const {};

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(subscriptionsByParentProvider);
          final List<Student> list =
              await ref.refresh(studentsByParentProvider.future);
          for (final Student s in list) {
            ref.invalidate(studentStatsProvider(s.id));
          }
        },
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(DirasstySpace.screen,
              DirasstySpace.lg, DirasstySpace.screen, DirasstySpace.xxl),
          children: [
            Text(l10n.parentSpace,
                style: type.label.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(
              parent == null ? l10n.parentSpace : l10n.hello(parent.name),
              style: type.title,
            ),
            const SizedBox(height: DirasstySpace.xl),
            students.when(
              loading: () => const _HomeSkeleton(),
              error: (_, __) => ErrorState(
                title: l10n.childrenLoadError,
                onRetry: () => ref.invalidate(studentsByParentProvider),
              ),
              data: (list) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (list.isNotEmpty) ...[
                    _WeekSummary(students: list),
                    const SizedBox(height: DirasstySpace.xl),
                    Text(l10n.myChildren, style: type.subheading),
                    const SizedBox(height: DirasstySpace.md),
                    for (final Student student in list) ...[
                      ChildCard(
                        student: student,
                        subscription: subs[student.id],
                        onTap: () => context.pushNamed(
                          ChildProgressScreen.name,
                          pathParameters: {'studentId': student.id},
                        ),
                      ),
                      const SizedBox(height: DirasstySpace.md),
                    ],
                  ] else ...[
                    EmptyState(
                      icon: Icons.family_restroom_rounded,
                      title: l10n.noChildrenTitle,
                      message: l10n.noChildrenBody,
                    ),
                    const SizedBox(height: DirasstySpace.lg),
                  ],
                  _AddChildButton(
                      onTap: () => context.push(AddChildScreen.path)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Cette semaine, vos enfants ont étudié **5 h 10** au total." — sums
/// each child's 7-day study time (the same stats the child cards read,
/// so no extra query).
class _WeekSummary extends ConsumerWidget {
  const _WeekSummary({required this.students});

  final List<Student> students;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    int total = 0;
    bool loading = false;
    for (final Student s in students) {
      final StudentStats? stats =
          ref.watch(studentStatsProvider(s.id)).valueOrNull;
      if (stats == null) {
        loading = true;
      } else {
        total += stats.week.minutesOnApp;
      }
    }
    if (loading) return const Skeleton(height: 72, radius: DirasstyRadius.card);

    final TextStyle base =
        type.bodySmall.copyWith(color: const Color(0xFFE6ECEA), fontSize: 14);
    final Widget text;
    if (total == 0) {
      text = Text(l10n.parentWeekNone, style: base);
    } else {
      final String time = formatStudyTime(l10n, total);
      final String sentence = l10n.parentWeekTotal(time);
      final int at = sentence.indexOf(time);
      text = Text.rich(
        TextSpan(
          style: base,
          children: [
            TextSpan(text: sentence.substring(0, at)),
            TextSpan(
              text: time,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
            TextSpan(text: sentence.substring(at + time.length)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsetsDirectional.all(DirasstySpace.lg),
      decoration: const BoxDecoration(
          color: DirasstyColors.ink, borderRadius: DirasstyRadius.cardR),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, color: DirasstyColors.gold),
          const SizedBox(width: DirasstySpace.md),
          Expanded(child: text),
        ],
      ),
    );
  }
}

class _AddChildButton extends StatelessWidget {
  const _AddChildButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: DirasstyRadius.cardR,
          onTap: onTap,
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_rounded, color: DirasstyColors.ink),
                const SizedBox(width: DirasstySpace.sm),
                Text(l10n.addChild,
                    style: type.subheading.copyWith(fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The 1.5 px dashed `#B9B3A5` outline of the "Ajouter un enfant" tile.
class _DashedBorderPainter extends CustomPainter {
  static const Color _color = Color(0xFFB9B3A5);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = _color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final Path outline = Path()
      ..addRRect(DirasstyRadius.cardR.toRRect(Offset.zero & size).deflate(0.75));
    for (final metric in outline.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => false;
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Skeleton(height: 72, radius: DirasstyRadius.card),
        SizedBox(height: DirasstySpace.xl),
        Skeleton(height: 124, radius: DirasstyRadius.card),
        SizedBox(height: DirasstySpace.md),
        Skeleton(height: 124, radius: DirasstyRadius.card),
      ],
    );
  }
}
