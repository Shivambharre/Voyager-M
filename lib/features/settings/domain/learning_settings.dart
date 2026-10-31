enum AppearanceMode { system, light, dark }

class LearningSettings {
  const LearningSettings({
    this.appearance = AppearanceMode.system,
    this.defaultPlaybackSpeed = 1,
    this.resumePlayback = true,
    this.confirmTopicCompletion = true,
    this.dailyStudyMinutesTarget = 30,
    this.dailyLessonsTarget = 1,
  }) : assert(defaultPlaybackSpeed > 0),
       assert(dailyStudyMinutesTarget > 0),
       assert(dailyLessonsTarget > 0);

  final AppearanceMode appearance;
  final double defaultPlaybackSpeed;
  final bool resumePlayback;
  final bool confirmTopicCompletion;
  final int dailyStudyMinutesTarget;
  final int dailyLessonsTarget;

  LearningSettings copyWith({
    AppearanceMode? appearance,
    double? defaultPlaybackSpeed,
    bool? resumePlayback,
    bool? confirmTopicCompletion,
    int? dailyStudyMinutesTarget,
    int? dailyLessonsTarget,
  }) => LearningSettings(
    appearance: appearance ?? this.appearance,
    defaultPlaybackSpeed: defaultPlaybackSpeed ?? this.defaultPlaybackSpeed,
    resumePlayback: resumePlayback ?? this.resumePlayback,
    confirmTopicCompletion:
        confirmTopicCompletion ?? this.confirmTopicCompletion,
    dailyStudyMinutesTarget:
        dailyStudyMinutesTarget ?? this.dailyStudyMinutesTarget,
    dailyLessonsTarget: dailyLessonsTarget ?? this.dailyLessonsTarget,
  );
}
