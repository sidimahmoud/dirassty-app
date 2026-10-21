import 'package:flutter/material.dart';

import '../../../../core/theme/dirassty_theme.dart';
import '../../../../core/widgets/dirassty/dirassty_widgets.dart';

/// Segmented control on a `track` background: 44 px segments, radius 8
/// (or pill-shaped, 36 px, for the cycle picker).
class AuthSegmented extends StatelessWidget {
  const AuthSegmented({
    required this.options,
    required this.selected,
    required this.onChanged,
    super.key,
    this.pill = false,
  });

  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;
  final bool pill;

  @override
  Widget build(BuildContext context) {
    final DirasstyType type = context.dirasstyType;
    final BorderRadius outer =
        pill ? DirasstyRadius.pillR : DirasstyRadius.cardR;
    final BorderRadius inner =
        pill ? DirasstyRadius.pillR : DirasstyRadius.smallR;
    return Container(
      padding: const EdgeInsets.all(DirasstySpace.xs),
      decoration:
          BoxDecoration(color: DirasstyColors.track, borderRadius: outer),
      child: Row(
        children: [
          for (int i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: DirasstySpace.xs),
            Expanded(
              child: Semantics(
                button: true,
                selected: i == selected,
                child: InkWell(
                  borderRadius: inner,
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: context.reduceMotion
                        ? Duration.zero
                        : DirasstyMotion.fast,
                    height: pill ? 36 : DirasstySize.minTouch,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == selected
                          ? DirasstyColors.surface
                          : Colors.transparent,
                      borderRadius: inner,
                      boxShadow: i == selected ? DirasstyShadow.level1 : null,
                    ),
                    child: Text(
                      options[i],
                      style: (pill
                              ? type.label
                              : type.label.copyWith(fontSize: 14))
                          .copyWith(
                        color: i == selected
                            ? DirasstyColors.ink
                            : DirasstyColors.textMuted,
                        fontWeight:
                            i == selected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
