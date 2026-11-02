import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design/brutalist_components.dart';
import '../../../core/design/design_tokens.dart';
import '../domain/learning_content.dart';
import '../domain/learning_library_repository.dart';
import '../../progress/domain/learning_progress.dart';
import '../../progress/domain/progress_repository.dart';

class PlaylistDetailPage extends StatefulWidget {
  const PlaylistDetailPage({
    required this.playlist,
    required this.libraryRepository,
    required this.progressRepository,
    required this.onOpenVideo,
    super.key,
  });

  final LearningPlaylist playlist;
  final LearningLibraryRepository libraryRepository;
  final ProgressRepository progressRepository;
  final Future<void> Function({String? sourceUrl, Duration? initialPosition})
  onOpenVideo;

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  late Future<List<_PlaylistVideo>> _videos;
  bool _savingOrder = false;

  @override
  void initState() {
    super.initState();
    _videos = _loadVideos();
  }

  Future<List<_PlaylistVideo>> _loadVideos() async {
    final entries = await widget.libraryRepository.getPlaylistEntries(
      widget.playlist.id,
    );
    return Future.wait(
      entries.map((entry) async {
        final video = await widget.libraryRepository.getVideo(entry.videoId);
        final progress = video == null
            ? null
            : await widget.progressRepository.getProgress(video.id);
        return _PlaylistVideo(entry: entry, video: video, progress: progress);
      }),
    );
  }

  void _reload() {
    setState(() {
      _videos = _loadVideos();
    });
  }

  Future<void> _openVideo(_PlaylistVideo item) async {
    final video = item.video;
    if (video == null) return;
    await widget.onOpenVideo(sourceUrl: video.sourceUrl);
    if (mounted) _reload();
  }

