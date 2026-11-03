import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design/brutalist_components.dart';
import '../../../core/design/design_tokens.dart';
import '../../library/domain/learning_library_repository.dart';
import '../../roadmap/domain/roadmap.dart';
import '../../roadmap/domain/roadmap_repository.dart';
import '../domain/notes_repository.dart';
import '../domain/study_note.dart';
import 'note_editor_page.dart';

typedef NotePlayerLauncher = Future<void> Function({
  String? sourceUrl,
  Duration? initialPosition,
});

class NotesHomePage extends StatefulWidget {
  const NotesHomePage({
    required this.repository,
    required this.libraryRepository,
    required this.roadmapRepository,
    required this.onOpenPlayer,
    super.key,
  });

  final NotesRepository repository;
  final LearningLibraryRepository libraryRepository;
  final RoadmapRepository roadmapRepository;
  final NotePlayerLauncher onOpenPlayer;

  @override
  State<NotesHomePage> createState() => _NotesHomePageState();
}

class _NotesHomePageState extends State<NotesHomePage> {
  final _searchController = TextEditingController();
  late Future<_NotesSnapshot> _snapshot;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _snapshot = _loadSnapshot();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<_NotesSnapshot> _loadSnapshot() async {
    final notes = await widget.repository.getNotes();
    final videos = await widget.libraryRepository.getVideos();
    final playlists = await widget.libraryRepository.getPlaylists();
    final roadmaps = await widget.roadmapRepository.getRoadmaps();
    final topics = <Topic>[];
    for (final roadmap in roadmaps) {
      topics.addAll(
        await widget.roadmapRepository.getTopicsForRoadmap(roadmap.id),
      );
    }
    final resources = <_NoteResource>[
      for (final video in videos)
        _NoteResource(
          id: video.id,
          type: NoteResourceType.video,
          name: video.title,
          description: video.creator,
          sourceUrl: video.sourceUrl,
        ),
      for (final topic in topics)
        _NoteResource(
          id: topic.id,
          type: NoteResourceType.lesson,
          name: topic.title,
          description: 'Lesson',
        ),
      for (final playlist in playlists)
        _NoteResource(
          id: playlist.id,
          type: NoteResourceType.library,
          name: playlist.title,
          description: playlist.description,
        ),
    ];
    return _NotesSnapshot(notes: notes, resources: resources);
  }

  void _reload() {
    setState(() => _snapshot = _loadSnapshot());
  }

