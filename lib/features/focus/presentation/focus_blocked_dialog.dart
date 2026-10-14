import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/focus_settings.dart';
import '../../../core/theme/dirassty_theme.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../application/focus_providers.dart';

/// Bumped to ask [FocusModeOverlay] (which lives above the Navigator) to
/// open its parent-PIN sheet from a regular screen.
final StateProvider<int> focusUnlockRequestProvider =
    StateProvider<int>((ref) => 0);

/// Logout, account deletion and the language change would be easy ways
/// around focus mode: while a window is active this shows the
/// FocusBlocked dialog ("Continuer à étudier" / "Saisir le code parent")
/// and returns true so the caller skips the action.
///
/// design_handoff FocusBlocked.dc.html · DESIGN_SPEC §4 "Focus mode".
bool blockedByFocus(BuildContext context, WidgetRef ref) {
  final FocusLockState focus = ref.read(focusLockControllerProvider);
  if (!focus.isActive) return false;
  final ProviderContainer container =
      ProviderScope.containerOf(context, listen: false);
  final AppLocalizations l10n = AppLocalizations.of(context);
  final DateTime until = focus.activeUntil!;
  showDirasstyDialog<bool>(
    context,
    icon: Icons.track_changes_rounded,
    iconBackground: DirasstyColors.goldTint,
    iconColor: DirasstyColors.ink,
    title: l10n.focusBlockedTitle,
    message: l10n.focusBlockedBody(
        FocusWindow.formatMinute(until.hour * 60 + until.minute)),
    actions: [
      DirasstyDialogAction(label: l10n.keepStudying, value: false),
      DirasstyDialogAction(
          label: l10n.enterParentCode,
          value: true,
          variant: DirasstyButtonVariant.quiet),
    ],
  ).then((bool? enterCode) {
    if (enterCode == true) {
      container.read(focusUnlockRequestProvider.notifier).state++;
    }
  });
  return true;
}
