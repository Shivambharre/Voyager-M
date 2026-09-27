import 'learning_settings.dart';

abstract interface class SettingsRepository {
  Future<LearningSettings> getSettings();
  Future<void> saveSettings(LearningSettings settings);
}
