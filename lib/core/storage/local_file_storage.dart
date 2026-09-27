abstract interface class LocalFileStorage {
  Future<String> saveFile(String fileName, List<int> bytes);
  Future<void> deleteFile(String path);
  Future<List<String>> listFiles();
}

class InMemoryFileStorage implements LocalFileStorage {
  final Map<String, List<int>> _files = {};
  var _nextId = 0;

  @override
  Future<String> saveFile(String fileName, List<int> bytes) async {
    if (fileName.trim().isEmpty) {
      throw ArgumentError.value(fileName, 'fileName', 'Must not be empty.');
    }
    final path = 'memory://${_nextId++}/${Uri.encodeComponent(fileName)}';
    _files[path] = List<int>.unmodifiable(bytes);
    return path;
  }

  @override
  Future<void> deleteFile(String path) async {
    _files.remove(path);
  }

  @override
  Future<List<String>> listFiles() async =>
      List<String>.unmodifiable(_files.keys);
}
