import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design/brutalist_components.dart';
import '../../../core/design/design_system_showcase.dart';
import '../../../core/design/design_tokens.dart';
import '../../../core/di/service_locator.dart';
import '../../../features/library/domain/learning_content.dart';
import '../../../features/library/domain/learning_library_repository.dart';
import '../../../features/notes/domain/notes_repository.dart';
import '../../../features/notes/domain/study_note.dart';
import '../../../features/roadmap/domain/roadmap_repository.dart';
import '../../player/presentation/learning_player_screen.dart';
import '../../roadmap/presentation/roadmaps_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    required this.repository,
    required this.isDarkMode,
    required this.onToggleTheme,
    super.key,
  });

  final RoadmapRepository repository;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const _titles = ['HOME', 'ROADMAPS', 'LIBRARY', 'NOTES', 'SETTINGS'];

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomePage(
        libraryRepository: serviceLocator<LearningLibraryRepository>(),
        notesRepository: serviceLocator<NotesRepository>(),
        onOpenPlayer: _openPlayer,
        onNavigate: (index) => setState(() => _selectedIndex = index),
      ),
      RoadmapsPage(repository: widget.repository),
      _LibraryPage(
        repository: serviceLocator<LearningLibraryRepository>(),
        onOpenPlayer: _openPlayer,
      ),
      _NotesPage(repository: serviceLocator<NotesRepository>()),
      _SettingsPage(
        isDarkMode: widget.isDarkMode,
        onToggleTheme: widget.onToggleTheme,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(DesignTokens.borderStrong),
          child: Container(
            height: DesignTokens.borderStrong,
            color: context.outlineColor,
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
            tooltip: widget.isDarkMode
                ? 'Use light appearance'
                : 'Use dark appearance',
            onPressed: widget.onToggleTheme,
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
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

  Future<void> _openPlayer({String? sourceUrl}) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LearningPlayerScreen(initialSourceUrl: sourceUrl),
      ),
    );
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
        border: Border(top: BorderSide(color: context.outlineColor, width: 3)),
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
                        ? context.accentColor
                        : context.surfaceColor,
                    padding: const EdgeInsets.symmetric(
                      vertical: DesignTokens.space2,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _items[index].$1,
                          color: DesignTokens.ink,
                          size: 21,
                        ),
                        const SizedBox(height: DesignTokens.space1),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _items[index].$2.toUpperCase(),
                            style: const TextStyle(
                              color: DesignTokens.ink,
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

typedef _PlayerLauncher = Future<void> Function({String? sourceUrl});

class _HomePage extends StatefulWidget {
  const _HomePage({
    required this.libraryRepository,
    required this.notesRepository,
    required this.onOpenPlayer,
    required this.onNavigate,
  });

  final LearningLibraryRepository libraryRepository;
  final NotesRepository notesRepository;
  final _PlayerLauncher onOpenPlayer;
  final ValueChanged<int> onNavigate;

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
    return _HomeSummary(playlistSummaries, notes.length);
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

  @override
  Widget build(BuildContext context) {
    return _PagePadding(
      children: [
        Text(
          'A LITTLE PROGRESS\nGOES A LONG WAY.',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w900, height: 1.05),
        ),
        const SizedBox(height: DesignTokens.space2),
        Text(
          'Your study space. Nothing more, nothing less.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: context.mutedColor),
        ),
        const SizedBox(height: DesignTokens.space5),
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
                  trailing: TextButton(
                    onPressed: () => widget.onNavigate(2),
                    child: const Text('LIBRARY'),
                  ),
                ),
                const SizedBox(height: DesignTokens.space3),
                if (summary.playlists.isEmpty)
                  BrutalistEmptyState(
                    title: 'Nothing in progress',
                    message: 'Save a playlist or load a lesson to get started.',
                    action: Wrap(
                      spacing: DesignTokens.space2,
                      runSpacing: DesignTokens.space2,
                      children: [
                        BrutalistButton(
                          label: 'Open player',
                          icon: Icons.play_arrow,
                          onPressed: () => unawaited(widget.onOpenPlayer()),
                        ),
                        BrutalistButton(
                          label: 'View roadmaps',
                          icon: Icons.account_tree_outlined,
                          secondary: true,
                          onPressed: () => widget.onNavigate(1),
                        ),
                      ],
                    ),
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
              ],
            );
          },
        ),
        const SizedBox(height: DesignTokens.space6),
        const BrutalistSectionHeader(title: 'Quick actions'),
        const SizedBox(height: DesignTokens.space3),
        Wrap(
          spacing: DesignTokens.space3,
          runSpacing: DesignTokens.space3,
          children: [
            BrutalistButton(
              label: 'Open player',
              icon: Icons.play_arrow,
              onPressed: () => unawaited(widget.onOpenPlayer()),
            ),
            BrutalistButton(
              label: 'New roadmap',
              icon: Icons.account_tree_outlined,
              secondary: true,
              onPressed: () => widget.onNavigate(1),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.space5),
      ],
    );
  }
}

class _SavedPlaylistSummary {
  const _SavedPlaylistSummary(this.playlist, this.entryCount);

  final LearningPlaylist playlist;
  final int entryCount;
}

class _HomeSummary {
  const _HomeSummary(this.playlists, this.noteCount);

  final List<_SavedPlaylistSummary> playlists;
  final int noteCount;
}

class _LibraryPage extends StatefulWidget {
  const _LibraryPage({required this.repository, required this.onOpenPlayer});

  final LearningLibraryRepository repository;
  final _PlayerLauncher onOpenPlayer;

  @override
  State<_LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<_LibraryPage> {
  late Future<_LibraryContents> _contents;

  @override
  void initState() {
    super.initState();
    _contents = _loadContents();
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
  const _NotesPage({required this.repository});

  final NotesRepository repository;

  @override
  State<_NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<_NotesPage> {
  final _noteController = TextEditingController();
  late Future<List<StudyNote>> _notes;

  @override
  void initState() {
    super.initState();
    _notes = widget.repository.getNotes();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _reload() {
    final notes = widget.repository.getNotes();
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
        FutureBuilder<List<StudyNote>>(
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
                for (final note in snapshot.data!) ...[
                  BrutalistCard(
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
                  const SizedBox(height: DesignTokens.space3),
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

  String _noteSubtitle(StudyNote note) {
    final timestamp = note.timestampSeconds;
    if (timestamp == null) return 'Saved ${note.updatedAt.toLocal()}';
    final duration = Duration(seconds: timestamp);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return 'At $minutes:$seconds · ${note.updatedAt.toLocal()}';
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({required this.isDarkMode, required this.onToggleTheme});

  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.space4),
      children: [
        const Text(
          'MAKE IT YOURS.',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: DesignTokens.space5),
        const _SettingsSectionLabel(label: 'APPEARANCE'),
        BrutalistCard(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space3),
          shadow: false,
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dark appearance',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text('Keep the strong contrast, day or night.'),
                  ],
                ),
              ),
              Semantics(
                label: 'Dark appearance',
                child: Switch(
                  value: isDarkMode,
                  onChanged: (_) => onToggleTheme(),
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
              Text(
                'Voyager Learning',
                style: Theme.of(context).textTheme.titleSmall,
              ),
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
