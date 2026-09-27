import '../domain/learning_settings.dart';
import '../domain/settings_repository.dart';

class InMemorySettingsRepository implements SettingsRepository {
  LearningSettings _settings = const LearningSettings();

  @override
  Future<LearningSettings> getSettings() async => _settings;

  @override
  Future<void> saveSettings(LearningSettings settings) async {
    _settings = settings;
  }
}
