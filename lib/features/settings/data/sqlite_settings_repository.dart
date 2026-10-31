import '../../../core/database/database.dart';
import '../domain/learning_settings.dart';
import '../domain/settings_repository.dart';

class SqliteSettingsRepository implements SettingsRepository {
  const SqliteSettingsRepository(this._database);

  final AppDatabase _database;

  @override
  Future<LearningSettings> getSettings() async {
    final rows = await _database.query(
      'settings',
      where: 'id = ?',
      whereArgs: [1],
    );
    if (rows.isEmpty) return const LearningSettings();
    final row = rows.first;
    return LearningSettings(
      appearance: AppearanceMode.values.firstWhere(
        (mode) => mode.name == row['appearance'],
        orElse: () => AppearanceMode.system,
      ),
      defaultPlaybackSpeed: (row['playback_speed']! as num).toDouble(),
      resumePlayback: row['resume_playback'] == 1,
      confirmTopicCompletion: row['confirm_topic_completion'] == 1,
      dailyStudyMinutesTarget: row['daily_study_minutes_target']! as int,
      dailyLessonsTarget: row['daily_lessons_target']! as int,
    );
  }

  @override
  Future<void> saveSettings(LearningSettings settings) async {
    await _database.upsert(
      'settings',
      {
        'id': 1,
        'appearance': settings.appearance.name,
        'playback_speed': settings.defaultPlaybackSpeed,
        'resume_playback': settings.resumePlayback ? 1 : 0,
        'confirm_topic_completion': settings.confirmTopicCompletion ? 1 : 0,
        'daily_study_minutes_target': settings.dailyStudyMinutesTarget,
        'daily_lessons_target': settings.dailyLessonsTarget,
      },
      keyWhere: 'id = ?',
      keyArgs: [1],
    );
  }
}
