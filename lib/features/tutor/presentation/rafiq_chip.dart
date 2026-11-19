import 'package:flutter/material.dart';

import '../../../core/theme/dirassty_theme.dart';
import '../../../core/widgets/dirassty/dirassty_context.dart';
import '../../../l10n/app_localizations.dart';

/// Rafiq's face: teal gradient disc with a sparkle and a gold "online" dot.
class RafiqAvatar extends StatelessWidget {
  const RafiqAvatar({this.size = 40, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [DirasstyColors.teal, DirasstyColors.tealDark],
              ),
              boxShadow: DirasstyShadow.level1,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: size * 0.48,
            ),
          ),
          PositionedDirectional(
            end: -1,
            bottom: -1,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: DirasstyColors.gold,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact "Rafiq — Bloqué ? Demande-moi" button for a screen's bottom
/// action bar (open exercises).
class RafiqChip extends StatelessWidget {
  const RafiqChip({required this.onTap, this.showTagline = true, super.key});

  final VoidCallback onTap;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    return Semantics(
      button: true,
      label: l10n.askDirassty,
      child: Material(
        color: DirasstyColors.surface,
        shape: const StadiumBorder(
          side: BorderSide(color: DirasstyColors.line),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(6, 6, 14, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const RafiqAvatar(size: 40),
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rafiq',
                      style: type.subheading.copyWith(fontSize: 14),
                    ),
                    if (showTagline)
                      Text(
                        l10n.rafiqTagline,
                        style: type.label.copyWith(fontSize: 11),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
