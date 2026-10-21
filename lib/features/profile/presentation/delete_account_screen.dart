import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/dirassty_theme.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/application/account_providers.dart';

const String _kConfirmWord = 'SUPPRIMER';

/// A confirmation gate before calling `delete_own_account` (see
/// AccountRepository) — the delete button stays disabled until
/// [_kConfirmWord] is typed exactly, a deliberate extra step for an
/// irreversible action rather than a single tap. On success the
/// controller signs out and the router's auth gate takes over.
///
/// Deviation from DESIGN_SPEC §4 "Profile": no parent-PIN step — the
/// typed confirmation stays the gate (and focus mode blocks reaching
/// this screen during a window, see blockedByFocus).
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  static const String path = '/profile/delete-account';
  static const String name = 'deleteAccount';

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _canConfirm = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final bool matches = _controller.text.trim() == _kConfirmWord;
      if (matches != _canConfirm) setState(() => _canConfirm = matches);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;

    ref.listen(deleteAccountControllerProvider, (previous, next) {
      if (next is AsyncError) showDirasstySnackBar(context, l10n.deleteFailed);
    });
    final bool isDeleting =
        ref.watch(deleteAccountControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: DirasstyColors.background,
      appBar: AppBar(title: Text(l10n.deleteAccount)),
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          DirasstySpace.screen,
          DirasstySpace.lg,
          DirasstySpace.screen,
          DirasstySpace.xxl,
        ),
        children: [
          const Center(
            child: IconBadge(
              icon: Icons.warning_amber_rounded,
              size: 72,
              background: DirasstyColors.errorTint,
              foreground: DirasstyColors.error,
            ),
          ),
          const SizedBox(height: DirasstySpace.lg),
          Text(
            l10n.deleteFinalTitle,
            textAlign: TextAlign.center,
            style: type.title,
          ),
          const SizedBox(height: DirasstySpace.xl),
          Container(
            padding: const EdgeInsetsDirectional.all(DirasstySpace.lg),
            decoration: const BoxDecoration(
              color: DirasstyColors.errorTint,
              borderRadius: DirasstyRadius.cardR,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.deleteLosesIntro,
                  style: type.subheading
                      .copyWith(fontSize: 14, color: DirasstyColors.errorDark),
                ),
                const SizedBox(height: DirasstySpace.sm),
                for (final String loss in [
                  l10n.deleteLossProgress,
                  l10n.deleteLossXp,
                  l10n.deleteLossHistory,
                ])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsetsDirectional.only(top: 2),
                          child: Icon(
                            Icons.remove_circle_outline_rounded,
                            size: 16,
                            color: DirasstyColors.error,
                          ),
                        ),
                        const SizedBox(width: DirasstySpace.sm),
                        Expanded(
                          child: Text(
                            loss,
                            style: type.bodySmall
                                .copyWith(color: DirasstyColors.text),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: DirasstySpace.md),
                Text(
                  l10n.deleteCannotUndo,
                  style: type.bodySmall.copyWith(color: DirasstyColors.text),
                ),
              ],
            ),
          ),
          const SizedBox(height: DirasstySpace.xl),
          DirasstyTextField(
            label: l10n.deleteTypeToConfirm(_kConfirmWord),
            controller: _controller,
            hint: _kConfirmWord,
            forceLtr: true,
          ),
          const SizedBox(height: DirasstySpace.xl),
          DirasstyButton(
            label: l10n.deleteForever,
            variant: DirasstyButtonVariant.danger,
            loading: isDeleting,
            onPressed: _canConfirm && !isDeleting
                ? () => ref
                    .read(deleteAccountControllerProvider.notifier)
                    .deleteAccount()
                : null,
          ),
        ],
      ),
    );
  }
}
