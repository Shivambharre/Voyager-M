import 'dart:async';
import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:highlight/highlight.dart' as syntax show highlight, Node;

import '../../../core/design/design_tokens.dart';
import '../data/note_image_store.dart';
import '../domain/notes_repository.dart';
import '../domain/study_note.dart';
import 'note_table_embed_builder.dart';

class NoteEditorPage extends StatefulWidget {
  const NoteEditorPage({
    required this.repository,
    required this.resourceType,
    required this.resourceId,
    required this.resourceName,
    this.note,
    this.timestampSeconds,
    this.onCaptureTimestamp,
    this.onJumpToTimestamp,
    super.key,
  });

  final NotesRepository repository;
  final NoteResourceType resourceType;
  final String? resourceId;
  final String resourceName;
  final StudyNote? note;
  final int? timestampSeconds;
  final Future<int?> Function()? onCaptureTimestamp;
  final Future<void> Function(Duration position)? onJumpToTimestamp;

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  final _titleController = TextEditingController();
  final _imageStore = NoteImageStore();
  late final QuillController _editorController;
  Timer? _saveTimer;
  StudyNote? _savedNote;
  DateTime? _createdAt;
  int? _timestampSeconds;
  bool _attachTimestamp = false;
  bool _isDirty = false;
  bool _isSaving = false;
  bool _allowPop = false;
  int _revision = 0;
  Future<bool>? _saveOperation;
  String _saveStatus = 'Saved';

  bool get _isEditingExisting => widget.note != null;

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    _savedNote = note;
    _createdAt = note?.createdAt;
    _timestampSeconds = note?.timestampSeconds ?? widget.timestampSeconds;
    _attachTimestamp =
        widget.resourceType == NoteResourceType.video &&
        _timestampSeconds != null;
    _titleController.text = note?.title ?? 'Untitled Note';
    _editorController = QuillController(
      document: _documentFor(note),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _titleController.addListener(_scheduleSave);
    _editorController.addListener(_scheduleSave);
    if (note == null) {
      _isDirty = true;
      _scheduleSave();
    }
  }

