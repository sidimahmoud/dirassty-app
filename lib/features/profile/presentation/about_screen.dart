import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/actions/app_promotion_actions.dart';
import '../../../core/i18n/app_language_provider.dart';
import '../../../core/theme/dirassty_theme.dart';
import '../../../l10n/app_localizations.dart';

class _Section {
  const _Section({
    required this.titleFr,
    required this.titleAr,
    required this.bodyFr,
    required this.bodyAr,
  });

  final String titleFr;
  final String titleAr;

  /// One bullet per list entry — kept as a list rather than one long
  /// paragraph so it reads the same way on both a phone-width screen and
  /// in Arabic (RTL bullets read naturally either way).
  final List<String> bodyFr;
  final List<String> bodyAr;
}

/// Content grounded in what the app actually does and how it's actually
/// run today — same discipline as FaqScreen's own doc comment: no
/// aspirational claims, no invented legal/company details we don't have.
/// "Notre responsabilité" is the section the user explicitly asked for —
/// what the app commits to, and just as importantly, what it doesn't
/// (a complement to school, not a replacement; AI content can be wrong;
/// no guaranteed grades).
const List<_Section> _kSections = [
  _Section(
    titleFr: 'Ce que propose Dirassty',
    titleAr: 'ما الذي يقدّمه تطبيق دراستي',
    bodyFr: [
      'Des leçons et exercices alignés sur le programme scolaire '
          'mauritanien, en français et en arabe.',
      'Des exercices à choix multiples corrigés automatiquement, et une '
          'pratique guidée avec correction détaillée par Rafiq, notre assistant IA.',
      "Rafiq, l'assistant de devoirs (IA), pour s'entraîner ou débloquer "
          'un exercice difficile.',
      'Un suivi de progression : bonnes réponses, exercices faits, jours '
          "actifs, temps passé et série de jours consécutifs, à la "
          'semaine et au mois.',
      'Un espace parent pour suivre chaque enfant et gérer les '
          'abonnements.',
    ],
    bodyAr: [
      'دروس وتمارين متوافقة مع البرنامج الدراسي الموريتاني، باللغتين '
          'الفرنسية والعربية.',
      'تمارين اختيار من متعدد تُصحَّح تلقائيًا، وتمرين موجّه بتصحيح '
          'مفصّل من رفيق، مساعدنا بالذكاء الاصطناعي.',
      'رفيق، مساعد الواجبات المنزلية (بالذكاء الاصطناعي)، للتدرّب أو '
          'تجاوز صعوبة في تمرين ما.',
      'متابعة للتقدّم: الإجابات الصحيحة، التمارين المنجزة، الأيام '
          'النشطة، الوقت المستغرق، وسلسلة الأيام المتتالية — أسبوعيًا '
          'وشهريًا.',
      'مساحة لولي الأمر لمتابعة كل طفل وإدارة الاشتراكات.',
    ],
  ),
  _Section(
    titleFr: 'Notre responsabilité',
    titleAr: 'مسؤوليتنا',
    bodyFr: [
      "Dirassty est un complément à l'école, pas un remplacement : "
          "l'enseignement en classe reste la référence.",
      "Les corrections et explications de Rafiq, notre assistant IA "
          '(aide aux devoirs, pratique guidée) sont une aide à '
          "l'apprentissage — elles peuvent contenir une erreur ; signale-la "
          'avec le bouton « Signaler », et en cas de doute avant un examen, '
          'vérifie avec un enseignant.',
      "Nous ne garantissons pas de note ou de résultat précis : les "
          "progrès dépendent du travail régulier de l'élève.",
      "Les données personnelles (progression, coordonnées) ne sont "
          'utilisées que pour faire fonctionner l\'application et ne '
          'sont jamais vendues.',
      "Aucun paiement par carte n'est jamais demandé dans l'application "
          "— les abonnements sont vérifiés manuellement (Bankily ou "
          'contact direct).',
      'Un souci, une erreur repérée, une question sur un paiement ? '
          "Contacte-nous directement, on répond.",
    ],
    bodyAr: [
      'تطبيق دراستي مكمّل للمدرسة وليس بديلاً عنها — يبقى التعليم '
          'داخل الفصل هو المرجع.',
      'تصحيحات وشروحات رفيق، مساعدنا بالذكاء الاصطناعي (مساعد '
          'الواجبات، التمرين الموجّه) أداة مساعدة للتعلّم — قد تحتوي على '
          'خطأ؛ أبلغ عنه بزر «إبلاغ»، وفي حال الشك قبل امتحان، تحقّق مع معلّمك.',
      'لا نضمن علامة أو نتيجة محددة: التقدّم يعتمد على انتظام عمل '
          'الطالب.',
      'البيانات الشخصية (التقدّم، معلومات التواصل) تُستخدم فقط لتشغيل '
          'التطبيق ولا تُباع أبدًا.',
      'لا يُطلب أي دفع ببطاقة داخل التطبيق أبدًا — يتم التحقق من '
          'الاشتراكات يدويًا (Bankily أو التواصل المباشر).',
      'واجهت مشكلة، لاحظت خطأً، أو لديك سؤال حول دفعة؟ تواصل معنا '
          'مباشرة، سنجيبك.',
    ],
  ),
];

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  static const String path = '/profile/about';
  static const String name = 'about';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isArabic = ref.watch(appLanguageProvider).isArabic;

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).about)),
      body: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: ListView(
          padding: const EdgeInsets.all(DirasstySpace.lg),
          children: [
            Center(
              child: Column(
                children: [
                  Semantics(
                    label: 'Dirassty',
                    image: true,
                    child: SvgPicture.asset('assets/logo/logo_stacked.svg',
                        height: 132),
                  ),
                  const SizedBox(height: DirasstySpace.md),
                  Text(
                    isArabic
                        ? 'التعلّم بالفرنسية والعربية، على مقاس البرنامج الموريتاني'
                        : "Apprendre en français et en arabe, sur mesure pour le "
                            'programme mauritanien',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: DirasstyColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DirasstySpace.xxl),
            for (final _Section section in _kSections) ...[
              Text(
                isArabic ? section.titleAr : section.titleFr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: DirasstySpace.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(DirasstySpace.lg),
                decoration: BoxDecoration(
                  color: DirasstyColors.surface,
                  borderRadius: DirasstyRadius.cardR,
                  border: Border.all(color: DirasstyColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final String line
                        in (isArabic ? section.bodyAr : section.bodyFr)) ...[
                      _BulletLine(text: line),
                      if (line !=
                          (isArabic ? section.bodyAr : section.bodyFr).last)
                        const SizedBox(height: DirasstySpace.sm),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: DirasstySpace.xl),
            ],
            TextButton.icon(
              onPressed: () => openPrivacyPolicy(context),
              icon: const Icon(Icons.privacy_tip_outlined),
              label: Text(AppLocalizations.of(context).privacyPolicy),
            ),
            const SizedBox(height: DirasstySpace.sm),
            OutlinedButton.icon(
              onPressed: () => contactSupport(context),
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text(
                isArabic
                    ? 'تواصل معنا عبر واتساب'
                    : 'Nous contacter sur WhatsApp',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('•  ', style: TextStyle(fontWeight: FontWeight.w700)),
        Expanded(
          child: Text(text, style: const TextStyle(height: 1.4)),
        ),
      ],
    );
  }
}
