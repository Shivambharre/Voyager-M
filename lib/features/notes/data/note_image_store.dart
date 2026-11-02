import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/notes_repository.dart';

import 'note_image_store_stub.dart'
    if (dart.library.io) 'note_image_store_io.dart' as storage;

class NoteImageStore {
  NoteImageStore({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<String?> pickAndStoreImage() async {
    final selected = await _picker.pickImage(source: ImageSource.gallery);
    if (selected == null) return null;
    final bytes = await selected.readAsBytes();
    if (kIsWeb) {
      final extension = selected.name.split('.').last.toLowerCase();
      final mimeType = switch (extension) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'gif' => 'image/gif',
        'webp' => 'image/webp',
        _ => 'image/png',
      };
      return 'data:$mimeType;base64,${base64Encode(bytes)}';
    }
    return storage.saveImage(selected.name, bytes);
  }

  Future<void> cleanUnusedImages(NotesRepository repository) async {
    if (kIsWeb) return;
    final notes = await repository.getNotes();
    final referencedImages = <String>{};
    for (final note in notes) {
      final contentJson = note.contentJson;
      if (contentJson == null || contentJson.isEmpty) continue;
      try {
        final delta = jsonDecode(contentJson);
        if (delta is! List) continue;
        for (final operation in delta.whereType<Map>()) {
          final insert = operation['insert'];
          if (insert is Map && insert['image'] is String) {
            referencedImages.add(insert['image'] as String);
          }
        }
      } on FormatException {
        continue;
      }
    }
    await storage.deleteUnusedImages(referencedImages);
  }

  Future<void> deleteUnusedImageReferences(
    NotesRepository repository,
  ) async {
    await cleanUnusedImages(repository);
  }
}
