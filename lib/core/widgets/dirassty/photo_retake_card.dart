import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../theme/dirassty_theme.dart';
import 'dirassty_button.dart';
import 'dirassty_chip.dart';
import 'dirassty_context.dart';

/// Shown instead of an AI answer/verdict when the photo couldn't be read
/// reliably (the AI never guesses from unreadable work): what's wrong with
/// the photo, how to retake it, and a retake button. Used by the photo
/// helper and handwritten-solution checking.
class PhotoRetakeCard extends StatelessWidget {
  const PhotoRetakeCard({
    required this.issues,
    required this.onRetake,
    super.key,
  });

  /// Machine codes from the API: blurry, dark, rotated, cropped,
  /// missing_parts, illegible, not_the_exercise / not_school_material.
  final List<String> issues;
  final VoidCallback onRetake;

  static String label(AppLocalizations l10n, String code) => switch (code) {
        'blurry' => l10n.issueBlurry,
        'dark' => l10n.issueDark,
        'rotated' => l10n.issueRotated,
        'cropped' => l10n.issueCropped,
        'missing_parts' => l10n.issueMissingParts,
        'illegible' => l10n.issueIllegible,
        'not_the_exercise' || 'not_school_material' => l10n.issueNotExercise,
        _ => code,
      };

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    return Container(
      padding: const EdgeInsetsDirectional.all(DirasstySpace.lg),
      decoration: const BoxDecoration(
        color: DirasstyColors.goldTint,
        borderRadius: DirasstyRadius.cardR,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.photo_camera_outlined,
                color: DirasstyColors.goldStroke,
              ),
              const SizedBox(width: DirasstySpace.sm),
              Expanded(
                child: Text(
                  l10n.photoUnreadableTitle,
                  style: type.subheading.copyWith(fontSize: 15),
                ),
              ),
            ],
          ),
          if (issues.isNotEmpty) ...[
            const SizedBox(height: DirasstySpace.sm),
            Wrap(
              spacing: DirasstySpace.xs,
              runSpacing: DirasstySpace.xs,
              children: [
                for (final String i in issues)
                  DirasstyChip(label: label(l10n, i), dense: true),
              ],
            ),
          ],
          const SizedBox(height: DirasstySpace.sm),
          Text(
            l10n.photoUnreadableBody,
            style: type.bodySmall.copyWith(color: DirasstyColors.text),
          ),
          const SizedBox(height: DirasstySpace.md),
          DirasstyButton(
            label: l10n.retakePhoto,
            icon: Icons.photo_camera_rounded,
            variant: DirasstyButtonVariant.ink,
            compact: true,
            onPressed: onRetake,
          ),
        ],
      ),
    );
  }
}
