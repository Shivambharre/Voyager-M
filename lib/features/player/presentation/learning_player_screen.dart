import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/brutalist_components.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/media/playback_controller.dart';
import '../../../core/media/player_engine.dart';
import '../../../core/media/video_models.dart';
import '../../../core/media/video_source_adapter.dart';
import '../../../features/library/domain/learning_content.dart';
import '../../../features/library/domain/learning_library_repository.dart';
import '../../../features/notes/domain/notes_repository.dart';
import '../../../features/notes/domain/study_note.dart';

class LearningPlayerScreen extends StatefulWidget {
  const LearningPlayerScreen({
    this.playbackController,
    this.libraryRepository,
    this.notesRepository,
    this.initialSourceUrl,
    super.key,
  });

  final PlaybackController? playbackController;
  final LearningLibraryRepository? libraryRepository;
  final NotesRepository? notesRepository;
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
  late final StreamSubscription<PlayerSnapshot> _snapshotSubscription;
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
  int _seekStepSeconds = 10;
  Timer? _controlsFadeTimer;
  Timer? _holdSeekTimer;
  double? _holdRestorePlaybackSpeed;
  bool _isHoldingSeek = false;

  @override
  void initState() {
    super.initState();
    _playbackController =
        widget.playbackController ?? serviceLocator<PlaybackController>();
    _libraryRepository =
        widget.libraryRepository ?? serviceLocator<LearningLibraryRepository>();
    _notesRepository =
        widget.notesRepository ?? serviceLocator<NotesRepository>();
    if (widget.initialSourceUrl case final sourceUrl?) {
      _urlController.text = sourceUrl;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_loadSource());
      });
    }
    _snapshot = _playbackController.snapshot;
    _snapshotSubscription = _playbackController.snapshots.listen((snapshot) {
      if (mounted) setState(() => _snapshot = snapshot);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scheduleControlsFade();
    });
  }

  @override
  void dispose() {
    _controlsFadeTimer?.cancel();
    _holdSeekTimer?.cancel();
    if (_isFullscreen) unawaited(_restoreSystemUi());
    _urlController.dispose();
    _noteController.dispose();
    unawaited(_snapshotSubscription.cancel());
    unawaited(_playbackController.dispose());
    super.dispose();
  }

  void _scheduleControlsFade() {
    _controlsFadeTimer?.cancel();
    if (!_controlsVisible) return;
    _controlsFadeTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _showControls() {
    _controlsFadeTimer?.cancel();
    if (mounted) {
      setState(() => _controlsVisible = true);
    }
    _scheduleControlsFade();
  }

  void _toggleControlsVisibility() {
    if (_controlsVisible) {
      _controlsFadeTimer?.cancel();
      if (mounted) setState(() => _controlsVisible = false);
      return;
    }
    _showControls();
  }

  Future<void> _handleSkipGesture(int direction) async {
    _showControls();
    await _seekBy(direction * _seekStepSeconds);
  }

  Future<void> _beginHoldSeek(int direction) async {
    if (_isHoldingSeek) return;
    _isHoldingSeek = true;
    _holdRestorePlaybackSpeed = _snapshot.playbackSpeed;
    await _playbackController.setPlaybackSpeed(2.5);
    _holdSeekTimer?.cancel();
    _holdSeekTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      unawaited(_seekBy(direction * _seekStepSeconds));
    });
    _showControls();
  }

  Future<void> _endHoldSeek() async {
    _holdSeekTimer?.cancel();
    _holdSeekTimer = null;
    if (!_isHoldingSeek) return;
    _isHoldingSeek = false;
    final restoreSpeed = _holdRestorePlaybackSpeed ?? 1.0;
    _holdRestorePlaybackSpeed = null;
    await _playbackController.setPlaybackSpeed(restoreSpeed);
  }

  @override
  Widget build(BuildContext context) {
    final hasMedia = _video != null && _snapshot.status != PlayerStatus.error;
    final position = _snapshot.position;
    final duration = _snapshot.duration;
    final maxSeconds = duration.inSeconds;
    final isPlaying = _snapshot.status == PlayerStatus.playing;
    if (_isFullscreen) return _buildFullscreenScaffold(hasMedia);
    return Scaffold(
      appBar: AppBar(
        title: const Text('FOCUSED STUDY'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(DesignTokens.borderStrong),
          child: Container(
            height: DesignTokens.borderStrong,
            color: context.outlineColor,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.space4),
        children: [
          AspectRatio(
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
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleControlsVisibility,
                onDoubleTapDown: (details) {
                  final direction = details.localPosition.dx <
                          (MediaQuery.sizeOf(context).width / 2)
                      ? -1
                      : 1;
                  unawaited(_handleSkipGesture(direction));
                },
                onLongPressStart: (details) {
                  final direction = details.localPosition.dx <
                          (MediaQuery.sizeOf(context).width / 2)
                      ? -1
                      : 1;
                  unawaited(_beginHoldSeek(direction));
                },
                onLongPressEnd: (_) => unawaited(_endHoldSeek()),
                onLongPressCancel: () => unawaited(_endHoldSeek()),
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
                            Icon(
                              Icons.ondemand_video,
                              color: Colors.white,
                              size: 48,
                            ),
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
                    Positioned.fill(
                      child: AnimatedOpacity(
                        opacity: _controlsVisible ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: IgnorePointer(
                          ignoring: !_controlsVisible,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.38),
                                  Colors.transparent,
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.52),
                                ],
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: DesignTokens.space1,
                                  right: DesignTokens.space1,
                                  child: IconButton(
                                    tooltip: 'Enter fullscreen',
                                    color: Colors.white,
                                    onPressed: () =>
                                        unawaited(_toggleFullscreen(true)),
                                    icon: const Icon(Icons.fullscreen),
                                  ),
                                ),
                                Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Seek back',
                                        onPressed: maxSeconds == 0
                                            ? null
                                            : () => unawaited(
                                                _handleSkipGesture(
                                                  -_seekStepSeconds,
                                                ),
                                              ),
                                        color: Colors.white,
                                        icon: const Icon(Icons.replay_10, size: 28),
                                      ),
                                      const SizedBox(width: DesignTokens.space4),
                                      IconButton(
                                        tooltip: isPlaying ? 'Pause' : 'Play',
                                        onPressed: () => unawaited(
                                          isPlaying
                                              ? _playbackController.pause()
                                              : _playbackController.play(),
                                        ),
                                        color: Colors.white,
                                        icon: Icon(
                                          isPlaying ? Icons.pause : Icons.play_arrow,
                                          size: 36,
                                        ),
                                      ),
                                      const SizedBox(width: DesignTokens.space4),
                                      IconButton(
                                        tooltip: 'Seek forward',
                                        onPressed: maxSeconds == 0
                                            ? null
                                            : () => unawaited(
                                                _handleSkipGesture(
                                                  _seekStepSeconds,
                                                ),
                                              ),
                                        color: Colors.white,
                                        icon: const Icon(Icons.forward_10, size: 28),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(
                                      DesignTokens.space3,
                                      0,
                                      DesignTokens.space3,
                                      DesignTokens.space3,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Slider(
                                                value: maxSeconds > 0
                                                    ? position.inSeconds
                                                        .clamp(0, maxSeconds)
                                                        .toDouble()
                                                    : 0,
                                                max: maxSeconds > 0
                                                    ? maxSeconds.toDouble()
                                                    : 1,
                                                onChanged: maxSeconds == 0
                                                    ? null
                                                    : (seconds) => unawaited(
                                                        _playbackController.seekTo(
                                                          Duration(
                                                            seconds:
                                                                seconds.round(),
                                                          ),
                                                        ),
                                                      ),
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    _formatTime(position),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Text(
                                                    _formatTime(duration),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: DesignTokens.space2),
                                        DropdownButtonHideUnderline(
                                          child: DropdownButton<int>(
                                            value: _seekStepSeconds,
                                            dropdownColor: Colors.black87,
                                            iconEnabledColor: Colors.white,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            items: const [
                                              DropdownMenuItem(
                                                value: 5,
                                                child: Text('5s'),
                                              ),
                                              DropdownMenuItem(
                                                value: 10,
                                                child: Text('10s'),
                                              ),
                                              DropdownMenuItem(
                                                value: 15,
                                                child: Text('15s'),
                                              ),
                                              DropdownMenuItem(
                                                value: 30,
                                                child: Text('30s'),
                                              ),
                                            ],
                                            onChanged: (value) {
                                              if (value != null) {
                                                setState(
                                                  () => _seekStepSeconds = value,
                                                );
                                                _showControls();
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
                    icon: _isLoading ? Icons.hourglass_top : Icons.play_arrow,
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
                        ?.copyWith(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                if (_snapshot.errorMessage != null) ...[
                  const SizedBox(height: DesignTokens.space2),
                  Text(
                    'Playback failed. Reload the lecture to refresh its stream.',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: Theme.of(context).colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
          if (_playlist case final playlist?) ...[
            const SizedBox(height: DesignTokens.space4),
            Text(playlist.title, style: Theme.of(context).textTheme.titleLarge),
            if (playlist.author case final author? when author.isNotEmpty)
              Text(author, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: DesignTokens.space2),
            Align(
              alignment: Alignment.centerLeft,
              child: BrutalistButton(
                key: const Key('save-playlist-button'),
                label: _isSavingPlaylist
                    ? 'Saving playlist'
                    : _isPlaylistSaved
                    ? 'Playlist saved'
                    : 'Save playlist to library',
                icon: _isPlaylistSaved
                    ? Icons.bookmark
                    : Icons.bookmark_add_outlined,
                secondary: _isPlaylistSaved,
                onPressed: _isSavingPlaylist || _isPlaylistSaved
                    ? null
                    : () => unawaited(_savePlaylist(playlist)),
              ),
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
          if (_video case final video?) ...[
            const SizedBox(height: DesignTokens.space4),
            _buildVideoDetails(video),
            const SizedBox(height: DesignTokens.space3),
            _buildQualitySelector(),
            _buildPlaybackControls(),
            const SizedBox(height: DesignTokens.space4),
            Wrap(
              spacing: DesignTokens.space2,
              runSpacing: DesignTokens.space2,
              alignment: WrapAlignment.center,
              children: [
                BrutalistButton(
                  label: 'Add note at current time',
                  icon: Icons.edit_note,
                  secondary: true,
                  onPressed: () => unawaited(_addTimestampedNote()),
                ),
                BrutalistButton(
                  label: _isSaved ? 'Saved moment' : 'Save moment',
                  icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
                  secondary: true,
                  onPressed: () => setState(() => _isSaved = !_isSaved),
                ),
              ],
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
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    tooltip: 'Exit fullscreen',
                    color: Colors.white,
                    onPressed: () => unawaited(_toggleFullscreen(false)),
                    icon: const Icon(Icons.fullscreen_exit, size: 32),
                  ),
                ),
                const Spacer(),
                if (_video != null)
                  Container(
                    color: Colors.white.withValues(alpha: 0.94),
                    padding: const EdgeInsets.all(DesignTokens.space3),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildQualitySelector(),
                        _buildPlaybackControls(),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFullscreen(bool enabled) async {
    if (_isFullscreen == enabled) return;
    setState(() => _isFullscreen = enabled);
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

  Widget _buildQualitySelector() {
    final streams = _playbackController.availableStreams;
    final selected = _playbackController.selectedStream;
    if (streams.isEmpty || selected == null) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text('QUALITY'),
        const SizedBox(width: DesignTokens.space2),
        Semantics(
          label: 'Select video quality',
          child: DropdownButtonHideUnderline(
            child: DropdownButton<MediaStreamInfo>(
              key: const Key('player-quality-selector'),
              value: selected,
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
                    child: Text(_qualityLabel(stream)),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _qualityLabel(MediaStreamInfo stream) {
    final height = stream.resolutionHeight;
    return '${height == null || height == 0 ? 'Auto' : '${height}p'} · ${stream.container.toUpperCase()}';
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

  Widget _buildPlaybackControls() {
    final position = _snapshot.position;
    final duration = _snapshot.duration;
    final maxSeconds = duration.inSeconds;
    final sliderMax = maxSeconds > 0 ? maxSeconds.toDouble() : 1.0;
    final sliderValue = maxSeconds > 0
        ? position.inSeconds.clamp(0, maxSeconds).toDouble()
        : 0.0;
    final isPlaying = _snapshot.status == PlayerStatus.playing;

    return Column(
      children: [
        Slider(
          value: sliderValue,
          max: sliderMax,
          semanticFormatterCallback: (value) =>
              'Playback position ${_formatTime(Duration(seconds: value.round()))} of ${_formatTime(duration)}',
          onChanged: maxSeconds == 0
              ? null
              : (seconds) => unawaited(
                  _playbackController.seekTo(
                    Duration(seconds: seconds.round()),
                  ),
                ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatTime(position),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Text(
              _formatTime(duration),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.space3),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Seek back ten seconds',
              onPressed: maxSeconds == 0 ? null : () => unawaited(_seekBy(-10)),
              icon: const Icon(Icons.replay_10, size: 28),
            ),
            const SizedBox(width: DesignTokens.space2),
            BrutalistButton(
              label: isPlaying ? 'Pause' : 'Play',
              icon: isPlaying ? Icons.pause : Icons.play_arrow,
              onPressed: () => unawaited(
                isPlaying
                    ? _playbackController.pause()
                    : _playbackController.play(),
              ),
            ),
            const SizedBox(width: DesignTokens.space2),
            IconButton(
              tooltip: 'Seek forward ten seconds',
              onPressed: maxSeconds == 0 ? null : () => unawaited(_seekBy(10)),
              icon: const Icon(Icons.forward_10, size: 28),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.space3),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BrutalistButton(
              label: '${_snapshot.playbackSpeed.toStringAsFixed(2)}×',
              icon: Icons.speed,
              secondary: true,
              onPressed: () => unawaited(_cycleSpeed()),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _loadSource() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _video = null;
      _playlist = null;
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
      final playlist = _playbackController.currentPlaylist;
      if (playlist != null) {
        final saved = await _libraryRepository.getPlaylist(playlist.id) != null;
        if (mounted) setState(() => _isPlaylistSaved = saved);
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
      if (!mounted) return;
      setState(() => _isPlaylistSaved = true);
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
