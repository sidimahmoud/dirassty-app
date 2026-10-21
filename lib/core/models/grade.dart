import 'package:flutter/foundation.dart';

/// Grade labels ported from `GRADE_FALLBACK` in
/// `packages/config/curriculum.ts` — just the display label, which is
/// all the Profile screen needs (full cycle/exam metadata stays
/// web-only until something in the mobile app actually needs it).
const Map<int, String> kGradeLabels = {
  1: '1ère année',
  2: '2ème année',
  3: '3ème année',
  4: '4ème année',
  5: '5ème année',
  6: '6ème année',
  7: '1ère Collège',
  8: '2ème Collège',
  9: '3ème Collège',
  10: '4ème Collège',
  11: 'Seconde',
  12: 'Première',
  13: 'Terminale',
};

String gradeLabel(int grade) => kGradeLabels[grade] ?? 'Niveau $grade';

/// Which grades have a national exam at the end of the year — ported
/// from `GRADE_FALLBACK`'s `exam` field. Used by the parent dashboard's
/// exam countdown (see `daysUntilExam`), mirroring
/// `gradeExam`/`daysUntilExam` in packages/config/curriculum.ts.
const Map<int, String> kGradeExams = {6: 'Concours', 10: 'Brevet', 13: 'Bac'};

/// Approximate days until the next June 1st, or null if this grade has
/// no exam.
int? daysUntilExam(int grade) {
  if (!kGradeExams.containsKey(grade)) return null;
  final DateTime now = DateTime.now();
  DateTime examDate = DateTime(now.year, 6, 1);
  if (examDate.isBefore(now)) {
    examDate = DateTime(now.year + 1, 6, 1);
  }
  return examDate.difference(now).inDays;
}

/// The three school cycles, in order.
enum GradeCycle { primaire, college, lycee }

/// Which cycle a grade (1–13) belongs to: P1–P6, C1–C4, L1–L3.
GradeCycle gradeCycle(int grade) => grade <= 6
    ? GradeCycle.primaire
    : grade <= 10
        ? GradeCycle.college
        : GradeCycle.lycee;

/// Grades in a cycle, in order.
List<int> gradesInCycle(GradeCycle cycle) => switch (cycle) {
      GradeCycle.primaire => [1, 2, 3, 4, 5, 6],
      GradeCycle.college => [7, 8, 9, 10],
      GradeCycle.lycee => [11, 12, 13],
    };

/// Grades open for new registrations: the admin's active grades
/// (`grades.is_active`). [open] null = not known yet (loading / offline)
/// → everything is offered and the server's check still applies.

/// Grades that can be picked: open ([active], null = not loaded yet →
/// all) and at least [minGrade].
Set<int> selectableGrades(Set<int>? active, {int minGrade = 1}) =>
    active == null
        ? {for (int g = minGrade; g <= 13; g++) g}
        : active.where((g) => g >= minGrade).toSet();

/// One class as the admin saved it (`grades` table: Curriculum page) —
/// the name and code shown in the class pickers.
@immutable
class GradeOption {
  const GradeOption({
    required this.id,
    required this.label,
    required this.short,
    required this.cycle,
    this.exam,
  });

  factory GradeOption.fromJson(Map<String, dynamic> json) => GradeOption(
        id: json['id'] as int,
        label: json['label'] as String,
        short: json['short'] as String,
        cycle: GradeCycle.values.asNameMap()[json['cycle']] ??
            gradeCycle(json['id'] as int),
        exam: json['exam'] as String?,
      );

  /// Offline fallback when the list can't be loaded: the static codes.
  factory GradeOption.fallback(int id) => GradeOption(
        id: id,
        label: gradeCode(id),
        short: gradeCode(id),
        cycle: gradeCycle(id),
        exam: kGradeExams[id],
      );

  final int id;
  final String label;
  final String short;
  final GradeCycle cycle;

  /// 'Concours' | 'Brevet' | 'Bac' | null.
  final String? exam;
}

/// First grade a student may register by themselves (C2); below it a
/// parent creates the account. Same rule in supabase/functions/register-direct.
const int kMinSelfSignupGrade = 8;

/// Cycles with at least one open grade.
List<GradeCycle> openCycles(Set<int>? open) => open == null
    ? GradeCycle.values
    : GradeCycle.values
        .where((c) => gradesInCycle(c).any(open.contains))
        .toList();

/// The open grades of [cycle], in order.
List<int> openGradesInCycle(GradeCycle cycle, Set<int>? open) => open == null
    ? gradesInCycle(cycle)
    : gradesInCycle(cycle).where(open.contains).toList();

/// [preferred] when it's open, otherwise the closest open grade; null when
/// no grade is open at all.
int? openGradeOrNearest(int preferred, Set<int>? open) {
  if (open == null || open.contains(preferred)) return preferred;
  if (open.isEmpty) return null;
  return (open.toList()
        ..sort(
          (a, b) => (a - preferred).abs().compareTo((b - preferred).abs()),
        ))
      .first;
}

/// Short code used on chips and cards — "P5", "C4", "L3".
String gradeCode(int grade) => switch (gradeCycle(grade)) {
      GradeCycle.primaire => 'P$grade',
      GradeCycle.college => 'C${grade - 6}',
      GradeCycle.lycee => 'L${grade - 10}',
    };
