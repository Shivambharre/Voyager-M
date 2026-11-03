import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voyager_learning/features/notes/data/in_memory_notes_repository.dart';
import 'package:voyager_learning/features/notes/data/note_image_store.dart';
import 'package:voyager_learning/features/notes/domain/study_note.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'retains referenced local images and removes them after note deletion',
    () async {
      final documents = await Directory.systemTemp.createTemp('note-images-');
      addTearDown(() => documents.delete(recursive: true));
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getApplicationDocumentsDirectory') {
              return documents.path;
            }
            throw MissingPluginException('Unexpected method: ${call.method}');
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      final separator = Platform.pathSeparator;
      final imageDirectory = Directory(
        '${documents.path}${separator}notes${separator}images',
      );
      await imageDirectory.create(recursive: true);
      final referencedImage = File(
        '${imageDirectory.path}${separator}referenced.png',
      );
      final unusedImage = File('${imageDirectory.path}${separator}unused.png');
      await referencedImage.writeAsBytes([1, 2, 3]);
      await unusedImage.writeAsBytes([4, 5, 6]);

      final repository = InMemoryNotesRepository();
      final now = DateTime.utc(2026, 11, 2);
      await repository.saveNote(
        StudyNote(
          id: 'image-note',
          title: 'Image note',
          content: 'Image',
          contentJson: jsonEncode([
            {
              'insert': {'image': referencedImage.path},
            },
          ]),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final store = NoteImageStore();
      expect(
        store.containsLocalImage(
          (await repository.getNotes()).single.contentJson,
        ),
        isTrue,
      );
      await store.cleanUnusedImages(repository);
      expect(await referencedImage.exists(), isTrue);
      expect(await unusedImage.exists(), isFalse);

      await repository.deleteNote('image-note');
      await store.cleanUnusedImages(repository);
      expect(await referencedImage.exists(), isFalse);
    },
  );
}
