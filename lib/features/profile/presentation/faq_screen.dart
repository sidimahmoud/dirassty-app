import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_lang.dart';
import '../../../core/i18n/app_language_provider.dart';
import '../../../core/theme/dirassty_theme.dart';
import '../../../l10n/app_localizations.dart';

class _FaqEntry {
  const _FaqEntry({
    required this.questionFr,
    required this.answerFr,
    required this.questionAr,
    required this.answerAr,
  });

  final String questionFr;
  final String answerFr;
  final String questionAr;
  final String answerAr;
}

/// Content grounded in what the app actually does today — the XP/streak
/// numbers, the QCM-vs-open-practice distinction, and the language/
/// account settings paths all match the real features, not aspirational
/// ones the mobile app doesn't have yet (e.g. no mention of the homework
/// helper or video lessons, which aren't built here).
const List<_FaqEntry> _kFaqEntries = [
  _FaqEntry(
    questionFr: "Comment gagner des points d'XP ?",
    answerFr:
        'Tu gagnes de l\'XP à chaque bonne réponse dans un exercice QCM : '
        '+5 XP (facile), +10 XP (moyen), +20 XP (difficile). Si tu réussis '
        "les 5 questions d'une session, tu gagnes un bonus de +25 XP !",
    questionAr: 'كيف أكسب نقاط الخبرة (XP)؟',
    answerAr:
        'تكسب نقاط الخبرة عند كل إجابة صحيحة في تمارين الاختيار من متعدد: '
        '+5 (سهل)، +10 (متوسط)، +20 (صعب). وإذا أجبت بشكل صحيح على '
        'الأسئلة الخمسة في الجلسة، تحصل على مكافأة إضافية +25!',
  ),
  _FaqEntry(
    questionFr: 'Comment fonctionne ma série (streak) ?',
    answerFr:
        'Ta série augmente de 1 chaque jour où tu es actif. Si tu manques '
        'une journée complète, elle repart à 1.',
    questionAr: 'كيف تعمل سلسلة الأيام المتتالية (streak)؟',
    answerAr: 'تزداد سلسلتك بمقدار 1 كل يوم تكون فيه نشطًا. إذا فوّتت يومًا '
        'كاملاً، تعود السلسلة إلى 1.',
  ),
  _FaqEntry(
    questionFr: 'Quelle est la différence entre QCM et Pratique guidée ?',
    answerFr: 'Les QCM sont des questions à choix multiples corrigées '
        'automatiquement. La pratique guidée te fait écrire une vraie '
        'réponse, avec un indice et une correction détaillée par Rafiq '
        '(notre assistant IA).',
    questionAr: 'ما الفرق بين الاختيار من متعدد والتمرين الموجّه؟',
    answerAr: 'الاختيار من متعدد أسئلة تُصحَّح تلقائيًا. التمرين الموجّه يجعلك '
        'تكتب إجابة حقيقية، مع تلميح وتصحيح مفصّل من رفيق (مساعدنا بالذكاء الاصطناعي).',
  ),
  _FaqEntry(
    questionFr: 'Je ne vois pas de leçon pour un chapitre, pourquoi ?',
    answerFr: 'Certaines leçons sont encore en préparation. Un message '
        '« bientôt disponible » s\'affiche — reviens un peu plus tard.',
    questionAr: 'لا أرى درسًا لأحد الفصول، لماذا؟',
    answerAr: 'بعض الدروس لا تزال قيد التحضير. ستظهر رسالة "قريبًا" — '
        'عاود المحاولة بعد قليل.',
  ),
  _FaqEntry(
    questionFr: "Comment changer la langue de l'application ?",
    answerFr:
        'Va dans Profil, puis choisis FR ou عربي dans la section Préférences.',
    questionAr: 'كيف أغيّر لغة التطبيق؟',
    answerAr: 'اذهب إلى الملف الشخصي، ثم اختر FR أو عربي في قسم التفضيلات.',
  ),
  _FaqEntry(
    questionFr: 'Comment supprimer mon compte ?',
    answerFr: 'Va dans Profil > Supprimer mon compte. Cette action est '
        'définitive et supprime toutes tes données (progression, XP, badges).',
    questionAr: 'كيف أحذف حسابي؟',
    answerAr: 'اذهب إلى الملف الشخصي > حذف حسابي. هذا الإجراء نهائي ويحذف جميع '
        'بياناتك (التقدم، النقاط، الشارات).',
  ),
];

class FaqScreen extends ConsumerWidget {
  const FaqScreen({super.key});

  static const String path = '/profile/faq';
  static const String name = 'faq';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isArabic = ref.watch(appLanguageProvider) == AppLang.ar;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).faq),
      ),
      body: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: ListView.separated(
          padding: const EdgeInsets.all(DirasstySpace.lg),
          itemCount: _kFaqEntries.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: DirasstySpace.sm),
          itemBuilder: (context, index) {
            final _FaqEntry entry = _kFaqEntries[index];
            return Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                shape: const RoundedRectangleBorder(side: BorderSide.none),
                title: Text(
                  isArabic ? entry.questionAr : entry.questionFr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      DirasstySpace.lg,
                      0,
                      DirasstySpace.lg,
                      DirasstySpace.lg,
                    ),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        isArabic ? entry.answerAr : entry.answerFr,
                        style: const TextStyle(color: DirasstyColors.textMuted),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
