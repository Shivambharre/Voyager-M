abstract interface class MediaProvider {
  Future<MediaAsset> loadAsset(String sourceUrl);
}

class MediaAsset {
  const MediaAsset({
    required this.id,
    required this.title,
    required this.sourceUrl,
    required this.durationSeconds,
  });

  final String id;
  final String title;
  final String sourceUrl;
  final int durationSeconds;
}

class MockMediaProvider implements MediaProvider {
  @override
  Future<MediaAsset> loadAsset(String sourceUrl) async {
    final uri = Uri.tryParse(sourceUrl);
    if (uri == null || !uri.hasScheme) {
      throw FormatException('A valid media URL is required.', sourceUrl);
    }
    return MediaAsset(
      id: 'mock-${Uri.encodeComponent(sourceUrl)}',
      title: 'Learning video',
      sourceUrl: sourceUrl,
      durationSeconds: 0,
    );
  }
}
