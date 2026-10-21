import 'package:flutter/material.dart';

import '../../../../core/theme/dirassty_theme.dart';
import '../../../../core/widgets/dirassty/dirassty_widgets.dart';

/// A bordered card of [ProfileRow]s with hairline dividers — the grouped
/// list on both profiles (Profile.dc.html).
class ProfileGroup extends StatelessWidget {
  const ProfileGroup({required this.rows, super.key});

  final List<ProfileRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DirasstyColors.surface,
        borderRadius: DirasstyRadius.cardR,
        border: Border.all(color: DirasstyColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            for (int i = 0; i < rows.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              rows[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// One 56 px row: icon, title (+ subtitle), optional trailing, chevron.
class ProfileRow extends StatelessWidget {
  const ProfileRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.destructive = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final DirasstyType type = context.dirasstyType;
    final Color color = destructive ? DirasstyColors.error : DirasstyColors.ink;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: DirasstySpace.lg,
            vertical: 10,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: DirasstySize.iconList,
                color: destructive
                    ? DirasstyColors.error
                    : DirasstyColors.textMuted,
              ),
              const SizedBox(width: DirasstySpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: type.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: type.label.copyWith(fontWeight: FontWeight.w400),
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                trailing!,
                const SizedBox(width: DirasstySpace.sm),
              ],
              if (!destructive)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: DirasstyColors.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
