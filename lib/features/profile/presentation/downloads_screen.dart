import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/video_body.dart';
import '../../../core/offline/offline_video_store.dart';
import '../../../core/offline/offline_videos_controller.dart';
import '../../../core/theme/dirassty_theme.dart';
import '../../../core/widgets/course_video_player.dart';
import '../../../core/widgets/dirassty/dirassty_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../student/application/student_providers.dart';

/// Every video saved on this device, playable with no connection at all —
/// reads nothing from the network (only the disk-backed
/// [offlineVideosControllerProvider]), which is why the router lands here
/// when a signed-in student opens the app offline.
///
/// Deviations from Downloads.dc.html (TODO): no free-space figure or
/// Wi-Fi-only switch (needs device-storage / connectivity plugins), and
/// videos aren't grouped by subject (a download only records its lesson).
///
/// design_handoff Downloads.dc.html · DESIGN_SPEC §4 "Downloads".
class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  static const String path = '/profile/downloads';
  static const String name = 'downloads';

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  String? _playingUrl;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final OfflineVideosState offline =
        ref.watch(offlineVideosControllerProvider);
    final List<OfflineVideo> videos = offline.downloads.values.toList()
      ..sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
    final OfflineVideo? playing = offline.hasAccess
        ? videos.where((v) => v.url == _playingUrl).firstOrNull
        : null;
    final int totalBytes = videos.fold(0, (sum, v) => sum + v.sizeBytes);

    return Scaffold(
      backgroundColor: DirasstyColors.background,
      appBar: AppBar(
        actions: [
          if (videos.isNotEmpty)
            IconButton(
              tooltip: l10n.deleteAll,
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: _confirmDeleteAll,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.only(bottom: DirasstySpace.xl),
        children: [
          if (playing != null)
            CourseVideoPlayer(
              key: ValueKey(playing.url),
              video: VideoBody(
                  url: playing.url,
                  durationSec: playing.durationSec,
                  type: 'filmed',
                  title: playing.title),
              color: DirasstyColors.teal,
              isArabic: context.isArabicLocale,
              borderRadius: BorderRadius.zero,
              showDownloadControl: false,
              autoPlay: true,
            ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
                DirasstySpace.screen, DirasstySpace.sm, DirasstySpace.screen, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.myDownloads, style: type.title),
                const SizedBox(height: DirasstySpace.lg),
                if (videos.isEmpty)
                  EmptyState(
                      icon: Icons.download_for_offline_outlined,
                      title: l10n.noDownloads,
                      message: l10n.noDownloadsBody)
                else ...[
                  DirasstyCard(
                    child: Row(
                      children: [
                        const Icon(Icons.sd_storage_outlined,
                            color: DirasstyColors.teal),
                        const SizedBox(width: DirasstySpace.md),
                        Expanded(
                            child: Text(
                                l10n.storageUsed(_formatSize(totalBytes)),
                                style: type.subheading.copyWith(fontSize: 14))),
                        Text(
                            l10n.videosCountSize(
                                videos.length, _formatSize(totalBytes)),
                            style: type.label),
                      ],
                    ),
                  ),
                  if (!offline.hasAccess) ...[
                    const SizedBox(height: DirasstySpace.lg),
                    Container(
                      padding: const EdgeInsetsDirectional.all(DirasstySpace.lg),
                      decoration: const BoxDecoration(
                          color: DirasstyColors.goldTint,
                          borderRadius: DirasstyRadius.cardR),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.lock_clock_outlined,
                                  color: DirasstyColors.goldStroke),
                              const SizedBox(width: DirasstySpace.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l10n.offlineExpired,
                                        style: type.subheading
                                            .copyWith(fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text(l10n.offlineExpiredBody,
                                        style: type.label.copyWith(
                                            fontWeight: FontWeight.w400)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: DirasstySpace.md),
                          DirasstyButton(
                            label: l10n.reconnect,
                            icon: Icons.refresh_rounded,
                            variant: DirasstyButtonVariant.ink,
                            compact: true,
                            // Refetching the student re-runs the subscription
                            // check, which renews offline access if the plan
                            // is still active.
                            onPressed: () =>
                                ref.invalidate(currentStudentProvider),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: DirasstySpace.lg),
                  Text(l10n.myVideos, style: type.subheading),
                  const SizedBox(height: DirasstySpace.md),
                  Container(
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
                          for (final (int i, OfflineVideo v)
                              in videos.indexed) ...[
                            if (i > 0) const Divider(height: 1),
                            _DownloadRow(
                              video: v,
                              playing: v.url == playing?.url,
                              enabled: offline.hasAccess,
                              onPlay: () => setState(() => _playingUrl = v.url),
                              onDelete: () async {
                                if (_playingUrl == v.url)
                                  setState(() => _playingUrl = null);
                                await ref
                                    .read(offlineVideosControllerProvider
                                        .notifier)
                                    .delete(v.url);
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: DirasstySpace.lg),
                  Text(l10n.downloadsFooter,
                      style: type.label.copyWith(fontWeight: FontWeight.w400)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAll() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool? confirmed = await showDirasstyDialog<bool>(
      context,
      icon: Icons.delete_outline_rounded,
      iconBackground: DirasstyColors.errorTint,
      iconColor: DirasstyColors.error,
      title: l10n.deleteAllDownloadsConfirm,
      actions: [
        DirasstyDialogAction(
            label: l10n.delete,
            value: true,
            variant: DirasstyButtonVariant.danger),
        DirasstyDialogAction(
            label: l10n.cancel,
            value: false,
            variant: DirasstyButtonVariant.quiet),
      ],
    );
    if (confirmed != true || !mounted) return;
    setState(() => _playingUrl = null);
    await ref.read(offlineVideosControllerProvider.notifier).deleteAll();
  }
}

String _formatSize(int bytes) {
  final double mb = bytes / (1024 * 1024);
  return mb >= 1024
      ? '${(mb / 1024).toStringAsFixed(1)} Go'
      : '${mb.toStringAsFixed(0)} Mo';
}

class _DownloadRow extends StatelessWidget {
  const _DownloadRow({
    required this.video,
    required this.playing,
    required this.enabled,
    required this.onPlay,
    required this.onDelete,
  });

  final OfflineVideo video;
  final bool playing;
  final bool enabled;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final DirasstyType type = context.dirasstyType;
    final int m = video.durationSec ~/ 60;
    final int s = video.durationSec % 60;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: enabled ? onPlay : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
                DirasstySpace.lg, DirasstySpace.md, DirasstySpace.xs, DirasstySpace.md),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 45,
                  decoration: const BoxDecoration(
                      color: DirasstyColors.ink, borderRadius: DirasstyRadius.smallR),
                  child: Icon(
                    enabled
                        ? (playing
                            ? Icons.graphic_eq_rounded
                            : Icons.play_arrow_rounded)
                        : Icons.lock_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: DirasstySpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(video.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: type.subheading.copyWith(fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (video.durationSec > 0)
                            '$m:${s.toString().padLeft(2, '0')}',
                          _formatSize(video.sizeBytes),
                        ].join(' · '),
                        style: type.label.copyWith(fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.delete,
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: DirasstyColors.textMuted),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
