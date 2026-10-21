import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/subject.dart';
import '../../../core/theme/dirassty_theme.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/presentation/student_home_screen.dart';
import '../../home/presentation/widgets/student_tab_bar.dart';
import '../application/courses_providers.dart';

/// Subjects tab (tab 2): every subject for the student's grade as the
/// same [SubjectGrid] cards the home screen previews (mastery ring,
/// lesson count, teal/ink alternation). Tapping one opens its chapters.
class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key});

  static const String path = '/courses';
  static const String name = 'courses';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<Subject>> subjects =
        ref.watch(subjectsWithMasteryProvider);

    return Scaffold(
      backgroundColor: DirasstyColors.background,
      bottomNavigationBar: const StudentTabBar(currentIndex: 1),
      appBar: AppBar(
        title:
            Text(l10n.mySubjectsTitle, style: context.dirasstyType.titleSmall),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(subjectsWithMasteryProvider.future),
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(
            DirasstySpace.screen,
            DirasstySpace.sm,
            DirasstySpace.screen,
            DirasstySpace.xl,
          ),
          children: [
            subjects.when(
              loading: () => Column(
                children: [
                  for (int i = 0; i < 4; i++) ...[
                    if (i > 0) const SizedBox(height: DirasstySpace.md),
                    const Skeleton(height: 80, radius: DirasstyRadius.card),
                  ],
                ],
              ),
              error: (_, __) => ErrorState(
                onRetry: () => ref.invalidate(subjectsWithMasteryProvider),
              ),
              data: (list) => list.isEmpty
                  ? EmptyState(
                      icon: Icons.menu_book_rounded,
                      title: l10n.noSubjects,
                    )
                  : SubjectGrid(subjects: list),
            ),
          ],
        ),
      ),
    );
  }
}
