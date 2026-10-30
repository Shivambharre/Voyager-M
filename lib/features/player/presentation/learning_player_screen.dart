import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/brutalist_components.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/media/playback_controller.dart';
import '../../../core/media/playback_state.dart';
import '../../../core/media/video_models.dart';
import '../../../core/media/video_source_adapter.dart';
import '../../../features/history/domain/recent_watch_entry.dart';
import '../../../features/history/domain/recent_watch_history_repository.dart';
import '../../../features/library/domain/learning_content.dart';
import '../../../features/library/domain/learning_library_repository.dart';
import '../../../features/notes/domain/notes_repository.dart';
import '../../../features/notes/domain/study_note.dart';

class LearningPlayerScreen extends StatefulWidget {
  const LearningPlayerScreen({
    this.playbackController,
    this.libraryRepository,
    this.notesRepository,
    this.recentWatchHistoryRepository,
    this.initialSourceUrl,
    super.key,
  });

  final PlaybackController? playbackController;
  final LearningLibraryRepository? libraryRepository;
  final NotesRepository? notesRepository;
  final RecentWatchHistoryRepository? recentWatchHistoryRepository;
  final String? initialSourceUrl;

  @override
  State<LearningPlayerScreen> createState() => _LearningPlayerScreenState();
}

class _LearningPlayerScreenState extends State<LearningPlayerScreen> {
  final _urlController = TextEditingController();
  final _noteController = TextEditingController();
  late final PlaybackController _playbackController;
  late final LearningLibraryRepository _libraryRepository;
  late final NotesRepository _notesRepository;
  late final RecentWatchHistoryRepository _recentWatchHistoryRepository;
  late final StreamSubscription<PlayerSnapshot> _snapshotSubscription;
  Timer? _controlsHideTimer;
  PlayerSnapshot _snapshot = const PlayerSnapshot.initial();
  VideoInfo? _video;
  PlaylistInfo? _playlist;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isSaved = false;
  bool _isPlaylistSaved = false;
  bool _isSavingPlaylist = false;
  bool _isFullscreen = false;
  bool _controlsVisible = true;

