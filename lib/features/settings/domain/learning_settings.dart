enum AppearanceMode {
  system,
  light,
  dark,
}

class LearningSettings {
  const LearningSettings({
    this.appearance = AppearanceMode.system,
    this.defaultPlaybackSpeed = 1,
    this.resumePlayback = true,
    this.confirmTopicCompletion = true,
  }) : assert(defaultPlaybackSpeed > 0);

  final AppearanceMode appearance;
  final double defaultPlaybackSpeed;
  final bool resumePlayback;
  final bool confirmTopicCompletion;
}
