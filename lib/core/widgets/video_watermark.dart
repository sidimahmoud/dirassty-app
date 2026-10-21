import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../features/student/application/student_providers.dart';
import '../models/student.dart';

/// Anti-leak watermark over course videos: the student's name flashes for
/// a few seconds at a random spot, at random moments of *playback* time
/// (pauses don't count). Rare and brief so it doesn't get in the way of
/// watching, but any screen recording or filmed copy shows who leaked it.
/// Same timing as the web (apps/web/components/shared/WatermarkedVideo.tsx).
///
/// Mounted as Chewie's `overlay`, so it stays on in fullscreen too.
/// Shows nothing outside student mode (no student name to show).
class VideoWatermark extends ConsumerStatefulWidget {
  const VideoWatermark({required this.controller, super.key});

  final VideoPlayerController controller;

  @override
  ConsumerState<VideoWatermark> createState() => _VideoWatermarkState();
}

class _VideoWatermarkState extends ConsumerState<VideoWatermark> {
  static const int _visibleSeconds = 4;

  final Random _random = Random();
  Timer? _ticker;
  int _playedSeconds = 0;

  /// First appearance after 15–45 s of playback, then every 60–150 s.
  late int _nextShowAt = 15 + _random.nextInt(31);
  int _hideAt = 0;
  Alignment _alignment = Alignment.topLeft;

  bool get _visible => _playedSeconds < _hideAt;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted || !widget.controller.value.isPlaying) return;
    _playedSeconds++;
    if (_playedSeconds >= _nextShowAt) {
      setState(() {
        // Anywhere but hugging the edges, where it'd be easy to crop out.
        _alignment = Alignment(
          _random.nextDouble() * 1.6 - 0.8,
          _random.nextDouble() * 1.6 - 0.8,
        );
        _hideAt = _playedSeconds + _visibleSeconds;
        _nextShowAt = _playedSeconds + 60 + _random.nextInt(91);
      });
    } else if (_playedSeconds == _hideAt) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Student? student = ref.watch(currentStudentProvider).valueOrNull;
    if (student == null) return const SizedBox.shrink();
    final String? username = student.username;
    final String label = username == null || username.isEmpty
        ? student.name
        : '${student.name} · @$username';

    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 500),
        child: Align(
          alignment: _alignment,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
