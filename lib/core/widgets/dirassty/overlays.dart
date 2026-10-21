import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../theme/dirassty_theme.dart';
import 'badges.dart';
import 'dirassty_button.dart';
import 'dirassty_context.dart';

/// Ink snackbar, radius 12, white 14 text, mint action, 4 s. [offline]
/// prefixes the gold wifi-off icon.
///
/// DESIGN_SPEC.md §2 "Snackbar".
void showDirasstySnackBar(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  bool offline = false,
}) {
  final DirasstyType type = context.dirasstyType;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: DirasstyColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: DirasstyRadius.cardR),
        content: Row(
          children: [
            if (offline) ...[
              const Icon(
                Icons.wifi_off_rounded,
                size: 18,
                color: DirasstyColors.gold,
              ),
              const SizedBox(width: DirasstySpace.sm),
            ],
            Expanded(
              child: Text(
                message,
                style: type.bodySmall.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        action: actionLabel == null
            ? null
            : SnackBarAction(
                label: actionLabel,
                textColor: DirasstyColors.mint,
                onPressed: onAction ?? () {},
              ),
      ),
    );
}

/// One stacked dialog action.
class DirasstyDialogAction<T> {
  const DirasstyDialogAction({
    required this.label,
    this.value,
    this.variant = DirasstyButtonVariant.primary,
  });

  final String label;

  /// Returned from [showDirasstyDialog] when tapped.
  final T? value;
  final DirasstyButtonVariant variant;
}

/// Dialog: radius 20, padding 24, an icon badge on top, title 18–20/800,
/// body 14 muted, actions stacked full width. Returns the tapped action's
/// value (null when dismissed).
///
/// DESIGN_SPEC.md §2 "Dialog".
Future<T?> showDirasstyDialog<T>(
  BuildContext context, {
  required String title,
  required List<DirasstyDialogAction<T>> actions,
  String? message,
  IconData? icon,
  Color iconBackground = DirasstyColors.tealTint,
  Color iconColor = DirasstyColors.teal,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: DirasstyColors.scrim,
    builder: (dialogContext) {
      final DirasstyType type = dialogContext.dirasstyType;
      return Dialog(
        backgroundColor: DirasstyColors.surface,
        shape:
            const RoundedRectangleBorder(borderRadius: DirasstyRadius.dialogR),
        insetPadding: const EdgeInsets.symmetric(horizontal: DirasstySpace.xl),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(DirasstySpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (icon != null) ...[
                Center(
                  child: IconBadge(
                    icon: icon,
                    size: 56,
                    background: iconBackground,
                    foreground: iconColor,
                  ),
                ),
                const SizedBox(height: DirasstySpace.lg),
              ],
              Text(title, textAlign: TextAlign.center, style: type.titleSmall),
              if (message != null) ...[
                const SizedBox(height: DirasstySpace.sm),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: type.bodySmall,
                ),
              ],
              const SizedBox(height: DirasstySpace.xl),
              for (int i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(height: DirasstySpace.sm),
                DirasstyButton(
                  label: actions[i].label,
                  variant: actions[i].variant,
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(actions[i].value),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

/// Bottom sheet: radius 20 on the top corners, 40×4 drag handle, ink
/// scrim at 45 %. [builder] content is padded 20 and respects the
/// keyboard and bottom safe area.
///
/// DESIGN_SPEC.md §2 "BottomSheet".
Future<T?> showDirasstyBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: DirasstyColors.background,
    barrierColor: DirasstyColors.scrim,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(borderRadius: DirasstyRadius.sheetR),
    // Sheets slide up in 300 ms (DESIGN_SPEC §6), instantly with reduced
    // motion.
    sheetAnimationStyle: context.reduceMotion
        ? AnimationStyle.noAnimation
        : const AnimationStyle(
            duration: DirasstyMotion.sheet,
            reverseDuration: DirasstyMotion.fast,
          ),
    builder: (sheetContext) => Padding(
      padding: EdgeInsetsDirectional.only(
        start: DirasstySpace.screen,
        end: DirasstySpace.screen,
        bottom:
            MediaQuery.viewInsetsOf(sheetContext).bottom + DirasstySpace.screen,
      ),
      child: SafeArea(top: false, child: builder(sheetContext)),
    ),
  );
}

/// Empty and error states: 64 px round icon badge (teal tint for empty,
/// red tint for error), title 16/700, text 14 muted, optional secondary
/// button. DESIGN_SPEC.md §2 "EmptyState / ErrorState".
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    super.key,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => _StateBody(
        badge: IconBadge(icon: icon),
        title: title,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
      );
}

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.title,
    this.message,
    this.onRetry,
  });

  /// Defaults to the generic "couldn't load" copy.
  final String? title;
  final String? message;

  /// Shows "Réessayer" when set.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return _StateBody(
      badge: const IconBadge(
        icon: Icons.cloud_off_rounded,
        background: DirasstyColors.errorTint,
        foreground: DirasstyColors.error,
      ),
      title: title ?? l10n.errorLoad,
      message: message,
      actionLabel: onRetry == null ? null : l10n.retry,
      onAction: onRetry,
    );
  }
}