  Future<void> _reorder(
    List<_PlaylistVideo> currentVideos,
    int oldIndex,
    int newIndex,
  ) async {
    if (_savingOrder || oldIndex == newIndex) return;
    final reordered = List<_PlaylistVideo>.of(currentVideos);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    final entries = [
      for (var index = 0; index < reordered.length; index++)
        PlaylistEntry(
          playlistId: widget.playlist.id,
          videoId: reordered[index].entry.videoId,
          position: index,
        ),
    ];

    setState(() => _savingOrder = true);
    try {
      await widget.libraryRepository.savePlaylistEntries(
        widget.playlist.id,
        entries,
      );
      if (!mounted) return;
      setState(() {
        _videos = Future.value(reordered);
        _savingOrder = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _savingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the new video order.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.playlist.title)),
      body: FutureBuilder<List<_PlaylistVideo>>(
        future: _videos,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(DesignTokens.space4),
              child: BrutalistErrorState(
                message: 'This library could not be opened.',
                onRetry: _reload,
              ),
            );
          }
          if (!snapshot.hasData) return const BrutalistLoadingState();

          final videos = snapshot.data!;
          final completedCount = videos
              .where((item) => item.progress?.isCompleted ?? false)
              .length;
          final progress = videos.isEmpty
              ? 0.0
              : completedCount / videos.length;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.space4,
                  DesignTokens.space3,
                  DesignTokens.space4,
                  DesignTokens.space2,
                ),
                child: BrutalistCard(
                  padding: const EdgeInsets.all(DesignTokens.space3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${videos.length} videos · $completedCount completed',
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: DesignTokens.space2),
                      LinearProgressIndicator(
                        key: const Key('playlist-overall-progress'),
                        value: progress,
                        minHeight: 5,
                        color: DesignTokens.romanOlive,
                        backgroundColor: context.raisedColor,
                      ),
                      const SizedBox(height: DesignTokens.space1),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${(progress * 100).round()}%',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: videos.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(DesignTokens.space4),
                        child: BrutalistEmptyState(
                          title: 'No videos yet',
                          message:
                              'Videos saved to this library will appear here.',
                        ),
                      )
                    : IgnorePointer(
                        ignoring: _savingOrder,
                        child: ReorderableListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            DesignTokens.space4,
                            DesignTokens.space2,
                            DesignTokens.space4,
                            DesignTokens.space4,
                          ),
                          buildDefaultDragHandles: false,
                          itemCount: videos.length,
                          onReorderItem: (oldIndex, newIndex) =>
                              unawaited(_reorder(videos, oldIndex, newIndex)),
                          itemBuilder: (context, index) {
                            final item = videos[index];
                            return _PlaylistVideoRow(
                              key: ValueKey(item.entry.videoId),
                              item: item,
                              index: index,
                              onTap: () => unawaited(_openVideo(item)),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PlaylistVideoRow extends StatelessWidget {
  const _PlaylistVideoRow({
    required this.item,
    required this.index,
    required this.onTap,
    super.key,
  });

  final _PlaylistVideo item;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final video = item.video;
    final totalSeconds =
        item.progress?.durationSeconds != null &&
            item.progress!.durationSeconds > 0
        ? item.progress!.durationSeconds
        : video?.durationSeconds ?? 0;
    final watchedSeconds = (item.progress?.positionSeconds ?? 0)
        .clamp(0, totalSeconds)
        .toInt();
    final isCompleted = item.progress?.isCompleted ?? false;
    final progress = totalSeconds == 0 ? 0.0 : watchedSeconds / totalSeconds;
    final foreground = context.isDarkMode
        ? const Color(0xFF8FBC8F)
        : const Color(0xFF2E7D32);

    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: DesignTokens.space2),
      child: BrutalistCard(
        padding: const EdgeInsets.all(DesignTokens.space3),
        onTap: video == null ? null : onTap,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radius / 2),
              child: SizedBox(
                width: 84,
                height: 58,
                child: video?.thumbnailUrl == null
                    ? _ThumbnailPlaceholder()
                    : Image.network(
                        video!.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _ThumbnailPlaceholder(),
                      ),
              ),
            ),
            const SizedBox(width: DesignTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video?.title ?? 'Video unavailable',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: DesignTokens.space1),
                  Text(
                    '${_formatDuration(watchedSeconds)} / '
                    '${_formatDuration(totalSeconds)}',
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: context.mutedColor),
                  ),
                  if (!isCompleted) ...[
                    const SizedBox(height: DesignTokens.space2),
                    LinearProgressIndicator(
                      key: Key('video-progress-${item.entry.videoId}'),
                      value: progress,
                      minHeight: 4,
                      color: DesignTokens.romanOlive,
                      backgroundColor: context.raisedColor,
                    ),
                  ],
                ],
              ),
            ),
            if (isCompleted)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space2,
                ),
                child: Icon(
                  Icons.done_all_rounded,
                  key: Key('completed-video-${item.entry.videoId}'),
                  color: foreground,
                  size: 20,
                ),
              ),
            ReorderableDragStartListener(
              key: Key('reorder-playlist-video-${item.entry.videoId}'),
              index: index,
              child: const Tooltip(
                message: 'Reorder video',
                child: Padding(
                  padding: EdgeInsets.only(left: DesignTokens.space1),
                  child: Icon(Icons.drag_handle, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistVideo {
  const _PlaylistVideo({
    required this.entry,
    required this.video,
    required this.progress,
  });

  final PlaylistEntry entry;
  final LearningVideo? video;
  final LearningProgress? progress;
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.raisedColor,
    child: Icon(Icons.ondemand_video_outlined, color: context.mutedColor),
  );
}

String _formatDuration(int seconds) {
  final duration = Duration(seconds: seconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final remainingSeconds = duration.inSeconds
      .remainder(60)
      .toString()
      .padLeft(2, '0');
  return hours > 0
      ? '$hours:$minutes:$remainingSeconds'
      : '${duration.inMinutes}:$remainingSeconds';
}
