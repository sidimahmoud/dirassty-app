import 'package:flutter/material.dart';

import 'dirassty_theme.dart';

/// The 9 subjects taught on Dirassty. An enum instead of a raw string key
/// so a typo'd subject id is a compile error, not a silent lookup miss.
///
/// Named `SubjectKey` — not `Subject` — because `core/models/subject.dart`
/// already defines a `Subject` class for the `subjects` table row; this
/// enum is purely the design-token side (color/icon/RTL/label), looked up
/// from that row's `key` field via [SubjectKey.fromDb].
enum SubjectKey {
  math,
  francais,
  arabe,
  sciences,
  islam,
  histoire,
  svt,
  physique,
  anglais;

  static SubjectKey fromDb(String key) => tryFromDb(key) ?? SubjectKey.math;

  /// Null for a subject the admin created beyond these 9 (e.g. "chimie").
  static SubjectKey? tryFromDb(String key) =>
      SubjectKey.values.where((k) => k.name == key).firstOrNull;
}

/// The name to show for subject [key]: the built-in French/Arabic label
/// for the 9 known subjects, otherwise the label stored on the subject
/// row ([dbLabel]) — never another subject's name. (Falling back to
/// [SubjectKey.math] here used to title e.g. "Chimie" as "Mathématiques".)
String subjectDisplayName(
  String key, {
  required bool isArabic,
  String? dbLabel,
}) {
  final SubjectKey? known = SubjectKey.tryFromDb(key);
  if (known == null) return dbLabel ?? key;
  final SubjectMeta meta = kSubjectMeta[known]!;
  return isArabic ? meta.labelAr : meta.labelFr;
}

/// Per-subject icon glyph, RTL flag, and bilingual label — ported 1:1
/// from `packages/config/subjects.ts` (that file still assigns each
/// subject its own one-off hex color; mobile deliberately no longer
/// mirrors that part — see [color]). [isRtl] is per-subject, not
/// per-locale: "arabe" and "islam" content is always right-to-left, even
/// inside an otherwise French-locale screen.
@immutable
class SubjectMeta {
  const SubjectMeta({
    required this.color,
    required this.icon,
    required this.isRtl,
    required this.labelFr,
    required this.labelAr,
  });

  final Color color;
  final String icon;
  final bool isRtl;
  final String labelFr;
  final String labelAr;
}

// Alternates the two structural brand colors (DirasstyColors.teal teal,
// DirasstyColors.ink deep ink) across the 9 subjects, in enum declaration
// order, so neighboring cards in the subject grid never share a color.
// Gold is deliberately not in the rotation: subject colors are also used
// as full backgrounds behind white text (subject screen app bar), and
// white on gold isn't readable.
const Map<SubjectKey, SubjectMeta> kSubjectMeta = {
  SubjectKey.math: SubjectMeta(
    color: DirasstyColors.teal,
    icon: '➕',
    isRtl: false,
    labelFr: 'Mathématiques',
    labelAr: 'الرياضيات',
  ),
  SubjectKey.francais: SubjectMeta(
    color: DirasstyColors.ink,
    icon: '🇫🇷',
    isRtl: false,
    labelFr: 'Français',
    labelAr: 'الفرنسية',
  ),
  SubjectKey.arabe: SubjectMeta(
    color: DirasstyColors.teal,
    icon: 'ع',
    isRtl: true,
    labelFr: 'Arabe',
    labelAr: 'اللغة العربية',
  ),
  SubjectKey.sciences: SubjectMeta(
    color: DirasstyColors.ink,
    icon: '🔬',
    isRtl: false,
    labelFr: 'Sciences',
    labelAr: 'العلوم الطبيعية',
  ),
  SubjectKey.islam: SubjectMeta(
    color: DirasstyColors.teal,
    icon: '☪',
    isRtl: true,
    labelFr: 'Éducation islamique',
    labelAr: 'التربية الإسلامية',
  ),
  SubjectKey.histoire: SubjectMeta(
    color: DirasstyColors.ink,
    icon: '🗺',
    isRtl: false,
    labelFr: 'Histoire-Géographie',
    labelAr: 'التاريخ والجغرافيا',
  ),
  SubjectKey.svt: SubjectMeta(
    color: DirasstyColors.teal,
    icon: '🧬',
    isRtl: false,
    labelFr: 'SVT',
    labelAr: 'علوم الحياة والأرض',
  ),
  SubjectKey.physique: SubjectMeta(
    color: DirasstyColors.ink,
    icon: '⚗️',
    isRtl: false,
    labelFr: 'Physique-Chimie',
    labelAr: 'الفيزياء والكيمياء',
  ),
  SubjectKey.anglais: SubjectMeta(
    color: DirasstyColors.teal,
    icon: '🇬🇧',
    isRtl: false,
    labelFr: 'Anglais',
    labelAr: 'اللغة الإنجليزية',
  ),
};
