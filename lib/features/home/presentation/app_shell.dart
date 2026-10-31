import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design/brutalist_components.dart';
import '../../../core/design/design_system_showcase.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/share/shared_video_intent_source.dart';
import '../../../core/share/shared_youtube_link.dart';
import '../../../features/history/domain/recent_watch_entry.dart';
import '../../../features/history/domain/recent_watch_history_repository.dart';
import '../../../features/library/domain/learning_content.dart';
import '../../../features/library/domain/learning_library_repository.dart';
import '../../../features/notes/domain/notes_repository.dart';
import '../../../features/notes/domain/study_note.dart';
import '../../../features/goals/domain/daily_goal_repository.dart';
import '../../../features/goals/domain/daily_goal_summary.dart';
import '../../../features/progress/domain/learning_progress.dart';
import '../../../features/progress/domain/progress_repository.dart';
import '../../../features/settings/domain/learning_settings.dart';
import '../../../features/roadmap/domain/roadmap_repository.dart';
import '../../player/presentation/learning_player_screen.dart';
import '../../roadmap/presentation/roadmaps_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    required this.repository,
    required this.settings,
    required this.onSettingsChanged,
    this.sharedVideoIntentSource,
    super.key,
  });

  final RoadmapRepository repository;
  final LearningSettings settings;
  final Future<void> Function(LearningSettings) onSettingsChanged;
  final SharedVideoIntentSource? sharedVideoIntentSource;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  StreamSubscription<String>? _sharedVideoSubscription;

  static const _titles = ['HOME', 'ROADMAPS', 'LIBRARY', 'NOTES', 'SETTINGS'];

  @override
  void initState() {
    super.initState();
    _sharedVideoSubscription = widget.sharedVideoIntentSource?.sharedTexts
        .listen(_handleSharedText);
  }

  @override
  void dispose() {
    unawaited(_sharedVideoSubscription?.cancel());
    super.dispose();
  }

  Future<void> _toggleAppearance(bool isDarkMode) async {
    try {
      await widget.onSettingsChanged(
        widget.settings.copyWith(
          appearance: isDarkMode ? AppearanceMode.light : AppearanceMode.dark,
        ),
      );
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save your appearance setting.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final pages = [
      _HomePage(
        libraryRepository: serviceLocator<LearningLibraryRepository>(),
        notesRepository: serviceLocator<NotesRepository>(),
        historyRepository: serviceLocator<RecentWatchHistoryRepository>(),
        dailyGoalRepository: serviceLocator<DailyGoalRepository>(),
        settings: widget.settings,
        onOpenPlayer: _openPlayer,
        onNavigate: (index) => setState(() => _selectedIndex = index),
        onOpenResume: _resumeLastLesson,
        onOpenDailyGoals: _openDailyGoals,
        onOpenProgress: _openProgress,
        onOpenBookmarks: _openBookmarks,
      ),
      RoadmapsPage(
        repository: widget.repository,
        confirmTopicCompletion: widget.settings.confirmTopicCompletion,
      ),
      _LibraryPage(
        repository: serviceLocator<LearningLibraryRepository>(),
        onOpenPlayer: _openPlayer,
      ),
      _NotesPage(
    repository: serviceLocator<NotesRepository>(),
    libraryRepository: serviceLocator<LearningLibraryRepository>(),
    onOpenPlayer: _openPlayer,
      ),
      _SettingsPage(        settings: widget.settings,
        onSettingsChanged: widget.onSettingsChanged,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(DesignTokens.border),
          child: Container(
            height: DesignTokens.border,
            color: context.dividerColor,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Open design system showcase',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const DesignSystemShowcase(),
              ),
            ),
            icon: const Icon(Icons.palette_outlined),
          ),
          IconButton(
            tooltip: isDarkMode
                ? 'Use light appearance'
                : 'Use dark appearance',
            onPressed: () => unawaited(_toggleAppearance(isDarkMode)),
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
          ),
          const SizedBox(width: DesignTokens.space2),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: SizedBox.expand(child: pages[_selectedIndex]),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: _BrutalistNavigationBar(
            selectedIndex: _selectedIndex,
            onSelected: (index) => setState(() => _selectedIndex = index),
          ),
        ),
      ),
    );
  }

  Future<void> _openPlayer({
    String? sourceUrl,
    Duration? initialPosition,
  }) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LearningPlayerScreen(
          initialSourceUrl: sourceUrl,
          recentWatchHistoryRepository:
              serviceLocator<RecentWatchHistoryRepository>(),
          initialPosition: initialPosition,
          progressRepository: serviceLocator<ProgressRepository>(),
          dailyGoalRepository: serviceLocator<DailyGoalRepository>(),
          resumePlayback: widget.settings.resumePlayback,
          defaultPlaybackSpeed: widget.settings.defaultPlaybackSpeed,
        ),
      ),
    );
  }

  Future<void> _resumeLastLesson() async {
    final recentHistory = await serviceLocator<RecentWatchHistoryRepository>()
        .getRecent(limit: 1);
    final recent = recentHistory.isNotEmpty ? recentHistory.first : null;
    if (recent == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('There is no lesson to resume yet.')),
      );
      return;
    }

    final progress = await serviceLocator<ProgressRepository>().getProgress(
      recent.videoId,
    );
    final fallbackPosition = recent.durationSeconds > 300
        ? const Duration(minutes: 5)
        : Duration(seconds: recent.durationSeconds);
    final resumePosition = progress != null && progress.positionSeconds > 0
        ? Duration(seconds: progress.positionSeconds)
        : fallbackPosition;

    if (!mounted) return;
    await _openPlayer(
      sourceUrl: recent.sourceUrl,
      initialPosition: resumePosition,
    );
  }

  Future<void> _openDailyGoals() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _DailyGoalsPage(
          repository: serviceLocator<DailyGoalRepository>(),
          settings: widget.settings,
        ),
      ),
    );
  }

  Future<void> _openProgress() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _ProgressPage(
          repository: serviceLocator<ProgressRepository>(),
          libraryRepository: serviceLocator<LearningLibraryRepository>(),
          onOpenVideo: _openPlayer,
        ),
      ),
    );
  }

  Future<void> _openBookmarks() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _BookmarksPage(
          repository: serviceLocator<ProgressRepository>(),
          libraryRepository: serviceLocator<LearningLibraryRepository>(),
          onOpenVideo: _openPlayer,
        ),
      ),
    );
  }

  void _handleSharedText(String text) {
    if (!mounted) return;
    final sourceUrl = SharedYoutubeLink.extract(text);
    if (sourceUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Share a YouTube video or playlist link.'),
        ),
      );
      return;
    }
    unawaited(_openPlayer(sourceUrl: sourceUrl));
  }
}

