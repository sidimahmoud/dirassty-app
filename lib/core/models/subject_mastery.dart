import 'package:flutter/foundation.dart';

/// Ported from `SubjectMastery` in packages/shared/src/types — see
/// ProgressRepository.getSubjectMastery for how this is computed
/// (diluted across every lesson in the subject, not just attempted ones).
@immutable
class SubjectMastery {
  const SubjectMastery({
    required this.subject,
    required this.mastery,
    required this.lessonsCompleted,
    required this.totalLessons,
  });

  static const SubjectMastery empty = SubjectMastery(
    subject: '',
    mastery: 0,
    lessonsCompleted: 0,
    totalLessons: 0,
  );

  final String subject;

  /// 0–1.
  final double mastery;
  final int lessonsCompleted;
  final int totalLessons;
}
