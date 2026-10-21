import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/app_auth_state.dart';
import '../../features/auth/application/auth_providers.dart';
import '../router/app_router.dart';
import '../theme/dirassty_theme.dart';
import '../widgets/dirassty/dirassty_context.dart';
import 'push_providers.dart';
import 'push_service.dart';

/// Mounted once via `MaterialApp.builder` (see DirasstyApp): shows a Dirassty
/// banner at the top for a push that arrives while the app is open (the
/// OS doesn't display those itself), and opens the right screen when a
/// notification — banner or system tray — is tapped.
class PushBannerHost extends ConsumerStatefulWidget {
  const PushBannerHost({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<PushBannerHost> createState() => _PushBannerHostState();
}

class _PushBannerHostState extends ConsumerState<PushBannerHost> {
  PushMessage? _current;
  bool _visible = false;
  Timer? _hide;
  late final StreamSubscription<PushMessage> _fg;
  late final StreamSubscription<PushMessage> _tap;

  @override
  void initState() {
    super.initState();
    final PushService push = ref.read(pushServiceProvider);
    _fg = push.foreground.listen(_show);
    _tap = push.taps.listen((m) => _open(m.route));
    // After subscribing: a tap that cold-started the app is emitted now.
    push.start();
  }

  @override
  void dispose() {
    _hide?.cancel();
    _fg.cancel();
    _tap.cancel();
    super.dispose();
  }

  void _show(PushMessage m) {
    if (m.title.isEmpty && m.body.isEmpty) return;
    _hide?.cancel();
    setState(() {
      _current = m;
      _visible = true;
    });
    _hide = Timer(const Duration(seconds: 5), _dismiss);
  }

  void _dismiss() {
    if (mounted) setState(() => _visible = false);
  }

  void _open(String? route) {
    final bool isParent =
        ref.read(appAuthStateProvider).valueOrNull is AppAuthParent;
    ref
        .read(goRouterProvider)
        .go(PushService.routeFor(route, isParent: isParent));
  }

  @override
  Widget build(BuildContext context) {
    final PushMessage? m = _current;
    return Stack(
      children: [
        widget.child,
        if (m != null)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SafeArea(
              bottom: false,
              child: AnimatedSlide(
                offset: _visible ? Offset.zero : const Offset(0, -1.4),
                duration:
                    context.reduceMotion ? Duration.zero : DirasstyMotion.sheet,
                curve: DirasstyMotion.curve,
                onEnd: () {
                  if (!_visible && mounted) setState(() => _current = null);
                },
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    DirasstySpace.md,
                    DirasstySpace.sm,
                    DirasstySpace.md,
                    0,
                  ),
                  child: _Banner(
                    message: m,
                    onTap: () {
                      _dismiss();
                      _open(m.route);
                    },
                    onClose: _dismiss,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.message,
    required this.onTap,
    required this.onClose,
  });

  final PushMessage message;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final DirasstyType type = context.dirasstyType;
    return Semantics(
      liveRegion: true,
      child: Material(
        color: DirasstyColors.surface,
        elevation: 8,
        shadowColor: DirasstyColors.ink.withValues(alpha: 0.25),
        shape: const RoundedRectangleBorder(
          borderRadius: DirasstyRadius.cardR,
          side: BorderSide(color: DirasstyColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              DirasstySpace.md,
              DirasstySpace.md,
              DirasstySpace.xs,
              DirasstySpace.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: DirasstyColors.teal,
                    borderRadius: DirasstyRadius.cardR,
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: DirasstySpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.title.isNotEmpty)
                        Text(
                          message.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: type.subheading.copyWith(fontSize: 15),
                        ),
                      if (message.body.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          message.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: type.bodySmall
                              .copyWith(color: DirasstyColors.textMuted),
                        ),
                      ],
                      if (message.image != null) ...[
                        const SizedBox(height: DirasstySpace.sm),
                        ClipRRect(
                          borderRadius: DirasstyRadius.smallR,
                          child: Image.network(
                            message.image!,
                            height: 110,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // No `tooltip`: this banner lives in MaterialApp.builder,
                // above the Navigator's Overlay, and a Tooltip without an
                // Overlay ancestor throws (red error screen). Same label
                // for screen readers via Semantics instead.
                Semantics(
                  button: true,
                  label: MaterialLocalizations.of(context).closeButtonTooltip,
                  excludeSemantics: true,
                  child: IconButton(
                    onPressed: onClose,
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: DirasstyColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
