import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/dirassty_theme.dart';
import '../../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/lesson_providers.dart';
import '../../data/lesson_repository.dart';

/// Opens the lesson's PDF (migration 084) in the phone's browser / PDF
/// viewer, where the student can save or share it.
Future<void> openLessonPdf(
  BuildContext context,
  WidgetRef ref,
  LessonPdf pdf,
) async {
  final AppLocalizations l10n = AppLocalizations.of(context);
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  try {
    final String url =
        await ref.read(lessonRepositoryProvider).lessonPdfDownloadUrl(pdf);
    final bool opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) throw Exception('launch_failed');
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.lessonPdfError)));
  }
}

String _sizeLabel(int? bytes) {
  if (bytes == null) return '';
  if (bytes < 1024 * 1024) return ' · ${(bytes / 1024).ceil()} Ko';
  return ' · ${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
}

/// Top-bar PDF button of the lesson viewer — hidden when the lesson has
/// no PDF.
class LessonPdfIconButton extends ConsumerWidget {
  const LessonPdfIconButton({required this.lessonId, super.key});

  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LessonPdf? pdf = ref.watch(lessonPdfProvider(lessonId)).valueOrNull;
    if (pdf == null) return const SizedBox.shrink();
    return IconButton(
      onPressed: () => openLessonPdf(context, ref, pdf),
      icon: const Icon(Icons.picture_as_pdf_rounded),
      color: DirasstyColors.teal,
      tooltip: AppLocalizations.of(context).downloadLessonPdf,
    );
  }
}

/// "Télécharger le cours en PDF" card — hidden when the lesson has none.
class LessonPdfCard extends ConsumerWidget {
  const LessonPdfCard({required this.lessonId, super.key});

  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LessonPdf? pdf = ref.watch(lessonPdfProvider(lessonId)).valueOrNull;
    if (pdf == null) return const SizedBox.shrink();
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    return DirasstyCard(
      onTap: () => openLessonPdf(context, ref, pdf),
      child: Row(
        children: [
          const IconBadge(icon: Icons.picture_as_pdf_rounded, size: 44),
          const SizedBox(width: DirasstySpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.downloadLessonPdf, style: type.subheading),
                const SizedBox(height: 2),
                Text(
                  '${l10n.lessonPdfSub}${_sizeLabel(pdf.size)}',
                  style: type.label.copyWith(fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.download_rounded,
            color: DirasstyColors.textMuted,
          ),
        ],
      ),
    );
  }
}
