import 'dart:convert';

import '../domain/notes_repository.dart';
import '../domain/study_note.dart';

import 'browser_note_storage_stub.dart'
    if (dart.library.js_interop) 'browser_note_storage_web.dart'
    as browser_storage;

typedef NotesLoader = Future<List<StudyNote>> Function();
typedef NotesWriter = Future<void> Function(List<StudyNote> notes);

class InMemoryNotesRepository implements NotesRepository {
  InMemoryNotesRepository({this.loadNotes, this.persistNotes}) {
    _ready = _restore();
  }

  factory InMemoryNotesRepository.forBrowserStorage() =>
      InMemoryNotesRepository(
        loadNotes: () async {
          final serialized = browser_storage.readNotes();
          if (serialized == null) return const <StudyNote>[];
          final decoded = jsonDecode(serialized);
          if (decoded is! List) {
            throw const FormatException('Stored notes must be a JSON list.');
          }
          return decoded
              .map((item) => _noteFromJson(item as Map<String, dynamic>))
              .toList(growable: false);
        },
        persistNotes: (notes) async => browser_storage.writeNotes(
          jsonEncode(notes.map(_noteToJson).toList(growable: false)),
        ),
      );

  final Map<String, StudyNote> _notes = {};
  final NotesLoader? loadNotes;
  final NotesWriter? persistNotes;
  late final Future<void> _ready;

  Future<void> _restore() async {
    final loadNotes = this.loadNotes;
    if (loadNotes == null) return;
    for (final note in await loadNotes()) {
      _notes[note.id] = note;
    }
  }

  @override
  Future<List<StudyNote>> getNotes({
    String? videoId,
    String? topicId,
    String? libraryId,
    String? resourceId,
    NoteResourceType? resourceType,
    String? searchQuery,
  }) async {
    await _ready;
    final normalizedQuery = searchQuery?.trim().toLowerCase();
    final notes =
        _notes.values.where((note) {
          final matchesResource =
              (videoId == null || note.videoId == videoId) &&
              (topicId == null || note.topicId == topicId) &&
              (libraryId == null || note.libraryId == libraryId) &&
              (resourceId == null || note.resolvedResourceId == resourceId) &&
              (resourceType == null ||
                  note.resolvedResourceType == resourceType);
          final matchesQuery =
              normalizedQuery == null ||
              normalizedQuery.isEmpty ||
              note.title.toLowerCase().contains(normalizedQuery) ||
              note.content.toLowerCase().contains(normalizedQuery);
          return matchesResource && matchesQuery;
        }).toList()..sort(
          (first, second) => second.updatedAt.compareTo(first.updatedAt),
        );
    return List.unmodifiable(notes);
  }

  @override
  Future<void> saveNote(StudyNote note) async {
    await _ready;
    final previous = _notes[note.id];
    _notes[note.id] = note;
    try {
      await persistNotes?.call(List.unmodifiable(_notes.values));
    } on Object {
      if (previous == null) {
        _notes.remove(note.id);
      } else {
        _notes[note.id] = previous;
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteNote(String id) async {
    await _ready;
    final removed = _notes.remove(id);
    if (removed == null) return;
    try {
      await persistNotes?.call(List.unmodifiable(_notes.values));
    } on Object {
      _notes[id] = removed;
      rethrow;
    }
  }
}

Map<String, Object?> _noteToJson(StudyNote note) => {
  'id': note.id,
  'title': note.title,
  'content': note.content,
  'contentJson': note.contentJson,
  'createdAt': note.createdAt.toIso8601String(),
  'updatedAt': note.updatedAt.toIso8601String(),
  'videoId': note.videoId,
  'topicId': note.topicId,
  'libraryId': note.libraryId,
  'resourceType': note.resourceType?.name,
  'resourceId': note.resourceId,
  'resourceName': note.resourceName,
  'isResourceArchived': note.isResourceArchived,
  'timestampSeconds': note.timestampSeconds,
};

StudyNote _noteFromJson(Map<String, dynamic> json) {
  final resourceTypeName = json['resourceType'] as String?;
  final resourceType = resourceTypeName == null
      ? null
      : NoteResourceType.values.firstWhere(
          (type) => type.name == resourceTypeName,
          orElse: () => throw FormatException(
            'Unknown note resource type: $resourceTypeName',
          ),
        );
  return StudyNote(
    id: json['id'] as String,
    title: json['title'] as String? ?? 'Untitled Note',
    content: json['content'] as String? ?? '',
    contentJson: json['contentJson'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    videoId: json['videoId'] as String?,
    topicId: json['topicId'] as String?,
    libraryId: json['libraryId'] as String?,
    resourceType: resourceType,
    resourceId: json['resourceId'] as String?,
    resourceName: json['resourceName'] as String?,
    isResourceArchived: json['isResourceArchived'] as bool? ?? false,
    timestampSeconds: json['timestampSeconds'] as int?,
  );
}