  @override
  void initState() {
    super.initState();
    _playbackController =
        widget.playbackController ?? serviceLocator<PlaybackController>();
    _libraryRepository =
        widget.libraryRepository ?? serviceLocator<LearningLibraryRepository>();
    _notesRepository =
        widget.notesRepository ?? serviceLocator<NotesRepository>();
    _recentWatchHistoryRepository =
        widget.recentWatchHistoryRepository ??
        serviceLocator<RecentWatchHistoryRepository>();
    if (widget.initialSourceUrl case final sourceUrl?) {
      _urlController.text = sourceUrl;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_loadSource());
      });
    }
    _snapshot = _playbackController.snapshot;
    _snapshotSubscription = _playbackController.snapshots.listen(
      _handleSnapshot,
    );
  }

  @override
  void dispose() {
    _controlsHideTimer?.cancel();
    if (_isFullscreen) unawaited(_restoreSystemUi());
    _urlController.dispose();
    _noteController.dispose();
    unawaited(_snapshotSubscription.cancel());
    unawaited(_playbackController.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasMedia = _video != null && _snapshot.status != PlayerStatus.error;
    return PopScope<void>(
      canPop: !_isFullscreen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isFullscreen) unawaited(_toggleFullscreen(false));
      },
      child: _isFullscreen
          ? _buildFullscreenScaffold(hasMedia)
          : Scaffold(
              appBar: AppBar(
                title: const Text('FOCUSED STUDY'),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(
                    DesignTokens.borderStrong,
                  ),
                  child: Container(
                    height: DesignTokens.borderStrong,
                    color: context.outlineColor,
                  ),
                ),
              ),
              body: ListView(
                padding: const EdgeInsets.all(DesignTokens.space4),
                children: [
                  _buildVideoWindow(hasMedia),
                  if (_video case final video?) ...[
                    const SizedBox(height: DesignTokens.space3),
                    _buildVideoDetails(video),
                    const SizedBox(height: DesignTokens.space3),
                    Wrap(
                      spacing: DesignTokens.space2,
                      runSpacing: DesignTokens.space2,
                      alignment: WrapAlignment.center,
                      children: [
                        BrutalistButton(
                          label: 'Add note',
                          icon: Icons.edit_note,
                          secondary: true,
                          onPressed: () => unawaited(_addTimestampedNote()),
                        ),
                        BrutalistButton(
                          label: _isSaved ? 'Saved moment' : 'Save moment',
                          icon: _isSaved
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          secondary: true,
                          onPressed: () => setState(() => _isSaved = !_isSaved),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: DesignTokens.space5),
                  BrutalistCard(
                    padding: const EdgeInsets.all(DesignTokens.space3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'VIDEO OR COURSE URL',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: DesignTokens.space2),
                        BrutalistInput(
                          controller: _urlController,
                          hint: 'YouTube video, playlist, or MIT OCW URL',
                          minLines: 1,
                          maxLines: 1,
                        ),
                        const SizedBox(height: DesignTokens.space3),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: BrutalistButton(
                            label: _isLoading ? 'Loading' : 'Load video',
                            icon: _isLoading
                                ? Icons.hourglass_top
                                : Icons.play_arrow,
                            onPressed: _isLoading
                                ? null
                                : () => unawaited(_loadSource()),
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: DesignTokens.space2),
                          Text(
                            _errorMessage!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                        ],
                        if (_snapshot.errorMessage != null) ...[
                          const SizedBox(height: DesignTokens.space2),
                          Text(
                            'Playback failed. Reload the lecture to refresh its stream.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_playlist case final playlist?) ...[
                    const SizedBox(height: DesignTokens.space4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            playlist.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        BrutalistButton(
                          key: const Key('save-playlist-button'),
                          label: _isSavingPlaylist
                              ? 'Saving playlist'
                              : _isPlaylistSaved
                              ? 'Playlist saved'
                              : 'Save playlist',
                          icon: _isPlaylistSaved
                              ? Icons.check
                              : Icons.playlist_add,
                          secondary: true,
                          onPressed: _isSavingPlaylist || _isPlaylistSaved
                              ? null
                              : () => unawaited(_savePlaylist(playlist)),
                        ),
                      ],
                    ),
                    if (playlist.author case final author?
                        when author.isNotEmpty)
                      Text(
                        author,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    const SizedBox(height: DesignTokens.space2),
                    for (final entry in playlist.entries)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: SizedBox(
                          width: 34,
                          child: Center(child: Text('${entry.position + 1}')),
                        ),
                        title: Text(
                          entry.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: entry.duration == null
                            ? null
                            : Text(_formatTime(entry.duration!)),
                        trailing: const Icon(Icons.play_arrow),
                        onTap: _isLoading
                            ? null
                            : () => unawaited(_selectLecture(entry)),
                      ),
                  ],
                  const SizedBox(height: DesignTokens.space6),
                  const BrutalistSectionHeader(title: 'Notes for this lesson'),
                  const SizedBox(height: DesignTokens.space3),
                  BrutalistInput(
                    controller: _noteController,
                    hint: 'Write a note at this moment...',
                    minLines: 2,
                    maxLines: 4,
                  ),
                  const SizedBox(height: DesignTokens.space2),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: BrutalistButton(
                      key: const Key('save-player-note-button'),
                      label: 'Save note',
                      icon: Icons.save_outlined,
                      onPressed: () => unawaited(_saveNote()),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildVideoWindow(bool hasMedia) {
    return AspectRatio(
      key: const Key('player-video-window'),
      aspectRatio: 16 / 9,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          border: Border.all(color: context.outlineColor, width: 3),
          boxShadow: [
            BoxShadow(
              color: context.hardShadowColor,
              offset: const Offset(
                DesignTokens.shadowSmall,
                DesignTokens.shadowSmall,
              ),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasMedia)
              _playbackController.buildSurface()
            else
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.ondemand_video, color: Colors.white, size: 48),
                    SizedBox(height: DesignTokens.space2),
                    Text(
                      'YOUTUBE PLAYER',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            if (hasMedia)
              Positioned.fill(
                child: _buildInteractiveControls(fullscreen: false),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullscreenScaffold(bool hasMedia) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (hasMedia)
            _playbackController.buildSurface()
          else
            const Center(
              child: Icon(Icons.ondemand_video, color: Colors.white, size: 56),
            ),
          SafeArea(child: _buildInteractiveControls(fullscreen: true)),
        ],
      ),
    );
  }

  Widget _buildInteractiveControls({required bool fullscreen}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleControlsVisibility,
      child: Listener(
        onPointerDown: (_) => _scheduleControlsHide(),
        child: AnimatedOpacity(
          key: const Key('player-controls-overlay'),
          opacity: _controlsVisible ? 1 : 0,
          duration: const Duration(milliseconds: 250),
          child: IgnorePointer(
            ignoring: !_controlsVisible,
            child: _buildVideoControls(fullscreen: fullscreen),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoControls({required bool fullscreen}) {
    final compact = !fullscreen && MediaQuery.sizeOf(context).width < 500;
    final position = _snapshot.position;
    final duration = _snapshot.duration;
    final maxSeconds = duration.inSeconds;
    final sliderMax = maxSeconds > 0 ? maxSeconds.toDouble() : 1.0;
    final sliderValue = maxSeconds > 0
        ? position.inSeconds.clamp(0, maxSeconds).toDouble()
        : 0.0;
    final isPlaying = _snapshot.status == PlayerStatus.playing;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black54, Colors.transparent, Colors.black87],
          stops: [0, 0.38, 1],
        ),
      ),
      child: Column(
        children: [
          Align(
            alignment: fullscreen ? Alignment.topLeft : Alignment.topRight,
            child: fullscreen
                ? IconButton(
                    tooltip: 'Exit fullscreen',
                    color: Colors.white,
                    onPressed: () => unawaited(_toggleFullscreen(false)),
                    constraints: const BoxConstraints.tightFor(
                      width: 40,
                      height: 40,
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.arrow_back, size: 24),
                  )
                : IconButton(
                    tooltip: 'Enter fullscreen',
                    color: Colors.white,
                    onPressed: () => unawaited(_toggleFullscreen(true)),
                    constraints: compact
                        ? const BoxConstraints.tightFor(width: 36, height: 36)
                        : null,
                    padding: compact ? EdgeInsets.zero : null,
                    visualDensity: compact
                        ? VisualDensity.compact
                        : VisualDensity.standard,
                    icon: const Icon(Icons.fullscreen),
                  ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Seek back ten seconds',
                color: Colors.white,
                constraints: compact
                    ? const BoxConstraints.tightFor(width: 40, height: 40)
                    : null,
                padding: compact ? EdgeInsets.zero : null,
                visualDensity: compact
                    ? VisualDensity.compact
                    : VisualDensity.standard,
                onPressed: maxSeconds == 0
                    ? null
                    : () => unawaited(_seekBy(-10)),
                icon: Icon(Icons.replay_10, size: compact ? 26 : 32),
              ),
              IconButton(
                tooltip: isPlaying ? 'Pause' : 'Play',
                color: Colors.white,
                constraints: compact
                    ? const BoxConstraints.tightFor(width: 44, height: 44)
                    : null,
                padding: compact ? EdgeInsets.zero : null,
                visualDensity: compact
                    ? VisualDensity.compact
                    : VisualDensity.standard,
                onPressed: () => unawaited(_togglePlayback(isPlaying)),
                icon: Icon(
                  isPlaying ? Icons.pause_circle : Icons.play_circle,
                  size: compact ? 42 : 54,
                ),
              ),
              IconButton(
                tooltip: 'Seek forward ten seconds',
                color: Colors.white,
                constraints: compact
                    ? const BoxConstraints.tightFor(width: 40, height: 40)
                    : null,
                padding: compact ? EdgeInsets.zero : null,
                visualDensity: compact
                    ? VisualDensity.compact
                    : VisualDensity.standard,
                onPressed: maxSeconds == 0
                    ? null
                    : () => unawaited(_seekBy(10)),
                icon: Icon(Icons.forward_10, size: compact ? 26 : 32),
              ),
            ],
          ),
          const Spacer(),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.space3,
              vertical: compact ? 0 : DesignTokens.space2,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    activeTrackColor: const Color(0xFFFF0033),
                    inactiveTrackColor: Colors.white38,
                    thumbColor: const Color(0xFFFF0033),
                    overlayColor: const Color(0x33FF0033),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 4,
                    ),
                  ),
                  child: SizedBox(
                    height: compact ? 24 : null,
                    child: Slider(
                      key: const Key('player-seek-slider'),
                      value: sliderValue,
                      max: sliderMax,
                      onChanged: maxSeconds == 0
                          ? null
                          : (seconds) => unawaited(
                              _playbackController.seekTo(
                                Duration(seconds: seconds.round()),
                              ),
                            ),
                    ),
                  ),
                ),
                if (compact) ...[
                  Row(
                    children: [
                      Text(
                        '${_formatTime(position)} / ${_formatTime(duration)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      _buildSpeedButton(compact: true),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildQualitySelector(),
                  ),
                ] else
                  Row(
                    children: [
                      Text(
                        '${_formatTime(position)} / ${_formatTime(duration)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      _buildQualitySelector(),
                      const SizedBox(width: DesignTokens.space2),
                      _buildSpeedButton(compact: false),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualitySelector() {
    final streams = _playbackController.availableStreams;
    final selected = _playbackController.selectedStream;
    if (streams.isEmpty || selected == null) return const SizedBox.shrink();
    return DropdownButtonHideUnderline(
      child: DropdownButton<MediaStreamInfo>(
        key: const Key('player-quality-selector'),
        value: selected,
        dropdownColor: Colors.black87,
        iconEnabledColor: Colors.white,
        style: const TextStyle(color: Colors.white, fontSize: 12),
        isDense: true,
        onChanged: _isLoading
            ? null
            : (stream) {
                if (stream != null) unawaited(_selectQuality(stream));
              },
        items: [
          for (final stream in streams)
            DropdownMenuItem(
              value: stream,
              child: Text(
                (stream.resolutionHeight ?? 0) > 0
                    ? '${stream.resolutionHeight}p'
                    : 'Auto',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSpeedButton({required bool compact}) {
    return TextButton(
      style: compact
          ? TextButton.styleFrom(
              minimumSize: const Size(40, 32),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            )
          : null,
      onPressed: () => unawaited(_cycleSpeed()),
      child: Text(
        '${_snapshot.playbackSpeed.toStringAsFixed(2)}×',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildVideoDetails(VideoInfo video) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(video.title, style: Theme.of(context).textTheme.titleLarge),
        if (video.author case final author? when author.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.space1),
          Text(
            author,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: context.mutedColor),
          ),
        ],
      ],
    );
  }

  Future<void> _selectQuality(MediaStreamInfo stream) async {
    setState(() => _isLoading = true);
    try {
      await _playbackController.selectStream(stream);
      if (mounted) setState(() => _errorMessage = null);
    } on Object {
      if (mounted) {
        setState(() => _errorMessage = 'Could not change video quality.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleSnapshot(PlayerSnapshot snapshot) {
    if (!mounted) return;
    final wasPlaying = _snapshot.status == PlayerStatus.playing;
    setState(() => _snapshot = snapshot);
    if (snapshot.status == PlayerStatus.playing && !wasPlaying) {
      _showControls();
    } else {
      if (snapshot.status != PlayerStatus.playing) {
        _controlsHideTimer?.cancel();
        if (!_controlsVisible) setState(() => _controlsVisible = true);
      }
    }
  }

  Future<void> _togglePlayback(bool isPlaying) async {
    if (isPlaying) {
      await _playbackController.pause();
      _controlsHideTimer?.cancel();
      if (mounted && !_controlsVisible) {
        setState(() => _controlsVisible = true);
      }
      return;
    }
    await _playbackController.play();
    _showControls();
  }

  void _toggleControlsVisibility() {
    if (_controlsVisible) {
      _controlsHideTimer?.cancel();
      setState(() => _controlsVisible = false);
    } else {
      _showControls();
    }
  }

  void _showControls() {
    if (!_controlsVisible && mounted) {
      setState(() => _controlsVisible = true);
    }
    _scheduleControlsHide();
  }

  void _scheduleControlsHide() {
    _controlsHideTimer?.cancel();
    if (!mounted || _snapshot.status != PlayerStatus.playing) return;
    _controlsHideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _snapshot.status == PlayerStatus.playing) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  Future<void> _toggleFullscreen(bool enabled) async {
    if (_isFullscreen == enabled) return;
    _controlsHideTimer?.cancel();
    setState(() => _isFullscreen = enabled);
    _showControls();
    if (enabled) {
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await _restoreSystemUi();
    }
  }

  Future<void> _restoreSystemUi() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _savePlaylist(PlaylistInfo playlist) async {
    setState(() => _isSavingPlaylist = true);
    try {
      await _libraryRepository.savePlaylist(
        LearningPlaylist(
          id: playlist.id,
          sourceId: playlist.id,
          sourceUrl: playlist.url.toString(),
          title: playlist.title,
          creator: playlist.author ?? '',
          description: playlist.description ?? '',
        ),
      );
      final videosById = <String, LearningVideo>{};
      for (final entry in playlist.entries) {
        videosById.putIfAbsent(
          entry.videoId,
          () => LearningVideo(
            id: entry.videoId,
            sourceId: entry.videoId,
            sourceUrl: entry.url.toString(),
            title: entry.title,
            creator: playlist.author ?? '',
            durationSeconds: entry.duration?.inSeconds ?? 0,
            thumbnailUrl: entry.thumbnailUrl?.toString(),
          ),
        );
      }
      for (final video in videosById.values) {
        await _libraryRepository.saveVideo(video);
      }
      await _libraryRepository.savePlaylistEntries(playlist.id, [
        for (final entry in playlist.entries)
          PlaylistEntry(
            playlistId: playlist.id,
            videoId: entry.videoId,
            position: entry.position,
          ),
      ]);
      if (mounted) setState(() => _isPlaylistSaved = true);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save this playlist.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingPlaylist = false);
    }
  }

  Future<void> _saveNote() async {
    final content = _noteController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write a note before saving.')),
      );
      return;
    }
    final now = DateTime.now();
    try {
      final timestamp = _video == null
          ? null
          : (await _playbackController.currentPosition).inSeconds;
      await _notesRepository.saveNote(
        StudyNote(
          id: now.microsecondsSinceEpoch.toString(),
          content: content,
          videoId: _video?.id,
          timestampSeconds: timestamp,
          createdAt: now,
          updatedAt: now,
        ),
      );
      if (!mounted) return;
      _noteController.clear();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Note saved.')));
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save this note.')),
      );
    }
  }

  Future<void> _loadSource() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _video = null;
      _playlist = null;
      _isPlaylistSaved = false;
    });
    try {
      await _playbackController.load(_urlController.text);
      if (!mounted) return;
      setState(() {
        _video = _playbackController.currentVideo;
        _playlist = _playbackController.currentPlaylist;
        _isSaved = false;
        _isPlaylistSaved = false;
      });
      if (_playbackController.currentVideo case final video?) {
        await _recordWatchHistory(video);
      }
    } on VideoSourceException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } on Object {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Could not load this lesson. Check the URL and network.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectLecture(PlaylistEntryInfo entry) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _video = null;
    });
    try {
      await _playbackController.selectLecture(entry);
      if (!mounted) return;
      setState(() {
        _video = _playbackController.currentVideo;
        _isSaved = false;
      });
      if (_playbackController.currentVideo case final video?) {
        await _recordWatchHistory(video);
      }
    } on VideoSourceException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } on Object {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Could not load this lecture. Try selecting it again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _seekBy(int offsetSeconds) async {
    final target = (_snapshot.position.inSeconds + offsetSeconds).clamp(
      0,
      _snapshot.duration.inSeconds,
    );
    await _playbackController.seekTo(Duration(seconds: target));
  }

  Future<void> _recordWatchHistory(VideoInfo video) async {
    try {
      await _recentWatchHistoryRepository.record(
        RecentWatchEntry(
          videoId: video.id,
          sourceUrl: video.url.toString(),
          title: video.title,
          creator: video.author ?? '',
          durationSeconds: video.duration.inSeconds,
          thumbnailUrl: video.thumbnailUrl?.toString(),
          watchedAt: DateTime.now(),
        ),
      );
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update watch history.')),
        );
      }
    }
  }

  Future<void> _cycleSpeed() async {
    const rates = [1.0, 1.25, 1.5, 2.0];
    final index = rates.indexOf(_snapshot.playbackSpeed);
    await _playbackController.setPlaybackSpeed(
      rates[(index + 1) % rates.length],
    );
  }

  Future<void> _addTimestampedNote() async {
    final position = await _playbackController.currentPosition;
    if (!mounted) return;
    final prefix = _noteController.text.isEmpty ? '' : '\n';
    _noteController.text =
        '${_noteController.text}$prefix${_formatTime(position)} ';
    _noteController.selection = TextSelection.collapsed(
      offset: _noteController.text.length,
    );
  }

  String _formatTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0
        ? '$hours:$minutes:$seconds'
        : '${duration.inMinutes}:$seconds';
  }
}
