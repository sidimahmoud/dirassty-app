import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dirassty_theme.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';
import 'choose_class_screen.dart';
import 'register_screen.dart';
import 'widgets/auth_scaffold.dart';

/// "Créer un compte" → who is signing up? Two large cards — student
/// (teal, C2 → Lycée, can sign up alone) and parent (gold, every grade,
/// adds the children) — each opening [RegisterScreen] for that role.
/// The cards rise in one after the other (instant with reduced motion).
class ChooseRoleScreen extends StatelessWidget {
  const ChooseRoleScreen({super.key});

  static const String path = '/signup';
  static const String name = 'chooseRole';

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;

    return AuthScaffold(
      gap: DirasstySpace.lg,
      children: [
        AuthHeading(title: l10n.chooseRoleTitle, body: l10n.chooseRoleBody),
        _Appear(
          order: 0,
          child: _RoleChoiceCard(
            icon: Icons.school_rounded,
            accent: DirasstyColors.teal,
            tint: DirasstyColors.tealTint,
            title: l10n.iAmStudent,
            description: l10n.roleStudentDesc,
            badge: l10n.roleStudentBadge,
            points: [l10n.roleStudentPoint1, l10n.roleStudentPoint2],
            onTap: () => context.pushNamed(ChooseClassScreen.name),
          ),
        ),
        _Appear(
          order: 1,
          child: _RoleChoiceCard(
            icon: Icons.family_restroom_rounded,
            accent: DirasstyColors.goldStroke,
            tint: DirasstyColors.goldTint,
            title: l10n.iAmParent,
            description: l10n.roleParentDesc,
            badge: l10n.roleParentBadge,
            points: [l10n.roleParentPoint1, l10n.roleParentPoint2],
            onTap: () => context.push(RegisterScreen.pathFor('parent')),
          ),
        ),
      ],
      bottom: [
        TextButton(
          onPressed: () => context.pop(),
          child: Text(l10n.signInWho,
              style: type.label.copyWith(color: DirasstyColors.teal)),
        ),
      ],
    );
  }
}

class _RoleChoiceCard extends StatelessWidget {
  const _RoleChoiceCard({
    required this.icon,
    required this.accent,
    required this.tint,
    required this.title,
    required this.description,
    required this.badge,
    required this.points,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final Color tint;
  final String title;
  final String description;
  final String badge;
  final List<String> points;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final DirasstyType type = context.dirasstyType;
    return Semantics(
      button: true,
      label: '$title. $description',
      child: Material(
        color: DirasstyColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: DirasstyRadius.dialogR,
          side: BorderSide(color: accent.withValues(alpha: 0.25), width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              // Soft decorative bubbles in the card's corner.
              PositionedDirectional(
                top: -40,
                end: -30,
                child: _Bubble(size: 150, color: tint),
              ),
              PositionedDirectional(
                top: 70,
                end: 40,
                child: _Bubble(size: 36, color: tint),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.all(DirasstySpace.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: AlignmentDirectional.topStart,
                              end: AlignmentDirectional.bottomEnd,
                              colors: [
                                accent,
                                Color.lerp(accent, Colors.black, 0.25)!
                              ],
                            ),
                            borderRadius: DirasstyRadius.dialogR,
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.30),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(icon, color: Colors.white, size: 34),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: DirasstySpace.md, vertical: 6),
                          decoration: BoxDecoration(
                            color: DirasstyColors.surface,
                            borderRadius: DirasstyRadius.pillR,
                            border: Border.all(
                                color: accent.withValues(alpha: 0.35)),
                          ),
                          child: Text(badge,
                              style: type.label
                                  .copyWith(color: accent, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: DirasstySpace.lg),
                    Text(title, style: type.title.copyWith(fontSize: 22)),
                    const SizedBox(height: DirasstySpace.xs),
                    Text(description,
                        style: type.bodySmall.copyWith(
                            color: DirasstyColors.textMuted, height: 1.45)),
                    const SizedBox(height: DirasstySpace.md),
                    for (final String p in points)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                size: 18, color: accent),
                            const SizedBox(width: DirasstySpace.sm),
                            Expanded(
                              child: Text(p,
                                  style: type.bodySmall
                                      .copyWith(color: DirasstyColors.text)),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: DirasstySpace.sm),
                    Row(
                      children: [
                        Text(AppLocalizations.of(context).continueAction,
                            style: type.subheading
                                .copyWith(color: accent, fontSize: 15)),
                        const SizedBox(width: DirasstySpace.xs),
                        Icon(
                            Directionality.of(context) == TextDirection.rtl
                                ? Icons.arrow_back_rounded
                                : Icons.arrow_forward_rounded,
                            size: 20,
                            color: accent),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      );
}

/// Fade + slight rise, staggered by [order].
class _Appear extends StatelessWidget {
  const _Appear({required this.order, required this.child});

  final int order;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + order * 140),
      curve: Interval(order * 0.25, 1, curve: DirasstyMotion.curve),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child:
            Transform.translate(offset: Offset(0, (1 - t) * 24), child: child),
      ),
      child: child,
    );
  }
}
