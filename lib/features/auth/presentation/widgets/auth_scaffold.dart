import 'package:flutter/material.dart';

import '../../../../core/theme/dirassty_theme.dart';
import '../../../../core/widgets/dirassty/dirassty_widgets.dart';

/// Shared frame for the onboarding screens (design_handoff Welcome /
/// StudentLogin / ParentLogin / VerifyCode / Register / TrialOffer /
/// ClaimInvite): background, 44 pt back button, 20 px side padding
/// (24 on centered hero screens), section gap 20, and [bottom] pinned to
/// the bottom edge on tall screens (`margin-top: auto` in the HTML) while
/// still scrolling with the content on short ones / with the keyboard up.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.children,
    super.key,
    this.bottom = const [],
    this.showBack = true,
    this.onBack,
    this.sidePadding = DirasstySpace.screen,
    this.gap = DirasstySpace.section,
  });

  final List<Widget> children;
  final List<Widget> bottom;
  final bool showBack;

  /// Defaults to popping the route.
  final VoidCallback? onBack;
  final double sidePadding;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DirasstyColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: EdgeInsetsDirectional.fromSTEB(
              sidePadding,
              DirasstySpace.lg,
              sidePadding,
              DirasstySpace.xxl,
            ),
            child: ConstrainedBox(
              // Clamped: Android can report a 0-height window for the first
              // frame(s), and a negative minHeight throws.
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight -
                        DirasstySpace.lg -
                        DirasstySpace.xxl)
                    .clamp(0.0, double.infinity),
              ),
              // No IntrinsicHeight/Spacer: a Column with unbounded max
              // height but a min height still grows to that min, and
              // spaceBetween pushes the bottom group down — without the
              // intrinsic-size pass (which throws on descendants like
              // LayoutBuilder-based widgets).
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showBack)
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Transform.translate(
                            // Optically align the arrow with the content edge.
                            offset: Offset(
                              Directionality.of(context) == TextDirection.rtl
                                  ? 10
                                  : -10,
                              0,
                            ),
                            child: IconButton(
                              onPressed: onBack ??
                                  () => Navigator.of(context).maybePop(),
                              icon: const BackButtonIcon(),
                              color: DirasstyColors.ink,
                              tooltip: MaterialLocalizations.of(context)
                                  .backButtonTooltip,
                              constraints: const BoxConstraints.tightFor(
                                width: DirasstySize.minTouch,
                                height: DirasstySize.minTouch,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      for (int i = 0; i < children.length; i++) ...[
                        if (i > 0 || showBack)
                          SizedBox(height: i == 0 ? DirasstySpace.xs : gap),
                        children[i],
                      ],
                    ],
                  ),
                  if (bottom.isNotEmpty)
                    Padding(
                      padding: EdgeInsetsDirectional.only(top: gap),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (int i = 0; i < bottom.length; i++) ...[
                            if (i > 0) const SizedBox(height: DirasstySpace.lg),
                            bottom[i],
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Title (24/800) + optional body (14 muted) block under the back button.
class AuthHeading extends StatelessWidget {
  const AuthHeading({
    required this.title,
    super.key,
    this.body,
    this.bodyTrailing,
  });

  final String title;
  final String? body;

  /// Inline link after the body text (e.g. "Activer mon compte").
  final Widget? bodyTrailing;

  @override
  Widget build(BuildContext context) {
    final DirasstyType type = context.dirasstyType;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: type.title),
        if (body != null) ...[
          const SizedBox(height: DirasstySpace.sm),
          Text(body!, style: type.bodySmall),
        ],
        if (bodyTrailing != null) bodyTrailing!,
      ],
    );
  }
}

/// Section label (14/600) with an optional trailing action on the same
/// line — "Code PIN · Code oublié ?".
class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel({required this.label, super.key, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: context.dirasstyType.label
                .copyWith(fontSize: 14, color: DirasstyColors.text),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