class _BrutalistNavigationBar extends StatelessWidget {
  const _BrutalistNavigationBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    (Icons.home_outlined, 'Home'),
    (Icons.account_tree_outlined, 'Roadmaps'),
    (Icons.video_library_outlined, 'Library'),
    (Icons.edit_note, 'Notes'),
    (Icons.settings_outlined, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(
          top: BorderSide(
            color: context.dividerColor,
            width: DesignTokens.border,
          ),
        ),
      ),
      child: Row(
        children: [
          for (var index = 0; index < _items.length; index++)
            Expanded(
              child: Semantics(
                button: true,
                selected: selectedIndex == index,
                label: _items[index].$2,
                child: InkWell(
                  onTap: () => onSelected(index),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 64),
                    color: selectedIndex == index
                        ? DesignTokens.romanOlive
                        : context.surfaceColor,
                    padding: const EdgeInsets.symmetric(
                      vertical: DesignTokens.space2,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _items[index].$1,
                          color: selectedIndex == index
                              ? DesignTokens.parchment
                              : context.inkColor,
                          size: 21,
                        ),
                        const SizedBox(height: DesignTokens.space1),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _items[index].$2.toUpperCase(),
                            style: TextStyle(
                              color: selectedIndex == index
                                  ? DesignTokens.parchment
                                  : context.inkColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.35,
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
    );
  }
}

class _PagePadding extends StatelessWidget {
  const _PagePadding({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.space4),
      children: children,
    );
  }
}

typedef _PlayerLauncher = Future<void> Function({
  String? sourceUrl,
  Duration? initialPosition,
});

class _HomePage extends StatefulWidget {
  const _HomePage({
    required this.libraryRepository,
    required this.notesRepository,
    required this.historyRepository,
    required this.dailyGoalRepository,
    required this.settings,
    required this.onOpenPlayer,
    required this.onNavigate,
    required this.onOpenResume,
    required this.onOpenDailyGoals,
    required this.onOpenProgress,
    required this.onOpenBookmarks,
  });

  final LearningLibraryRepository libraryRepository;
  final NotesRepository notesRepository;
  final RecentWatchHistoryRepository historyRepository;
  final DailyGoalRepository dailyGoalRepository;
  final LearningSettings settings;
  final _PlayerLauncher onOpenPlayer;
  final ValueChanged<int> onNavigate;
  final Future<void> Function() onOpenResume;
  final Future<void> Function() onOpenDailyGoals;
  final Future<void> Function() onOpenProgress;
  final Future<void> Function() onOpenBookmarks;

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  late Future<_HomeSummary> _summary;

  @override
  void initState() {
    super.initState();
    _summary = _loadSummary();
  }

  Future<_HomeSummary> _loadSummary() async {
    final playlists = await widget.libraryRepository.getPlaylists();
    final playlistSummaries = await Future.wait(
      playlists.map((playlist) async {
        final entries = await widget.libraryRepository.getPlaylistEntries(
          playlist.id,
        );
        return _SavedPlaylistSummary(playlist, entries.length);
      }),
    );
    final notes = await widget.notesRepository.getNotes();
    final dailyGoals = await widget.dailyGoalRepository.getSummary(
      DateTime.now(),
    );
    return _HomeSummary(playlistSummaries, notes.length, dailyGoals);
  }

  void _reload() {
    final summary = _loadSummary();
    setState(() {
      _summary = summary;
    });
  }

  Future<void> _openPlaylist(LearningPlaylist playlist) async {
    await widget.onOpenPlayer(sourceUrl: playlist.sourceUrl);
    if (mounted) _reload();
  }

  Future<void> _beginLearning() async {
    await widget.onOpenPlayer();
    if (mounted) _reload();
  }

  Future<void> _resumeLastLesson() async {
    await widget.onOpenResume();
    if (mounted) _reload();
  }

  Future<void> _openWatchHistory() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _WatchHistoryPage(
          repository: widget.historyRepository,
          onOpenVideo: widget.onOpenPlayer,
        ),
      ),
    );
    if (mounted) _reload();
  }

  Future<void> _openDailyGoals() async {
    await widget.onOpenDailyGoals();
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return _PagePadding(
      children: [
        Text(
          'VOYAGER-M · THE CLASSICAL ARCHIVE',
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: context.mutedColor, letterSpacing: 1.5),
        ),
        const SizedBox(height: DesignTokens.space3),
        Text(
          'A LITTLE PROGRESS\nGOES A LONG WAY.',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontSize: 34, height: 1.05),
        ),
        const SizedBox(height: DesignTokens.space3),
        Text(
          'A thoughtful place for the ideas you choose to keep.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: context.mutedColor),
        ),
        const SizedBox(height: DesignTokens.space4),
        BrutalistButton(
          key: const Key('begin-learning-button'),
          label: 'Begin learning',
          icon: Icons.play_arrow_rounded,
          expand: true,
          onPressed: () => unawaited(_beginLearning()),
        ),
        const SizedBox(height: DesignTokens.space6),
        FutureBuilder<_HomeSummary>(
          future: _summary,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return BrutalistErrorState(
                message: 'Your study overview could not be loaded.',
                onRetry: _reload,
              );
            }
            if (!snapshot.hasData) return const BrutalistLoadingState();
            final summary = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BrutalistSectionHeader(
                  title: 'Saved playlists (${summary.playlists.length})',
                  trailing: Wrap(
                    spacing: DesignTokens.space1,
                    children: [
                      TextButton(
                        key: const Key('open-watch-history-button'),
                        onPressed: () => unawaited(_openWatchHistory()),
                        child: const Text('HISTORY'),
                      ),
                      TextButton(
                        onPressed: () => widget.onNavigate(2),
                        child: const Text('LIBRARY'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.space3),
                if (summary.playlists.isEmpty)
                  BrutalistEmptyState(
                    title: 'Nothing in progress',
                    message: 'Save a playlist or load a lesson to get started.',
                  )
                else
                  for (final item in summary.playlists) ...[
                    BrutalistListItem(
                      title: item.playlist.title,
                      subtitle:
                          '${item.playlist.creator} · ${item.entryCount} lessons',
                      icon: Icons.queue_music,
                      trailing: const Icon(Icons.play_arrow),
                      onTap: () => unawaited(_openPlaylist(item.playlist)),
                    ),
                    const SizedBox(height: DesignTokens.space2),
                  ],
                BrutalistListItem(
                  title: 'Study notes',
                  subtitle: '${summary.noteCount} saved notes',
                  icon: Icons.edit_note,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => widget.onNavigate(3),
                ),
                const SizedBox(height: DesignTokens.space3),
                _DailyGoalSummaryCard(
                  summary: summary.dailyGoals,
                  settings: widget.settings,
                  onTap: _openDailyGoals,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: DesignTokens.space6),
        const BrutalistSectionHeader(title: 'Quick actions'),
        const SizedBox(height: DesignTokens.space3),
        SizedBox(
          height: 220,
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: DesignTokens.space3,
            mainAxisSpacing: DesignTokens.space3,
            childAspectRatio: 2.45,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _HomeQuickAction(
                key: Key('home-action-resume'),
                label: 'Resume',
                icon: Icons.play_circle_outline,
                onTap: () => unawaited(_resumeLastLesson()),
              ),
              _HomeQuickAction(
                key: Key('home-action-daily-goals'),
                label: 'Daily Goals',
                icon: Icons.track_changes,
                onTap: () => unawaited(_openDailyGoals()),
              ),
              _HomeQuickAction(
                key: Key('home-action-progress'),
                label: 'Progress',
                icon: Icons.show_chart,
                onTap: () => unawaited(widget.onOpenProgress()),
              ),
              _HomeQuickAction(
                key: Key('home-action-bookmarks'),
                label: 'Bookmarks',
                icon: Icons.bookmark_border,
                onTap: () => unawaited(widget.onOpenBookmarks()),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.space5),
      ],
    );
  }
}

class _HomeQuickAction extends StatelessWidget {
  const _HomeQuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = context.isDarkMode
        ? DesignTokens.parchment
        : DesignTokens.romanOlive;
    return Semantics(
      button: true,
      enabled: true,
      label: label,
      child: ExcludeSemantics(
        child: BrutalistCard(
          onTap: onTap,
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space2),
          shadow: false,
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: foreground.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                ),
                child: Icon(icon, color: foreground, size: 21),
              ),
              const SizedBox(width: DesignTokens.space2),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(color: foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedPlaylistSummary {
  const _SavedPlaylistSummary(this.playlist, this.entryCount);

  final LearningPlaylist playlist;
  final int entryCount;
}

class _HomeSummary {
  const _HomeSummary(this.playlists, this.noteCount, this.dailyGoals);

  final List<_SavedPlaylistSummary> playlists;
  final int noteCount;
  final DailyGoalSummary dailyGoals;
}

class _WatchHistoryPage extends StatefulWidget {
  const _WatchHistoryPage({
    required this.repository,
    required this.onOpenVideo,
  });

  final RecentWatchHistoryRepository repository;
  final _PlayerLauncher onOpenVideo;

  @override
  State<_WatchHistoryPage> createState() => _WatchHistoryPageState();
}

class _WatchHistoryPageState extends State<_WatchHistoryPage> {
  late Future<List<RecentWatchEntry>> _history;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _history = widget.repository.getRecent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WATCH HISTORY')),
      body: FutureBuilder<List<RecentWatchEntry>>(
        future: _history,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(DesignTokens.space4),
              child: BrutalistErrorState(
                message: 'Watch history could not be loaded.',
                onRetry: () => setState(_reload),
              ),
            );
          }
          if (!snapshot.hasData) return const BrutalistLoadingState();
          if (snapshot.data!.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(DesignTokens.space4),
              child: BrutalistEmptyState(
                title: 'No recently watched videos',
                message: 'Videos you play will appear here.',
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(DesignTokens.space4),
            children: [
              for (final entry in snapshot.data!)
                BrutalistListItem(
                  title: entry.title,
                  subtitle: entry.creator.isEmpty
                      ? _watchedTime(entry.watchedAt)
                      : '${entry.creator} · ${_watchedTime(entry.watchedAt)}',
                  icon: Icons.play_circle_outline,
                  trailing: const Icon(Icons.play_arrow),
                  onTap: () async {
                    await widget.onOpenVideo(sourceUrl: entry.sourceUrl);
                    if (mounted) setState(_reload);
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  String _watchedTime(DateTime watchedAt) {
    final date = watchedAt.toLocal();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return 'Watched ${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')} $hour:$minute';
  }
}

class _DailyGoalSummaryCard extends StatelessWidget {
  const _DailyGoalSummaryCard({
    required this.summary,
    required this.settings,
    required this.onTap,
  });

  final DailyGoalSummary summary;
  final LearningSettings settings;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final minutes = summary.playedSeconds ~/ 60;
    final minuteProgress = (minutes / settings.dailyStudyMinutesTarget).clamp(
      0.0,
      1.0,
    );
    final lessonProgress =
        (summary.completedLessons / settings.dailyLessonsTarget).clamp(
          0.0,
          1.0,
        );
    return BrutalistCard(
      onTap: () => unawaited(onTap()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TODAY', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: DesignTokens.space2),
          Text(
            '$minutes / ${settings.dailyStudyMinutesTarget} study minutes',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          LinearProgressIndicator(value: minuteProgress),
          const SizedBox(height: DesignTokens.space2),
          Text(
            '${summary.completedLessons} / ${settings.dailyLessonsTarget} completed lessons',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          LinearProgressIndicator(value: lessonProgress),
        ],
      ),
    );
  }
}

class _DailyGoalsPage extends StatefulWidget {
  const _DailyGoalsPage({required this.repository, required this.settings});

  final DailyGoalRepository repository;
  final LearningSettings settings;

  @override
  State<_DailyGoalsPage> createState() => _DailyGoalsPageState();
}

class _DailyGoalsPageState extends State<_DailyGoalsPage> {
  late Future<DailyGoalSummary> _summary;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _summary = widget.repository.getSummary(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DAILY GOALS')),
      body: FutureBuilder<DailyGoalSummary>(
        future: _summary,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(DesignTokens.space4),
              child: BrutalistErrorState(
                message: 'Daily goals could not be loaded.',
                onRetry: () => setState(_reload),
              ),
            );
          }
          if (!snapshot.hasData) return const BrutalistLoadingState();
          final summary = snapshot.data!;
          final minutes = summary.playedSeconds ~/ 60;
          return ListView(
            padding: const EdgeInsets.all(DesignTokens.space4),
            children: [
              const BrutalistSectionHeader(title: 'Today’s study'),
              const SizedBox(height: DesignTokens.space3),
              BrutalistCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '$minutes of ${widget.settings.dailyStudyMinutesTarget} minutes',
                    ),
                    LinearProgressIndicator(
                      value: (minutes / widget.settings.dailyStudyMinutesTarget)
                          .clamp(0.0, 1.0),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    Text(
                      '${summary.completedLessons} of ${widget.settings.dailyLessonsTarget} lessons',
                    ),
                    LinearProgressIndicator(
                      value:
                          (summary.completedLessons /
                                  widget.settings.dailyLessonsTarget)
                              .clamp(0.0, 1.0),
                    ),
                    const SizedBox(height: DesignTokens.space3),
                    Text(
                      'Study time counts only while a lesson is playing. '
                      'Mark a lesson complete in the player.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProgressPage extends StatefulWidget {
  const _ProgressPage({
    required this.repository,
    required this.libraryRepository,
    required this.onOpenVideo,
  });

  final ProgressRepository repository;
  final LearningLibraryRepository libraryRepository;
  final _PlayerLauncher onOpenVideo;

  @override
  State<_ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<_ProgressPage> {
  late Future<List<_ProgressEntry>> _entries;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<List<_ProgressEntry>> _load() async {
    final progress = await widget.repository.getAllProgress();
    final entries = await Future.wait(
      progress.map((item) async {
        final video = await widget.libraryRepository.getVideo(item.videoId);
        return video == null ? null : _ProgressEntry(item, video);
      }),
    );
    return entries.whereType<_ProgressEntry>().toList(growable: false);
  }

  void _reload() {
    _entries = _load();
  }

  Future<void> _openProgressEntry(_ProgressEntry entry) async {
    await widget.onOpenVideo(
      sourceUrl: entry.video.sourceUrl,
      initialPosition: Duration(seconds: entry.progress.positionSeconds),
    );
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LEARNING PROGRESS')),
      body: FutureBuilder<List<_ProgressEntry>>(
        future: _entries,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(DesignTokens.space4),
              child: BrutalistErrorState(
                message: 'Learning progress could not be loaded.',
                onRetry: () => setState(_reload),
              ),
            );
          }
          if (!snapshot.hasData) return const BrutalistLoadingState();
          if (snapshot.data!.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(DesignTokens.space4),
              child: BrutalistEmptyState(
                title: 'No progress yet',
                message: 'Load a lesson to start tracking your progress.',
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(DesignTokens.space4),
            children: [
              for (final entry in snapshot.data!) ...[
                BrutalistListItem(
                  title: entry.video.title,
                  subtitle: entry.progress.isCompleted
                      ? 'Complete'
                      : '${_formatPlaybackTime(entry.progress.positionSeconds)} of '
                            '${_formatPlaybackTime(entry.progress.durationSeconds)}',
                  icon: entry.progress.isCompleted
                      ? Icons.check_circle_outline
                      : Icons.play_circle_outline,
                  trailing: const Icon(Icons.play_arrow),
                  onTap: () => unawaited(_openProgressEntry(entry)),
                ),
                const SizedBox(height: DesignTokens.space2),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ProgressEntry {
  const _ProgressEntry(this.progress, this.video);

  final LearningProgress progress;
  final LearningVideo video;
}

class _BookmarksPage extends StatefulWidget {
  const _BookmarksPage({
    required this.repository,
    required this.libraryRepository,
    required this.onOpenVideo,
  });

  final ProgressRepository repository;
  final LearningLibraryRepository libraryRepository;
  final _PlayerLauncher onOpenVideo;

  @override
  State<_BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<_BookmarksPage> {
  late Future<List<_BookmarkEntry>> _entries;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<List<_BookmarkEntry>> _load() async {
    final bookmarks = await widget.repository.getAllBookmarks();
    final entries = await Future.wait(
      bookmarks.map((bookmark) async {
        final video = await widget.libraryRepository.getVideo(bookmark.videoId);
        return video == null ? null : _BookmarkEntry(bookmark, video);
      }),
    );
    return entries.whereType<_BookmarkEntry>().toList(growable: false);
  }

  void _reload() {
    _entries = _load();
  }

  Future<void> _delete(LearningBookmark bookmark) async {
    try {
      await widget.repository.deleteBookmark(bookmark.id);
      if (mounted) setState(_reload);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete this bookmark.')),
      );
    }
  }

  Future<void> _openBookmark(_BookmarkEntry entry) async {
    await widget.onOpenVideo(
      sourceUrl: entry.video.sourceUrl,
      initialPosition: Duration(seconds: entry.bookmark.positionSeconds),
    );
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BOOKMARKS')),
      body: FutureBuilder<List<_BookmarkEntry>>(
        future: _entries,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(DesignTokens.space4),
              child: BrutalistErrorState(
                message: 'Bookmarks could not be loaded.',
                onRetry: () => setState(_reload),
              ),
            );
          }
          if (!snapshot.hasData) return const BrutalistLoadingState();
          if (snapshot.data!.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(DesignTokens.space4),
              child: BrutalistEmptyState(
                title: 'No saved moments',
                message: 'Save a moment from a lesson to find it here.',
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(DesignTokens.space4),
            children: [
              for (final entry in snapshot.data!) ...[
                BrutalistListItem(
                  title: entry.video.title,
                  subtitle:
                      '${entry.bookmark.label.isEmpty ? 'Saved moment' : entry.bookmark.label} · '
                      '${_formatPlaybackTime(entry.bookmark.positionSeconds)}',
                  icon: Icons.bookmark_outline,
                  trailing: IconButton(
                    tooltip: 'Delete bookmark',
                    onPressed: () => unawaited(_delete(entry.bookmark)),
                    icon: const Icon(Icons.delete_outline),
                  ),
                  onTap: () => unawaited(_openBookmark(entry)),
                ),
                const SizedBox(height: DesignTokens.space2),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _BookmarkEntry {
  const _BookmarkEntry(this.bookmark, this.video);

  final LearningBookmark bookmark;
  final LearningVideo video;
}

String _formatPlaybackTime(int seconds) {
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

class _LibraryPage extends StatefulWidget {
  const _LibraryPage({required this.repository, required this.onOpenPlayer});

  final LearningLibraryRepository repository;
  final _PlayerLauncher onOpenPlayer;

  @override
  State<_LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<_LibraryPage> {
  final _playlistNameController = TextEditingController();
  final _playlistDescriptionController = TextEditingController();
  late Future<_LibraryContents> _contents;

  @override
  void initState() {
    super.initState();
    _contents = _loadContents();
  }

  @override
  void dispose() {
    _playlistNameController.dispose();
    _playlistDescriptionController.dispose();
    super.dispose();
  }

  Future<_LibraryContents> _loadContents() async {
    final videos = await widget.repository.getVideos();
    final playlists = await widget.repository.getPlaylists();
    return _LibraryContents(videos, playlists);
  }

  void _reload() {
    final contents = _loadContents();
    setState(() {
      _contents = contents;
    });
  }

  Future<void> _openSource(String sourceUrl) async {
    await widget.onOpenPlayer(sourceUrl: sourceUrl);
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_LibraryContents>(
      future: _contents,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(DesignTokens.space4),
            child: BrutalistErrorState(
              message: 'Your library could not be loaded.',
              onRetry: _reload,
            ),
          );
        }
        if (!snapshot.hasData) return const BrutalistLoadingState();
        final contents = snapshot.data!;
        final empty = contents.videos.isEmpty && contents.playlists.isEmpty;
        return ListView(
          padding: const EdgeInsets.all(DesignTokens.space4),
          children: [
            const BrutalistSectionHeader(title: 'Your study library'),
            const SizedBox(height: DesignTokens.space2),
            Text(
              'Only material you chose to keep.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: context.mutedColor),
            ),
            const SizedBox(height: DesignTokens.space4),
            BrutalistCard(
              color: context.raisedColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'CREATE PLAYLIST',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: DesignTokens.space2),
                  BrutalistInput(
                    controller: _playlistNameController,
                    hint: 'Playlist name',
                    minLines: 1,
                    maxLines: 1,
                  ),
                  const SizedBox(height: DesignTokens.space2),
                  BrutalistInput(
                    controller: _playlistDescriptionController,
                    hint: 'Description (optional)',
                    minLines: 2,
                    maxLines: 3,
                  ),
                  const SizedBox(height: DesignTokens.space3),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: BrutalistButton(
                      label: 'Create playlist',
                      icon: Icons.playlist_add,
                      onPressed: () => unawaited(_createPlaylist()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.space4),
            if (empty)
              BrutalistEmptyState(
                title: 'Your library is empty',
                message: 'Saved videos and playlists will appear here.',
                action: BrutalistButton(
                  label: 'Open player',
                  icon: Icons.add_link,
                  onPressed: () => unawaited(widget.onOpenPlayer()),
                ),
              ),
            if (contents.playlists.isNotEmpty) ...[
              const BrutalistSectionHeader(title: 'Playlists'),
              const SizedBox(height: DesignTokens.space3),
              for (final playlist in contents.playlists) ...[
                BrutalistListItem(
                  title: playlist.title,
                  subtitle: playlist.creator,
                  icon: Icons.queue_music,
                  trailing: IconButton(
                    tooltip: 'Remove playlist',
                    onPressed: () => unawaited(_deletePlaylist(playlist)),
                    icon: const Icon(Icons.delete_outline),
                  ),
                  onTap: () => unawaited(_openSource(playlist.sourceUrl)),
                ),
                const SizedBox(height: DesignTokens.space2),
              ],
            ],
            if (contents.videos.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.space3),
              const BrutalistSectionHeader(title: 'Videos'),
              const SizedBox(height: DesignTokens.space3),
              for (final video in contents.videos) ...[
                BrutalistListItem(
                  title: video.title,
                  subtitle: video.creator,
                  icon: Icons.play_circle_outline,
                  trailing: IconButton(
                    tooltip: 'Remove video',
                    onPressed: () => unawaited(_deleteVideo(video)),
                    icon: const Icon(Icons.delete_outline),
                  ),
                  onTap: () => unawaited(_openSource(video.sourceUrl)),
                ),
                const SizedBox(height: DesignTokens.space2),
              ],
            ],
          ],
        );
      },
    );
  }

  Future<void> _createPlaylist() async {
    final title = _playlistNameController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give your playlist a name first.')),
      );
      return;
    }

    final playlist = LearningPlaylist(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      sourceId: DateTime.now().microsecondsSinceEpoch.toString(),
      sourceUrl: '',
      title: title,
      creator: 'You',
      description: _playlistDescriptionController.text.trim(),
    );
    await widget.repository.savePlaylist(playlist);
    if (!mounted) return;
    _playlistNameController.clear();
    _playlistDescriptionController.clear();
    _reload();
  }

  Future<void> _deletePlaylist(LearningPlaylist playlist) async {
    await widget.repository.deletePlaylist(playlist.id);
    if (mounted) _reload();
  }

  Future<void> _deleteVideo(LearningVideo video) async {
    await widget.repository.deleteVideo(video.id);
    if (mounted) _reload();
  }
}

class _LibraryContents {
  const _LibraryContents(this.videos, this.playlists);

  final List<LearningVideo> videos;
  final List<LearningPlaylist> playlists;
}

class _NotesPage extends StatefulWidget {
  const _NotesPage({
    required this.repository,
    required this.libraryRepository,
    required this.onOpenPlayer,
  });

  final NotesRepository repository;
  final LearningLibraryRepository libraryRepository;
  final _PlayerLauncher onOpenPlayer;

  @override
  State<_NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<_NotesPage> {
  final _noteController = TextEditingController();
  late Future<List<_NoteGroup>> _notes;

  @override
  void initState() {
    super.initState();
    _notes = _loadNoteGroups();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<List<_NoteGroup>> _loadNoteGroups() async {
    final notes = await widget.repository.getNotes();
    final groups = <String, _NoteGroup>{};
    for (final note in notes) {
      final key = note.videoId ?? '__general__';
      final video = note.videoId == null
          ? null
          : await widget.libraryRepository.getVideo(note.videoId!);
      final title = video?.title ??
          (note.videoId == null ? 'General notes' : 'Video note');
      groups.putIfAbsent(
        key,
        () => _NoteGroup(title: title, notes: <StudyNote>[]),
      ).notes.add(note);
    }
    return groups.values.toList(growable: false);
  }

  void _reload() {
    final notes = _loadNoteGroups();
    setState(() {
      _notes = notes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.space4),
      children: [
        const BrutalistSectionHeader(title: 'Study notes'),
        const SizedBox(height: DesignTokens.space2),
        Text(
          'Ideas and important moments, kept with your learning.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: context.mutedColor),
        ),
        const SizedBox(height: DesignTokens.space4),
        BrutalistCard(
          color: context.raisedColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ADD A NOTE',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: DesignTokens.space2),
              BrutalistInput(
                controller: _noteController,
                hint: 'Write down what you learned...',
                minLines: 3,
                maxLines: 6,
              ),
              const SizedBox(height: DesignTokens.space3),
              Align(
                alignment: Alignment.centerLeft,
                child: BrutalistButton(
                  label: 'Save note',
                  icon: Icons.save_outlined,
                  onPressed: () => unawaited(_saveNote()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.space5),
        const BrutalistSectionHeader(title: 'Recent notes'),
        const SizedBox(height: DesignTokens.space3),
        FutureBuilder<List<_NoteGroup>>(
          future: _notes,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return BrutalistErrorState(
                message: 'Your notes could not be loaded.',
                onRetry: _reload,
              );
            }
            if (!snapshot.hasData) return const BrutalistLoadingState();
            if (snapshot.data!.isEmpty) {
              return const BrutalistEmptyState(
                title: 'No notes yet',
                message: 'Saved notes will appear here.',
              );
            }
            return Column(
              children: [
                for (final group in snapshot.data!) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      group.title.toUpperCase(),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space2),
                  for (final note in group.notes) ...[
                    GestureDetector(
                      onTap: note.timestampSeconds == null || note.videoId == null
                          ? null
                          : () => unawaited(_openNoteTimestamp(note)),
                      child: BrutalistCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(note.content),
                                  const SizedBox(height: DesignTokens.space2),
                                  Text(
                                    _noteSubtitle(note),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: context.mutedColor),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Delete note',
                              onPressed: () => unawaited(_deleteNote(note)),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space3),
                  ],
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _saveNote() async {
    final content = _noteController.text.trim();
    if (content.isEmpty) return;
    final now = DateTime.now();
    await widget.repository.saveNote(
      StudyNote(
        id: now.microsecondsSinceEpoch.toString(),
        content: content,
        createdAt: now,
        updatedAt: now,
      ),
    );
    if (!mounted) return;
    _noteController.clear();
    _reload();
  }

  Future<void> _deleteNote(StudyNote note) async {
    await widget.repository.deleteNote(note.id);
    if (mounted) _reload();
  }

  Future<void> _openNoteTimestamp(StudyNote note) async {
    if (note.videoId == null || note.timestampSeconds == null) return;
    final video = await widget.libraryRepository.getVideo(note.videoId!);
    if (video == null || !mounted) return;
    await widget.onOpenPlayer(
      sourceUrl: video.sourceUrl,
      initialPosition: Duration(seconds: note.timestampSeconds!),
    );
  }

  String _noteSubtitle(StudyNote note) {
    final timestamp = note.timestampSeconds;
    if (timestamp == null) return 'Saved ${note.updatedAt.toLocal()}';
    final duration = Duration(seconds: timestamp);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return 'At $minutes:$seconds · ${note.updatedAt.toLocal()}';
  }
}

class _NoteGroup {
  const _NoteGroup({required this.title, required this.notes});

  final String title;
  final List<StudyNote> notes;
}

class _SettingsPage extends StatefulWidget {
  const _SettingsPage({
    required this.settings,
    required this.onSettingsChanged,
  });

  final LearningSettings settings;
  final Future<void> Function(LearningSettings) onSettingsChanged;

  @override
  State<_SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<_SettingsPage> {
  late LearningSettings _settings = widget.settings;
  bool _isSaving = false;

  @override
  void didUpdateWidget(covariant _SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) _settings = widget.settings;
  }

  Future<void> _save(LearningSettings settings) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await widget.onSettingsChanged(settings);
      if (mounted) setState(() => _settings = settings);
    } on Object {
      if (!mounted) return;
      setState(() => _settings = widget.settings);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save your settings.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final speedOptions = <double>{
      0.5,
      0.75,
      1,
      1.25,
      1.5,
      1.75,
      2,
      2.5,
      3,
      _settings.defaultPlaybackSpeed,
    }.toList()..sort();
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.space4),
      children: [
        Text(
          'A PLACE OF YOUR OWN',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: DesignTokens.space5),
        const _SettingsSectionLabel(label: 'APPEARANCE'),
        BrutalistCard(
          child: DropdownButtonFormField<AppearanceMode>(
            key: const Key('settings-appearance'),
            isExpanded: true,
            initialValue: _settings.appearance,
            decoration: const InputDecoration(labelText: 'Appearance'),
            items: const [
              DropdownMenuItem(
                value: AppearanceMode.system,
                child: Text('Use device setting'),
              ),
              DropdownMenuItem(
                value: AppearanceMode.light,
                child: Text('Light'),
              ),
              DropdownMenuItem(value: AppearanceMode.dark, child: Text('Dark')),
            ],
            onChanged: _isSaving
                ? null
                : (value) {
                    if (value != null) {
                      unawaited(_save(_settings.copyWith(appearance: value)));
                    }
                  },
          ),
        ),
        const SizedBox(height: DesignTokens.space4),
        const _SettingsSectionLabel(label: 'PLAYBACK'),
        BrutalistCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Default playback speed',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              DropdownButton<double>(
                key: const Key('settings-playback-speed'),
                value: _settings.defaultPlaybackSpeed,
                items: [
                  for (final speed in speedOptions)
                    DropdownMenuItem(
                      value: speed,
                      child: Text('${speed.toStringAsFixed(2)}×'),
                    ),
                ],
                onChanged: _isSaving
                    ? null
                    : (speed) {
                        if (speed != null) {
                          unawaited(
                            _save(
                              _settings.copyWith(defaultPlaybackSpeed: speed),
                            ),
                          );
                        }
                      },
              ),
              Material(
                color: context.surfaceColor,
                child: SwitchListTile(
                  key: const Key('settings-resume-playback'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Resume playback position'),
                  value: _settings.resumePlayback,
                  onChanged: _isSaving
                      ? null
                      : (value) => unawaited(
                          _save(_settings.copyWith(resumePlayback: value)),
                        ),
                ),
              ),
              Material(
                color: context.surfaceColor,
                child: SwitchListTile(
                  key: const Key('settings-confirm-topic'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Confirm topic completion'),
                  value: _settings.confirmTopicCompletion,
                  onChanged: _isSaving
                      ? null
                      : (value) => unawaited(
                          _save(
                            _settings.copyWith(confirmTopicCompletion: value),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.space4),
        const _SettingsSectionLabel(label: 'DAILY GOALS'),
        BrutalistCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Study minutes: ${_settings.dailyStudyMinutesTarget}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Slider(
                key: const Key('settings-daily-minutes-target'),
                min: 5,
                max: 180,
                divisions: 35,
                label: '${_settings.dailyStudyMinutesTarget} min',
                value: _settings.dailyStudyMinutesTarget
                    .clamp(5, 180)
                    .toDouble(),
                onChanged: _isSaving
                    ? null
                    : (value) => setState(
                        () => _settings = _settings.copyWith(
                          dailyStudyMinutesTarget: value.round(),
                        ),
                      ),
                onChangeEnd: (value) => unawaited(
                  _save(
                    _settings.copyWith(dailyStudyMinutesTarget: value.round()),
                  ),
                ),
              ),
              Text(
                'Completed lessons: ${_settings.dailyLessonsTarget}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Slider(
                key: const Key('settings-daily-lessons-target'),
                min: 1,
                max: 10,
                divisions: 9,
                label: '${_settings.dailyLessonsTarget} lessons',
                value: _settings.dailyLessonsTarget.clamp(1, 10).toDouble(),
                onChanged: _isSaving
                    ? null
                    : (value) => setState(
                        () => _settings = _settings.copyWith(
                          dailyLessonsTarget: value.round(),
                        ),
                      ),
                onChangeEnd: (value) => unawaited(
                  _save(_settings.copyWith(dailyLessonsTarget: value.round())),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.space4),
        const _SettingsSectionLabel(label: 'ABOUT'),
        BrutalistCard(
          child: Row(
            children: [
              const Icon(Icons.school_outlined),
              const SizedBox(width: DesignTokens.space3),
              Text('VoyagerM', style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsSectionLabel extends StatelessWidget {
  const _SettingsSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space2),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: context.blueAccentColor,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