  Document _documentFor(StudyNote? note) {
    final contentJson = note?.contentJson;
    if (contentJson != null && contentJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(contentJson);
        if (decoded is List) return Document.fromJson(decoded);
      } on Object {
        // Old or damaged Delta data is kept as readable plain text.
      }
    }
    final document = Document();
    final plainText = note?.content ?? '';
    if (plainText.isNotEmpty) {
      document.insert(0, plainText);
    }
    return document;
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _titleController.removeListener(_scheduleSave);
    _editorController.removeListener(_scheduleSave);
    _titleController.dispose();
    _editorController.dispose();
    super.dispose();
  }

  void _scheduleSave() {
    _revision++;
    _isDirty = true;
    if (mounted) {
      setState(() => _saveStatus = 'Unsaved changes');
    }
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 600), () {
      unawaited(_saveNow());
    });
  }

  Future<bool> _saveNow() async {
    if (!_isDirty) return true;
    final existingOperation = _saveOperation;
    if (existingOperation != null) return existingOperation;
    _saveTimer?.cancel();
    final operation = _persistNote();
    _saveOperation = operation;
    try {
      return await operation;
    } finally {
      _saveOperation = null;
    }
  }

  Future<bool> _persistNote() async {
    final title = _titleController.text.trim().isEmpty
        ? 'Untitled Note'
        : _titleController.text.trim();
    final delta = jsonEncode(_editorController.document.toDelta().toJson());
    final plainText = _editorController.document
        .toPlainText(_embedBuilders)
        .trim();
    final timestamp = _attachTimestamp ? _timestampSeconds : null;
    final savingRevision = _revision;
    setState(() {
      _isSaving = true;
      _saveStatus = 'Saving';
    });
    final now = DateTime.now();
    final previous = _savedNote;
    final note = StudyNote(
      id: previous?.id ?? now.microsecondsSinceEpoch.toString(),
      title: title,
      content: plainText,
      contentJson: delta,
      createdAt: _createdAt ?? now,
      updatedAt: now,
      videoId: _resourceVideoId(previous),
      topicId: _resourceTopicId(previous),
      libraryId: _resourceLibraryId(previous),
      resourceType: widget.resourceType,
      resourceId: widget.resourceId,
      resourceName: widget.resourceName,
      isResourceArchived: previous?.isResourceArchived ?? false,
      timestampSeconds: timestamp,
    );
    try {
      await widget.repository.saveNote(note);
      _savedNote = note;
      _createdAt ??= now;
      _isDirty = _revision != savingRevision;
      if (_imageStore.containsLocalImage(previous?.contentJson)) {
        try {
          await _imageStore.cleanUnusedImages(widget.repository);
        } on Object {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Note saved, but unused images could not be cleaned up.',
                ),
              ),
            );
          }
        }
      }
      if (mounted) {
        setState(() => _saveStatus = _isDirty ? 'Unsaved changes' : 'Saved');
        if (_isDirty) _scheduleSave();
      }
      return true;
    } on Object {
      if (mounted) setState(() => _saveStatus = 'Save failed');
      return false;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _resourceVideoId(StudyNote? previous) =>
      widget.resourceType == NoteResourceType.video
      ? widget.resourceId
      : previous?.videoId;

  String? _resourceTopicId(StudyNote? previous) =>
      widget.resourceType == NoteResourceType.lesson
      ? widget.resourceId
      : previous?.topicId;

  String? _resourceLibraryId(StudyNote? previous) =>
      widget.resourceType == NoteResourceType.library
      ? widget.resourceId
      : previous?.libraryId;

  Future<void> _saveAndPop() async {
    while (_isDirty) {
      if (!await _saveNow() || !mounted) return;
    }
    if (!mounted) return;
    setState(() => _allowPop = true);
    Navigator.of(context).pop(true);
  }

  Future<void> _deleteNote() async {
    final note = _savedNote;
    if (note == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This permanently deletes the note.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;
    try {
      await widget.repository.deleteNote(note.id);
      if (_imageStore.containsLocalImage(note.contentJson)) {
        await _imageStore.cleanUnusedImages(widget.repository);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete this note.')),
        );
      }
    }
  }

  Future<void> _attachCurrentTimestamp() async {
    final capture = widget.onCaptureTimestamp;
    if (capture == null) return;
    try {
      final position = await capture();
      if (!mounted || position == null) return;
      setState(() {
        _timestampSeconds = position;
        _attachTimestamp = true;
      });
      _scheduleSave();
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read the playback position.'),
          ),
        );
      }
    }
  }

  Future<void> _jumpToTimestamp() async {
    final callback = widget.onJumpToTimestamp;
    final seconds = _timestampSeconds;
    if (callback == null || seconds == null) return;
    await callback(Duration(seconds: seconds));
  }

  Future<void> _insertImage() async {
    try {
      final imageUrl = await _imageStore.pickAndStoreImage();
      if (!mounted || imageUrl == null) return;
      final selection = _editorController.selection;
      final start = selection.start;
      final length = selection.end - selection.start;
      _editorController.replaceText(
        start,
        length,
        BlockEmbed.image(imageUrl),
        TextSelection.collapsed(offset: start + 1),
      );
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not add that image.')),
        );
      }
    }
  }

  Future<void> _insertTable() async {
    final rows = await showNoteTableDialog(context);
    if (!mounted || rows == null) return;
    _insertTableEmbed(rows);
  }

  Future<void> _editTable(EmbedContext context) async {
    final custom = CustomBlockEmbed.fromJsonString(
      context.node.value.data as String,
    );
    final rows = (jsonDecode(custom.data as String) as List)
        .map((row) => (row as List).map((cell) => cell.toString()).toList())
        .toList();
    final updatedRows = await showNoteTableDialog(
      this.context,
      initialRows: rows,
    );
    if (updatedRows == null || !mounted) return;
    final offset = context.node.documentOffset;
    _editorController.replaceText(
      offset,
      1,
      BlockEmbed.custom(
        CustomBlockEmbed(
          NoteTableEmbedBuilder.embedName,
          jsonEncode(updatedRows),
        ),
      ),
      TextSelection.collapsed(offset: offset + 1),
    );
  }

  void _insertTableEmbed(List<List<String>> rows) {
    final selection = _editorController.selection;
    final start = selection.start;
    _editorController.replaceText(
      start,
      selection.end - start,
      BlockEmbed.custom(
        CustomBlockEmbed(NoteTableEmbedBuilder.embedName, jsonEncode(rows)),
      ),
      TextSelection.collapsed(offset: start + 1),
    );
  }

  Future<void> _previewCode() async {
    final selected = _editorController.document
        .toPlainText()
        .split('\n')
        .where((line) => line.isNotEmpty)
        .join('\n');
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('C code preview'),
        content: SingleChildScrollView(
          child: SelectableText.rich(
            _syntaxHighlightedText(
              selected,
              const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  List<EmbedBuilder> get _embedBuilders => [
    ...FlutterQuillEmbeds.editorBuilders(
      imageEmbedConfig: QuillEditorImageEmbedConfig(
        imageProviderBuilder: (_, imageUrl) {
          if (!imageUrl.startsWith('data:image/')) return null;
          final encodedImage = imageUrl.split(',').last;
          return MemoryImage(base64Decode(encodedImage));
        },
        onImageRemovedCallback: (_) async {},
      ),
    ),
    NoteTableEmbedBuilder(onEdit: _editTable),
  ];

  InlineSpan _buildCodeSpan(
    BuildContext context,
    Node node,
    int nodeOffset,
    String text,
    TextStyle? style,
    GestureRecognizer? recognizer,
  ) {
    final isCodeBlock =
        node.style.containsKey(Attribute.codeBlock.key) ||
        node.parent?.style.containsKey(Attribute.codeBlock.key) == true;
    if (!isCodeBlock) {
      return defaultSpanBuilder(
        context,
        node,
        nodeOffset,
        text,
        style,
        recognizer,
      );
    }
    return _syntaxHighlightedText(
      text,
      style?.copyWith(fontFamily: 'monospace'),
    );
  }

  TextSpan _syntaxHighlightedText(String text, TextStyle? baseStyle) {
    final nodes = syntax.highlight.parse(text, language: 'c').nodes ?? [];
    return TextSpan(
      style: baseStyle,
      children: [for (final node in nodes) _highlightNodeSpan(node)],
    );
  }

  TextSpan _highlightNodeSpan(syntax.Node node) {
    final className = node.className;
    final style = className == null ? null : githubTheme[className];
    if (node.value != null) {
      return TextSpan(text: node.value, style: style);
    }
    return TextSpan(
      style: style,
      children: [
        for (final child in node.children ?? <syntax.Node>[])
          _highlightNodeSpan(child),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final embedBuilders = _embedBuilders;
    return PopScope<bool>(
      canPop: _allowPop || !_isDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_allowPop) unawaited(_saveAndPop());
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('NOTE'),
          actions: [
            if (_isEditingExisting)
              IconButton(
                tooltip: 'Delete note',
                onPressed: () => unawaited(_deleteNote()),
                icon: const Icon(Icons.delete_outline),
              ),
            IconButton(
              tooltip: 'Save and close',
              onPressed: _isSaving ? null : () => unawaited(_saveAndPop()),
              icon: const Icon(Icons.check),
            ),
          ],
        ),
        body: SafeArea(
          child: Localizations.override(
            context: context,
            delegates: FlutterQuillLocalizations.localizationsDelegates,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.resourceName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                      Text(
                        _saveStatus,
                        key: const Key('note-save-status'),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _saveStatus == 'Save failed'
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.note?.isResourceArchived ?? false)
                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('The original resource is unavailable.'),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    key: const Key('note-title-field'),
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: 'Untitled Note',
                      border: InputBorder.none,
                    ),
                    style: Theme.of(context).textTheme.headlineSmall,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                if (widget.resourceType == NoteResourceType.video)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _attachTimestamp,
                          onChanged: (value) {
                            setState(() => _attachTimestamp = value ?? false);
                            _scheduleSave();
                          },
                        ),
                        const Expanded(
                          child: Text('Attach playback timestamp'),
                        ),
                        if (_attachTimestamp)
                          TextButton(
                            onPressed: widget.onCaptureTimestamp == null
                                ? null
                                : () => unawaited(_attachCurrentTimestamp()),
                            child: const Text('Use current time'),
                          ),
                        if (_attachTimestamp && _timestampSeconds != null)
                          TextButton(
                            onPressed: widget.onJumpToTimestamp == null
                                ? null
                                : () => unawaited(_jumpToTimestamp()),
                            child: Text(_formatTime(_timestampSeconds!)),
                          ),
                      ],
                    ),
                  ),
                const Divider(height: 1),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: QuillSimpleToolbar(
                    controller: _editorController,
                    config: QuillSimpleToolbarConfig(
                      showFontFamily: false,
                      showFontSize: false,
                      showColorButton: false,
                      showBackgroundColorButton: false,
                      showInlineCode: false,
                      showClearFormat: false,
                      showSearchButton: false,
                      showDirection: false,
                      showSubscript: false,
                      showSuperscript: false,
                      showQuote: false,
                      customButtons: [
                        QuillToolbarCustomButtonOptions(
                          icon: const Icon(Icons.image_outlined),
                          tooltip: 'Insert image',
                          onPressed: () => unawaited(_insertImage()),
                        ),
                        QuillToolbarCustomButtonOptions(
                          icon: const Icon(Icons.table_chart_outlined),
                          tooltip: 'Insert table',
                          onPressed: () => unawaited(_insertTable()),
                        ),
                        QuillToolbarCustomButtonOptions(
                          icon: const Icon(Icons.code),
                          tooltip: 'Preview C syntax highlighting',
                          onPressed: () => unawaited(_previewCode()),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: QuillEditor.basic(
                    key: const Key('note-body-editor'),
                    controller: _editorController,
                    config: QuillEditorConfig(
                      padding: const EdgeInsets.all(DesignTokens.space4),
                      placeholder: 'Write your note...',
                      embedBuilders: embedBuilders,
                      textSpanBuilder: _buildCodeSpan,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final duration = Duration(seconds: seconds);
    return '${duration.inMinutes}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }
}