class _StateBody extends StatelessWidget {
  const _StateBody({
    required this.badge,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final Widget badge;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final DirasstyType type = context.dirasstyType;
    return Padding(
      padding: const EdgeInsetsDirectional.all(DirasstySpace.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          badge,
          const SizedBox(height: DirasstySpace.lg),
          Text(title, textAlign: TextAlign.center, style: type.subheading),
          if (message != null) ...[
            const SizedBox(height: DirasstySpace.xs),
            Text(message!, textAlign: TextAlign.center, style: type.bodySmall),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: DirasstySpace.lg),
            DirasstyButton(
              label: actionLabel!,
              onPressed: onAction,
              variant: DirasstyButtonVariant.secondary,
              compact: true,
              expand: false,
            ),
          ],
        ],
      ),
    );
  }
}

/// Loading placeholder block, same radius as the content it stands in
/// for. Shimmers between the two skeleton tones on a 1.2 s loop — static
/// with reduce-motion on. DESIGN_SPEC.md §2 "Skeleton".
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = DirasstyRadius.small,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(
              DirasstyColors.skeleton,
              DirasstyColors.skeletonLight,
              _controller.value,
            ),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}

/// Ink bar: gold wifi-off icon, "Hors ligne · …" and a mint "Voir" link.
/// Sits at the top of a data screen while offline (cached data stays
/// visible below). DESIGN_SPEC.md §2 "OfflineBanner".
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.onSee});

  /// Opens the downloads — hides the link when null.
  final VoidCallback? onSee;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    return Semantics(
      liveRegion: true,
      child: Container(
        color: DirasstyColors.ink,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: DirasstySpace.screen,
          vertical: DirasstySpace.sm,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 18,
              color: DirasstyColors.gold,
            ),
            const SizedBox(width: DirasstySpace.sm),
            Expanded(
              child: Text(
                l10n.offlineBanner,
                style: type.label.copyWith(color: Colors.white),
              ),
            ),
            if (onSee != null)
              TextButton(
                onPressed: onSee,
                style:
                    TextButton.styleFrom(foregroundColor: DirasstyColors.mint),
                child: Text(l10n.see),
              ),
          ],
        ),
      ),
    );
  }
}

/// Full-width ink bar shown on every student screen during a parental
/// focus window: gold target icon, "Mode concentration jusqu'à HH:MM",
/// and a "Déverrouiller" pill at the end. DESIGN_SPEC.md §2
/// "FocusModeBar".
class FocusModeBar extends StatelessWidget {
  const FocusModeBar({
    required this.untilLabel,
    required this.onUnlock,
    super.key,
  });

  /// Already formatted time, e.g. "19:00".
  final String untilLabel;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    return Material(
      color: DirasstyColors.ink,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            DirasstySpace.screen,
            DirasstySpace.sm,
            DirasstySpace.md,
            DirasstySpace.sm,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.track_changes_rounded,
                size: 20,
                color: DirasstyColors.gold,
              ),
              const SizedBox(width: DirasstySpace.sm),
              Expanded(
                child: Text(
                  l10n.focusUntil(untilLabel),
                  style: type.subheading
                      .copyWith(color: Colors.white, fontSize: 14),
                ),
              ),
              Material(
                color: Colors.white.withValues(alpha: 0.12),
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: onUnlock,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 36),
                    child: Padding(
                      padding:
                          const EdgeInsetsDirectional.symmetric(horizontal: 14),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          l10n.unlock,
                          style: type.label.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
