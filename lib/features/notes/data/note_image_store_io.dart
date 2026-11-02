import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

Future<String> saveImage(String name, List<int> bytes) async {
  final root = await _imageDirectory();
  await root.create(recursive: true);
  final extension = path.extension(name).toLowerCase();
  final filename =
      '${DateTime.now().microsecondsSinceEpoch}${_supportedExtension(extension)}';
  final image = File(path.join(root.path, filename));
  await image.writeAsBytes(bytes, flush: true);
  return image.path;
}

Future<void> deleteUnusedImages(Set<String> references) async {
  final root = await _imageDirectory();
  if (!await root.exists()) return;
  await for (final entry in root.list()) {
    if (entry is! File || references.contains(entry.path)) continue;
    await entry.delete();
  }
}

Future<Directory> _imageDirectory() async {
  final documents = await getApplicationDocumentsDirectory();
  return Directory(path.join(documents.path, 'notes', 'images'));
}

String _supportedExtension(String extension) => switch (extension) {
  '.jpg' || '.jpeg' || '.png' || '.gif' || '.webp' => extension,
  _ => '.png',
};
