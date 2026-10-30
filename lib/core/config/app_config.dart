class AppConfig {
  const AppConfig({this.useExtractedYoutubePlayer = true});

  final bool useExtractedYoutubePlayer;

  static const fromEnvironment = AppConfig(
    useExtractedYoutubePlayer: bool.fromEnvironment(
      'USE_EXTRACTED_YOUTUBE_PLAYER',
      defaultValue: true,
    ),
  );
}
