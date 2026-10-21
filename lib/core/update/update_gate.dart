import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../actions/app_promotion_actions.dart';
import '../theme/dirassty_theme.dart';
import '../widgets/dirassty/dirassty_widgets.dart';
import 'app_update.dart';

/// Mounted once in `MaterialApp.builder` (see DirasstyApp), above every
/// screen:
/// - update **required** (installed < admin's minimum) → a full-screen
///   block with the update button; nothing underneath is reachable;
/// - update **available** (installed < admin's latest) → a dismissible
///   card at the bottom, shown once per version.
///
/// Lives above the Navigator/Overlay, so no Tooltip, dialog or sheet here
/// (they need an Overlay ancestor — see PushBannerHost).
class UpdateGate extends ConsumerStatefulWidget {
  const UpdateGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends ConsumerState<UpdateGate> {
  static const String _dismissedKey = 'update.dismissedVersion';
  String? _dismissed;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _dismissed = p.getString(_dismissedKey));
    });
  }

  Future<void> _dismiss(String? version) async {
    setState(() => _dismissed = version ?? '');
    final SharedPreferences p = await SharedPreferences.getInstance();
    await p.setString(_dismissedKey, version ?? '');
  }

  Future<void> _open(AppUpdateStatus s) async {
    final String? url = s.url;
    if (url == null) {
      await contactSupport(context);
      return;
    }
    final Uri? uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final AppUpdateStatus s =
        ref.watch(appUpdateStatusProvider).valueOrNull ?? AppUpdateStatus.none;
    return Stack(
      children: [
        widget.child,
        if (s.kind == UpdateKind.required)
          Positioned.fill(
            child: _RequiredScreen(status: s, onUpdate: () => _open(s)),
          )
        else if (s.kind == UpdateKind.available &&
            _dismissed != null &&
            _dismissed != s.latestVersion)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  DirasstySpace.md,
                  0,
                  DirasstySpace.md,
                  DirasstySpace.md,
                ),
                child: _AvailableCard(
                  status: s,
                  onUpdate: () => _open(s),
                  onLater: () => _dismiss(s.latestVersion),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

String? _notes(BuildContext context, AppUpdateStatus s) {
  final String? n = context.isArabicLocale
      ? (s.notesAr ?? s.notesFr)
      : (s.notesFr ?? s.notesAr);
  return n == null || n.trim().isEmpty ? null : n.trim();
}

class _RequiredScreen extends StatelessWidget {
  const _RequiredScreen({required this.status, required this.onUpdate});

  final AppUpdateStatus status;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final String? notes = _notes(context, status);
    return Material(
      color: DirasstyColors.background,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.all(DirasstySpace.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: IconBadge(
                    icon: Icons.system_update_rounded,
                    size: 104,
                    background: DirasstyColors.tealTint,
                    foreground: DirasstyColors.teal,
                  ),
                ),
                const SizedBox(height: DirasstySpace.screen),
                Text(
                  l10n.updateRequiredTitle,
                  textAlign: TextAlign.center,
                  style: type.title.copyWith(fontSize: 26),
                ),
                const SizedBox(height: DirasstySpace.sm),
                Text(
                  l10n.updateRequiredBody,
                  textAlign: TextAlign.center,
                  style: type.body.copyWith(color: DirasstyColors.textMuted),
                ),
                if (status.latestVersion != null) ...[
                  const SizedBox(height: DirasstySpace.sm),
                  Text(
                    l10n.updateVersionLabel(status.latestVersion!),
                    textAlign: TextAlign.center,
                    style: type.label,
                  ),
                ],
                if (notes != null) ...[
                  const SizedBox(height: DirasstySpace.lg),
                  _Notes(text: notes),
                ],
                const SizedBox(height: DirasstySpace.xl),
                DirasstyButton(
                  label:
                      status.url == null ? l10n.updateNoLink : l10n.updateNow,
                  icon: Icons.download_rounded,
                  onPressed: onUpdate,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvailableCard extends StatelessWidget {
  const _AvailableCard({
    required this.status,
    required this.onUpdate,
    required this.onLater,
  });

  final AppUpdateStatus status;
  final VoidCallback onUpdate;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final String? notes = _notes(context, status);
    return Material(
      color: DirasstyColors.surface,
      elevation: 8,
      shadowColor: DirasstyColors.ink.withValues(alpha: 0.25),
      shape: const RoundedRectangleBorder(
        borderRadius: DirasstyRadius.cardR,
        side: BorderSide(color: DirasstyColors.line),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(DirasstySpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.system_update_rounded,
                  color: DirasstyColors.teal,
                ),
                const SizedBox(width: DirasstySpace.sm),
                Expanded(
                  child: Text(
                    l10n.updateAvailableTitle,
                    style: type.subheading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DirasstySpace.xs),
            Text(
              notes ?? l10n.updateAvailableBody,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: type.bodySmall.copyWith(color: DirasstyColors.textMuted),
            ),
            const SizedBox(height: DirasstySpace.md),
            Row(
              children: [
                Expanded(
                  child: DirasstyButton(
                    label: l10n.updateLater,
                    variant: DirasstyButtonVariant.secondary,
                    compact: true,
                    onPressed: onLater,
                  ),
                ),
                const SizedBox(width: DirasstySpace.sm),
                Expanded(
                  child: DirasstyButton(
                    label:
                        status.url == null ? l10n.updateNoLink : l10n.updateNow,
                    compact: true,
                    onPressed: onUpdate,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Notes extends StatelessWidget {
  const _Notes({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    return Container(
      padding: const EdgeInsetsDirectional.all(DirasstySpace.md),
      decoration: const BoxDecoration(
        color: DirasstyColors.tealTint,
        borderRadius: DirasstyRadius.cardR,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.updateWhatsNew,
            style: type.label.copyWith(color: DirasstyColors.tealDark),
          ),
          const SizedBox(height: DirasstySpace.xs),
          Text(
            text,
            style: type.bodySmall
                .copyWith(color: DirasstyColors.text, height: 1.5),
          ),
        ],
      ),
    );
  }
}
