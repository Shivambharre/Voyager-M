class AppConfig {
  const AppConfig({
    this.useExtractedYoutubePlayer = true,
    this.contentFilteringEnabled = false,
    this.filterEngine = 'none',
  });

  final bool useExtractedYoutubePlayer;
  final bool contentFilteringEnabled;
  final String filterEngine;

  static const fromEnvironment = AppConfig(
    useExtractedYoutubePlayer: bool.fromEnvironment(
      'USE_EXTRACTED_YOUTUBE_PLAYER',
      defaultValue: true,
    ),
    contentFilteringEnabled: bool.fromEnvironment(
      'ENABLE_CONTENT_FILTER',
      defaultValue: false,
    ),
    filterEngine: String.fromEnvironment('FILTER_ENGINE', defaultValue: 'none'),
  );
}