  void _searchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() {});
    });
  }

  Future<void> _openResource(
    _NoteResource resource, {
    required List<StudyNote> notes,
  }) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _NotesResourcePage(
          repository: widget.repository,
          libraryRepository: widget.libraryRepository,
          resource: resource,
          notes: notes,
          onOpenPlayer: widget.onOpenPlayer,
        ),
      ),
    );
    if (mounted) _reload();
  }

  Future<void> _createNote(List<_NoteResource> resources) async {
    if (resources.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Save a video or create a library before adding notes.',
          ),
        ),
      );
      return;
    }
    final resource = await showModalBottomSheet<_NoteResource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text('Choose where to save this note'),
              subtitle: Text('Video / Lesson Notes or Library Notes'),
            ),
            for (final category in [
              NoteResourceType.video,
              NoteResourceType.lesson,
            ]) ...[
              if (resources.any((item) => item.type == category))
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    'VIDEO / LESSON NOTES',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              for (final item in resources.where(
                (item) => item.type == category,
              ))
                ListTile(
                  leading: Icon(
                    category == NoteResourceType.video
                        ? Icons.play_circle_outline
                        : Icons.school_outlined,
                  ),
                  title: Text(item.name),
                  subtitle: item.description.isEmpty
                      ? null
                      : Text(item.description),
                  onTap: () => Navigator.pop(context, item),
                ),
            ],
            if (resources.any((item) => item.type == NoteResourceType.library))
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'LIBRARY NOTES',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            for (final item in resources.where(
              (item) => item.type == NoteResourceType.library,
            ))
              ListTile(
                leading: const Icon(Icons.library_books_outlined),
                title: Text(item.name),
                subtitle: item.description.isEmpty
                    ? null
                    : Text(item.description),
                onTap: () => Navigator.pop(context, item),
              ),
          ],
        ),
      ),
    );
    if (resource == null || !mounted) return;
    await _editNote(null, resource);
  }

  Future<void> _editNote(StudyNote? note, _NoteResource? resource) async {
    final type = note?.resolvedResourceType ?? resource?.type;
    final id = note?.resolvedResourceId ?? resource?.id;
    final name = note?.resourceName ?? resource?.name ?? 'Lesson notes';
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => NoteEditorPage(
          repository: widget.repository,
          note: note,
          resourceType: type ?? NoteResourceType.lesson,
          resourceId: id,
          resourceName: name,
          onJumpToTimestamp: note?.videoId == null
              ? null
              : (position) => _openTimestamp(note!, position),
        ),
      ),
    );
    if (mounted) _reload();
  }

  Future<void> _openTimestamp(StudyNote note, Duration position) async {
    final videoId = note.videoId ?? note.resolvedResourceId;
    if (videoId == null) return;
    final video = await widget.libraryRepository.getVideo(videoId);
    if (!mounted) return;
    if (video == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The original video is unavailable.')),
      );
      return;
    }
    await widget.onOpenPlayer(
      sourceUrl: video.sourceUrl,
      initialPosition: position,
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_NotesSnapshot>(
    future: _snapshot,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return BrutalistErrorState(
          message: 'Your notes could not be loaded.',
          onRetry: _reload,
        );
      }
      if (!snapshot.hasData) return const BrutalistLoadingState();
      final data = snapshot.data!;
      final query = _searchController.text.trim();
      final filteredFuture = query.isEmpty
          ? Future<List<StudyNote>>.value(data.notes)
          : widget.repository.getNotes(searchQuery: query);
      return FutureBuilder<List<StudyNote>>(
        future: filteredFuture,
        builder: (context, searchSnapshot) {
          if (searchSnapshot.hasError) {
            return BrutalistErrorState(
              message: 'Search could not be completed.',
              onRetry: _reload,
            );
          }
          final visibleNotes = searchSnapshot.data ?? const <StudyNote>[];
          final videoLessonNotes = data.notes
              .where((note) => _isVideoLesson(note))
              .length;
          final libraryNotes = data.notes
              .where(
                (note) => note.resolvedResourceType == NoteResourceType.library,
              )
              .length;
          final recent = [...visibleNotes]
            ..sort(
              (first, second) => second.updatedAt.compareTo(first.updatedAt),
            );
          return ListView(
            padding: const EdgeInsets.all(DesignTokens.space4),
            children: [
              Row(
                children: [
                  const Expanded(child: BrutalistSectionHeader(title: 'Notes')),
                  BrutalistIconButton(
                    icon: Icons.add,
                    label: 'Add note',
                    onPressed: () => unawaited(_createNote(data.resources)),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.space2),
              Text(
                'Keep lesson ideas and library notes together.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: context.mutedColor),
              ),
              const SizedBox(height: DesignTokens.space4),
              BrutalistSearchField(
                controller: _searchController,
                hint: 'Search notes and resources',
                onChanged: _searchChanged,
              ),
              const SizedBox(height: DesignTokens.space4),
              Row(
                children: [
                  Expanded(
                    child: _CategoryCard(
                      title: 'Video / Lesson Notes',
                      count: videoLessonNotes,
                      icon: Icons.play_lesson_outlined,
                      onTap: () => _openCategory(NoteResourceType.video, data),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.space3),
                  Expanded(
                    child: _CategoryCard(
                      title: 'Library Notes',
                      count: libraryNotes,
                      icon: Icons.library_books_outlined,
                      onTap: () =>
                          _openCategory(NoteResourceType.library, data),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.space5),
              BrutalistSectionHeader(
                title: query.isEmpty ? 'Recently edited' : 'Search results',
              ),
              const SizedBox(height: DesignTokens.space3),
              if (recent.isEmpty)
                BrutalistEmptyState(
                  title: query.isEmpty ? 'No notes yet' : 'No matching notes',
                  message: query.isEmpty
                      ? 'Create a note from a video, lesson, or library.'
                      : 'Try another title or phrase from the note.',
                )
              else
                for (final note in recent.take(12))
                  _NoteCard(
                    note: note,
                    parentName: note.resourceName ?? 'Unlinked lesson',
                    onTap: () =>
                        _editNote(note, _resourceForNote(note, data.resources)),
                    onTimestampTap: note.timestampSeconds == null
                        ? null
                        : () => unawaited(
                            _openTimestamp(
                              note,
                              Duration(seconds: note.timestampSeconds!),
                            ),
                          ),
                  ),
              if (!searchSnapshot.hasData && query.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      );
    },
  );

  Future<void> _openCategory(
    NoteResourceType category,
    _NotesSnapshot snapshot,
  ) async {
    final notes = snapshot.notes
        .where(
          (note) => category == NoteResourceType.library
              ? note.resolvedResourceType == NoteResourceType.library
              : _isVideoLesson(note),
        )
        .toList();
    final groups = <String, List<StudyNote>>{};
    for (final note in notes) {
      final type = note.resolvedResourceType ?? NoteResourceType.lesson;
      final key = '${type.name}:${note.resolvedResourceId ?? '__unlinked__'}';
      groups.putIfAbsent(key, () => <StudyNote>[]).add(note);
    }
    final resources = <_NoteResource>[];
    for (final entry in groups.entries) {
      final groupNotes = entry.value;
      final note = groupNotes.first;
      final id = note.resolvedResourceId;
      final type = note.resolvedResourceType ?? NoteResourceType.lesson;
      final available = snapshot.resources.where(
        (resource) => resource.id == id && resource.type == type,
      );
      final found = available.isEmpty ? null : available.first;
      resources.add(
        _NoteResource(
          id: id,
          type: type,
          name: found?.name ?? note.resourceName ?? 'Unlinked lesson',
          description: found?.description ?? 'Original resource unavailable',
          sourceUrl: found?.sourceUrl,
          archived: note.isResourceArchived || found == null,
        ),
      );
    }
    resources.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _NotesCategoryPage(
          title: category == NoteResourceType.library
              ? 'Library Notes'
              : 'Video / Lesson Notes',
          resources: resources,
          groups: groups,
          onOpenResource: _openResource,
        ),
      ),
    );
    if (mounted) _reload();
  }

  _NoteResource? _resourceForNote(
    StudyNote note,
    List<_NoteResource> resources,
  ) {
    final type = note.resolvedResourceType;
    final id = note.resolvedResourceId;
    for (final resource in resources) {
      if (resource.type == type && resource.id == id) return resource;
    }
    return null;
  }

  bool _isVideoLesson(StudyNote note) =>
      note.resolvedResourceType != NoteResourceType.library;
}

class _NotesCategoryPage extends StatelessWidget {
  const _NotesCategoryPage({
    required this.title,
    required this.resources,
    required this.groups,
    required this.onOpenResource,
  });

  final String title;
  final List<_NoteResource> resources;
  final Map<String, List<StudyNote>> groups;
  final Future<void> Function(
    _NoteResource resource, {
    required List<StudyNote> notes,
  })
  onOpenResource;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: resources.isEmpty
        ? const Center(
            child: BrutalistEmptyState(
              title: 'No resources with notes',
              message:
                  'Add a note to a video, lesson, or library to see it here.',
            ),
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final resource in resources)
                BrutalistCard(
                  onTap: () => unawaited(
                    onOpenResource(
                      resource,
                      notes:
                          groups['${resource.type.name}:${resource.id ?? '__unlinked__'}'] ??
                          const [],
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        resource.archived
                            ? Icons.inventory_2_outlined
                            : resource.type == NoteResourceType.library
                            ? Icons.library_books_outlined
                            : Icons.play_lesson_outlined,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              resource.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              resource.archived
                                  ? 'Original resource unavailable'
                                  : '${groups['${resource.type.name}:${resource.id ?? '__unlinked__'}']?.length ?? 0} notes',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
            ],
          ),
  );
}

class _NotesResourcePage extends StatefulWidget {
  const _NotesResourcePage({
    required this.repository,
    required this.libraryRepository,
    required this.resource,
    required this.notes,
    required this.onOpenPlayer,
  });

  final NotesRepository repository;
  final LearningLibraryRepository libraryRepository;
  final _NoteResource resource;
  final List<StudyNote> notes;
  final NotePlayerLauncher onOpenPlayer;

  @override
  State<_NotesResourcePage> createState() => _NotesResourcePageState();
}

class _NotesResourcePageState extends State<_NotesResourcePage> {
  late Future<List<StudyNote>> _notes;

  @override
  void initState() {
    super.initState();
    _notes = _loadNotes();
  }

  Future<List<StudyNote>> _loadNotes() => widget.resource.id == null
      ? Future.value(widget.notes)
      : widget.repository.getNotes(
          resourceType: widget.resource.type,
          resourceId: widget.resource.id,
        );

  Future<void> _reload() async {
    final future = _loadNotes();
    setState(() => _notes = future);
    await future;
  }

  Future<void> _editNote(StudyNote? note) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => NoteEditorPage(
          repository: widget.repository,
          note: note,
          resourceType: widget.resource.type,
          resourceId: widget.resource.id,
          resourceName: widget.resource.name,
          timestampSeconds: widget.resource.type == NoteResourceType.video
              ? note?.timestampSeconds
              : null,
          onJumpToTimestamp: note?.timestampSeconds == null
              ? null
              : (position) => _openTimestamp(note!, position),
        ),
      ),
    );
    if (result == true && mounted) await _reload();
  }

  Future<void> _openTimestamp(StudyNote note, Duration position) async {
    final id = note.videoId ?? note.resolvedResourceId;
    if (id == null) return;
    final video = await widget.libraryRepository.getVideo(id);
    if (!mounted) return;
    if (video == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The original video is unavailable.')),
      );
      return;
    }
    await widget.onOpenPlayer(
      sourceUrl: video.sourceUrl,
      initialPosition: position,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.resource.name)),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => unawaited(_editNote(null)),
      icon: const Icon(Icons.add),
      label: const Text('Add note'),
    ),
    body: FutureBuilder<List<StudyNote>>(
      future: _notes,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: BrutalistErrorState(
              message: 'Notes for this resource could not be loaded.',
              onRetry: _reload,
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: BrutalistLoadingState());
        }
        final notes = snapshot.data!;
        if (notes.isEmpty) {
          return const Center(
            child: BrutalistEmptyState(
              title: 'No notes for this resource',
              message: 'Add a note to keep important ideas here.',
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          children: [
            for (final note in notes)
              _NoteCard(
                note: note,
                parentName: widget.resource.name,
                onTap: () => unawaited(_editNote(note)),
                onTimestampTap: note.timestampSeconds == null
                    ? null
                    : () => unawaited(
                        _openTimestamp(
                          note,
                          Duration(seconds: note.timestampSeconds!),
                        ),
                      ),
              ),
          ],
        );
      },
    ),
  );
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final int count;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => BrutalistCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 26),
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text('$count notes', style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.parentName,
    required this.onTap,
    this.onTimestampTap,
  });

  final StudyNote note;
  final String parentName;
  final VoidCallback onTap;
  final VoidCallback? onTimestampTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: BrutalistCard(
      onTap: onTap,
      child: Row(
        children: [
          const Icon(Icons.edit_note),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  parentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                if (note.content.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    note.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (note.timestampSeconds case final seconds?)
                  TextButton(
                    onPressed: onTimestampTap,
                    child: Text('Jump to ${_formatTime(seconds)}'),
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    ),
  );

  String _formatTime(int seconds) {
    final duration = Duration(seconds: seconds);
    return '${duration.inMinutes}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }
}

class _NotesSnapshot {
  const _NotesSnapshot({required this.notes, required this.resources});

  final List<StudyNote> notes;
  final List<_NoteResource> resources;
}

class _NoteResource {
  const _NoteResource({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    this.sourceUrl,
    this.archived = false,
  });

  final String? id;
  final NoteResourceType type;
  final String name;
  final String description;
  final String? sourceUrl;
  final bool archived;
}
