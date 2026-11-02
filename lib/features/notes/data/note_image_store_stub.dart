Future<String> saveImage(String name, List<int> bytes) =>
    Future<String>.error(UnsupportedError('Local image storage is unavailable.'));

Future<void> deleteUnusedImages(Set<String> references) async {}
