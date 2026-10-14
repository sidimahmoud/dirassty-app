import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/dirassty_theme.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_providers.dart';
import '../../student/application/student_providers.dart';

/// "Rafiq is an AI, it can be wrong" + a "Signaler" link, shown under
/// every Rafiq (AI) answer. The report (reason, optional comment, the
/// answer text and a little context) goes to `ai_reports` (migration 063)
/// and is reviewed in Admin → Révision → Signalements IA. Required by
/// Google Play's AI-generated content policy.
class ReportAiButton extends ConsumerWidget {
  const ReportAiButton({
    required this.feature,
    required this.aiText,
    this.reportContext = const {},
    this.studentId,
    super.key,
  });

  /// 'tutor' | 'homework' | 'correction' | 'insight'.
  final String feature;

  /// The answer being reported, as shown to the user.
  final String aiText;

  /// Ids that help the team find the source (lesson, exercise, action…).
  final Map<String, Object?> reportContext;

  /// The child concerned when a parent reports; resolved from the session
  /// for a signed-in student.
  final String? studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.aiDisclaimer,
            style: type.label.copyWith(
              fontWeight: FontWeight.w400,
              fontSize: 11,
              color: DirasstyColors.textMuted,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: () => _open(context, ref),
          style: TextButton.styleFrom(
            foregroundColor: DirasstyColors.textMuted,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 6),
          ),
          icon: const Icon(Icons.flag_outlined, size: 16),
          label: Text(l10n.reportAiAnswer, style: type.label),
        ),
      ],
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final bool? sent = await showDirasstyBottomSheet<bool>(
      context,
      builder: (_) => _ReportForm(
        feature: feature,
        aiText: aiText,
        reportContext: reportContext,
        studentId: studentId,
      ),
    );
    if (sent == true && context.mounted) {
      showDirasstySnackBar(
          context, AppLocalizations.of(context).reportAiThanks);
    }
  }
}

class _ReportForm extends ConsumerStatefulWidget {
  const _ReportForm({
    required this.feature,
    required this.aiText,
    required this.reportContext,
    this.studentId,
  });

  final String feature;
  final String aiText;
  final Map<String, Object?> reportContext;
  final String? studentId;

  @override
  ConsumerState<_ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends ConsumerState<_ReportForm> {
  final TextEditingController _comment = TextEditingController();
  String _reason = 'wrong';
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final SupabaseClient db = ref.read(supabaseClientProvider);
      String? studentId = widget.studentId;
      if (studentId == null) {
        try {
          studentId = (await ref.read(currentStudentProvider.future)).id;
        } catch (_) {
          // Not a student session (parent) — the report still goes through.
        }
      }
      final String text = widget.aiText.length > 8000
          ? widget.aiText.substring(0, 8000)
          : widget.aiText;
      final String comment = _comment.text.trim();
      await db.from('ai_reports').insert({
        'feature': widget.feature,
        'reason': _reason,
        if (comment.isNotEmpty) 'comment': comment,
        'ai_text': text,
        'context': widget.reportContext,
        if (studentId != null) 'student_id': studentId,
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = AppLocalizations.of(context).reportAiError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final List<(String, String)> reasons = [
      ('wrong', l10n.reportAiReasonWrong),
      ('inappropriate', l10n.reportAiReasonInappropriate),
      ('other', l10n.reportAiReasonOther),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.reportAiTitle, style: type.titleSmall),
        const SizedBox(height: DirasstySpace.sm),
        Wrap(
          spacing: DirasstySpace.sm,
          runSpacing: DirasstySpace.sm,
          children: [
            for (final (String value, String label) in reasons)
              DirasstyChip(
                label: label,
                variant: value == _reason
                    ? DirasstyChipVariant.selected
                    : DirasstyChipVariant.neutral,
                onTap: _sending ? null : () => setState(() => _reason = value),
              ),
          ],
        ),
        const SizedBox(height: DirasstySpace.md),
        TextField(
          controller: _comment,
          enabled: !_sending,
          minLines: 2,
          maxLines: 4,
          maxLength: 1000,
          decoration: InputDecoration(hintText: l10n.reportAiCommentHint),
        ),
        if (_error != null)
          Text(_error!,
              style: type.label.copyWith(color: DirasstyColors.error)),
        const SizedBox(height: DirasstySpace.sm),
        DirasstyButton(
          label: l10n.reportAiSend,
          loading: _sending,
          onPressed: _sending ? null : _send,
        ),
      ],
    );
  }
}
