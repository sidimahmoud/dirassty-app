import 'package:flutter/foundation.dart';

import '../i18n/app_lang.dart';

/// Ported from `Subject` in packages/shared/src/types — a subject offered
/// for a given grade (e.g. "math" for grade 6). [mastery] is populated
/// separately (see ProgressRepository.getSubjectMastery), not by this
/// model's own JSON parsing — it's `null` until a caller attaches it.
@immutable
class Subject {
  const Subject({
    required this.id,
    required this.country,
    required this.grade,
    required this.key,
    required this.label,
    required this.lang,
    required this.icon,
    required this.isActive,
    this.mastery,
    this.totalLessons,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as String,
      country: json['country'] as String,
      grade: json['grade'] as int,
      key: json['key'] as String,
      label: json['label'] as String,
      lang: AppLang.fromDb(json['lang'] as String),
      icon: json['icon'] as String,
      isActive: json['is_active'] as bool,
    );
  }

  final String id;
  final String country;
  final int grade;
  final String key;
  final String label;
  final AppLang lang;
  final String icon;
  final bool isActive;
  final double? mastery;

  /// Lesson count for the grade — attached with [mastery] (it comes from
  /// the same SubjectMastery fetch), null until then.
  final int? totalLessons;

  Subject withMastery(double value, {int? totalLessons}) => Subject(
        id: id,
        country: country,
        grade: grade,
        key: key,
        label: label,
        lang: lang,
        icon: icon,
        isActive: isActive,
        mastery: value,
        totalLessons: totalLessons ?? this.totalLessons,
      );
}
