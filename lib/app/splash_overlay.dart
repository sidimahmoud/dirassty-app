import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/theme/dirassty_theme.dart';
import '../l10n/app_localizations.dart';

/// The animated half of the launch sequence. The native launch screen
/// (flutter_native_splash, configured in pubspec.yaml) shows the app icon
/// still, centered on white; it is kept up (see bootstrap.dart) until the
/// logo assets below are decoded, then this takes over from that exact
/// frame:
///
///   0–400 ms     the icon breathes in with a soft zoom
///   300–800 ms   it rises and settles above where the wordmark goes
///   600–1100 ms  the bilingual "Dirassty / دراستي" wordmark and the
///                "Apprendre · Pratiquer · Réussir" tagline fade up
///   1360–1600 ms the splash fades out, revealing Welcome or Home
///
/// The app builds underneath the whole time.
class SplashOverlay extends StatefulWidget {
  const SplashOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay>
    with SingleTickerProviderStateMixin {
  /// Once per process: MaterialApp.builder can rebuild this subtree, but
  /// the splash should never replay mid-session.
  static bool _played = false;

  static const String _iconAsset = 'assets/icon/icon.png';
  static const String _wordmarkAsset = 'assets/logo/wordmark.svg';

  /// Must match the native splash icon size (512px image rendered at 4x
  /// by flutter_native_splash → 128 logical px).
  static const double _nativeIconSize = 128;
  static const double _lockupIconSize = 112;
  static const double _gap = 20;

  /// brand/2-wordmark bilingual wordmark viewBox (522.22 × 322.18).
  static const double _wordmarkAspect = 522.22 / 322.18;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  bool _done = _played;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    if (_done) FlutterNativeSplash.remove();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_done || _started) return;
    _started = true;
    _played = true;
    _warmUpThenPlay();
  }

  /// Decodes the icon and wordmark first so the hand-off from the native
  /// splash is invisible, then starts the animation. Never blocks launch:
  /// on any failure it just plays.
  Future<void> _warmUpThenPlay() async {
    try {
      await Future.wait([
        precacheImage(const AssetImage(_iconAsset), context),
        svg.cache.putIfAbsent(
          const SvgAssetLoader(_wordmarkAsset).cacheKey(null),
          () => const SvgAssetLoader(_wordmarkAsset).loadBytes(null),
        ),
      ]).timeout(const Duration(seconds: 2));
    } catch (_) {}
    FlutterNativeSplash.remove();
    if (!mounted) return;
    _controller.forward().whenComplete(() {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final double t = _controller.value;
              final double exit = _segment(t, 0.85, 1, Curves.easeIn);
              return IgnorePointer(
                ignoring: exit > 0.5,
                child: Opacity(
                  opacity: 1 - exit,
                  child: ColoredBox(
                    color: Colors.white,
                    child: Stack(
                      children: [
                        Positioned.fill(child: _buildLogo(context, t)),
                        _buildTagline(context, t),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLogo(BuildContext context, double t) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    // Android can report a 0×0 window for the very first frame(s).
    if (screenWidth <= 0) return const SizedBox.shrink();

    final double wordmarkWidth = (screenWidth - 2 * 48).clamp(0.0, 200.0);
    final double wordmarkHeight = wordmarkWidth / _wordmarkAspect;

    // Soft zoom: a gentle breath in and back, no bounce.
    final double zoom = 1 + 0.07 * _breath(_segment(t, 0, 0.25));
    final double settle = _segment(t, 0.19, 0.5, Curves.easeInOutCubic);
    final double reveal = _segment(t, 0.375, 0.69, Curves.easeOutCubic);

    final double iconSize = _lerp(_nativeIconSize, _lockupIconSize, settle);
    // The icon starts at screen centre (like the native splash) and rises
    // so icon + gap + wordmark end up centred together.
    final double rise = (_gap + wordmarkHeight) / 2 * settle;

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: Offset(0, -rise),
            child: Transform.scale(
              scale: zoom,
              child: Image.asset(_iconAsset,
                  width: iconSize,
                  height: iconSize,
                  filterQuality: FilterQuality.medium),
            ),
          ),
          Transform.translate(
            offset: Offset(
                0,
                _lockupIconSize / 2 +
                    _gap +
                    wordmarkHeight / 2 -
                    rise +
                    12 * (1 - reveal)),
            child: Opacity(
              opacity: reveal,
              child: SvgPicture.asset(_wordmarkAsset,
                  width: wordmarkWidth, height: wordmarkHeight),
            ),
          ),
        ],
      ),
    );
  }
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// "Apprendre · Pratiquer · Réussir" with three loading dots, 56 px from
/// the bottom (Main.dc.html) — fades in with the wordmark.
extension on _SplashOverlayState {
  Widget _buildTagline(BuildContext context, double t) {
    final double appear = _segment(t, 0.45, 0.75, Curves.easeOut);
    final bool arabic = Localizations.localeOf(context).languageCode == 'ar';
    final int activeDot = (t * 9).floor() % 3;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 56,
      child: Opacity(
        opacity: appear,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == activeDot
                          ? DirasstyColors.teal
                          : DirasstyColors.teal.withValues(alpha: 0.22),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).tagline,
              style: DirasstyType(arabic).label,
            ),
          ],
        ),
      ),
    );
  }
}

/// 0→1 progress of [t] through the [begin, end] slice of the timeline.
double _segment(double t, double begin, double end,
    [Curve curve = Curves.linear]) {
  if (t <= begin) return 0;
  if (t >= end) return 1;
  return curve.transform((t - begin) / (end - begin));
}

/// 0 → 1 → 0 with soft ends, for the icon's zoom "breath".
double _breath(double p) =>
    Curves.easeInOut.transform(p < 0.5 ? p * 2 : 2 - p * 2);
