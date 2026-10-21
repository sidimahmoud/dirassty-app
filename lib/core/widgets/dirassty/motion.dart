import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/dirassty_theme.dart';
import 'dirassty_context.dart';

/// Replays a one-shot feedback animation on [child] each time [trigger]
/// changes (DESIGN_SPEC §6 "Answer feedback"):
/// - [AnswerFeedback.correct]: scale pulse 1 → 1.02 → 1 in 250 ms;
/// - [AnswerFeedback.wrong]: horizontal shake, 3 × 4 px in 240 ms, plus a
///   light haptic.
/// Does nothing when the OS asks for reduced motion (the haptic still
/// fires — it's feedback, not motion).
enum AnswerFeedback { none, correct, wrong }

class FeedbackMotion extends StatefulWidget {
  const FeedbackMotion({
    required this.feedback,
    required this.child,
    super.key,
  });

  final AnswerFeedback feedback;
  final Widget child;

  @override
  State<FeedbackMotion> createState() => _FeedbackMotionState();
}

class _FeedbackMotionState extends State<FeedbackMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  static final Animatable<double> _pulse = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: 1.02), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1.02, end: 1), weight: 1),
  ]).chain(CurveTween(curve: Curves.easeOut));

  @override
  void didUpdateWidget(FeedbackMotion old) {
    super.didUpdateWidget(old);
    if (old.feedback == widget.feedback) return;
    if (widget.feedback == AnswerFeedback.wrong) {
      HapticFeedback.lightImpact();
    }
    if (widget.feedback == AnswerFeedback.none || context.reduceMotion) {
      return;
    }
    _controller.duration = widget.feedback == AnswerFeedback.correct
        ? DirasstyMotion.feedback
        : DirasstyMotion.shake;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final double t = _controller.value;
        if (!_controller.isAnimating) return child!;
        if (widget.feedback == AnswerFeedback.correct) {
          return Transform.scale(scale: _pulse.transform(t), child: child);
        }
        final double dx = math.sin(t * 3 * 2 * math.pi) * 4 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}

/// Fades in while rising [distance] px — the "+10 XP" chip (250 ms).
class RiseIn extends StatelessWidget {
  const RiseIn({
    required this.child,
    this.distance = 8,
    this.duration = DirasstyMotion.feedback,
    super.key,
  });

  final Widget child;
  final double distance;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: DirasstyMotion.curve,
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, distance * (1 - t)),
          child: child,
        ),
      ),
    );
  }
}

/// Scales from [begin] to 1 after [delay] with a soft spring — the
/// streak flame (0.6 → 1, 380 ms) and its sparks.
class ScaleIn extends StatefulWidget {
  const ScaleIn({
    required this.child,
    this.begin = 0.6,
    this.delay = Duration.zero,
    this.duration = DirasstyMotion.celebrate,
    this.burst = Offset.zero,
    super.key,
  });

  final Widget child;
  final double begin;
  final Duration delay;
  final Duration duration;

  /// Where the child starts relative to its final position, e.g. a spark
  /// "bursting" outward from the flame's centre.
  final Offset burst;

  @override
  State<ScaleIn> createState() => _ScaleInState();
}

class _ScaleInState extends State<ScaleIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _curve =
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return widget.child;
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) {
        final double t = _curve.value;
        return Opacity(
          opacity: _controller.value,
          child: Transform.translate(
            offset: widget.burst * (1 - t),
            child: Transform.scale(
              scale: widget.begin + (1 - widget.begin) * t,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
