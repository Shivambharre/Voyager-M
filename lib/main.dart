import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'core/design/app_theme.dart';
import 'core/di/service_locator.dart';
import 'core/share/shared_video_intent_source.dart';
import 'features/home/presentation/app_shell.dart';
import 'features/roadmap/domain/roadmap_repository.dart';
import 'features/settings/domain/learning_settings.dart';
import 'features/settings/domain/settings_repository.dart';

// App starts here. We prepare the app, load saved settings,
// and then show the real UI.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  final settings = await serviceLocator<SettingsRepository>().getSettings();
  runApp(
    VoyagerApp(
      initialSettings: settings,
      sharedVideoIntentSource:
          !kIsWeb && defaultTargetPlatform == TargetPlatform.android
          ? AndroidSharedVideoIntentSource()
          : null,
    ),
  );
}

// This is the root app widget. It keeps the app theme and user settings
// in one place and passes them down to the screens.
class VoyagerApp extends StatefulWidget {
  const VoyagerApp({
    this.repository,
    this.initialSettings = const LearningSettings(),
    this.sharedVideoIntentSource,
    super.key,
  });

  final RoadmapRepository? repository;
  final LearningSettings initialSettings;
  final SharedVideoIntentSource? sharedVideoIntentSource;

  @override
  State<VoyagerApp> createState() => _VoyagerAppState();
}

class _VoyagerAppState extends State<VoyagerApp> {
  late LearningSettings _settings = widget.initialSettings;

  // Save the new preferences and refresh the app UI right away.
  Future<void> _saveSettings(LearningSettings settings) async {
    await serviceLocator<SettingsRepository>().saveSettings(settings);
    if (mounted) setState(() => _settings = settings);
  }

  @override
  Widget build(BuildContext context) {
    final repository =
        widget.repository ?? serviceLocator.get<RoadmapRepository>();

    return MaterialApp(
      title: 'VoyagerM',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: switch (_settings.appearance) {
        AppearanceMode.system => ThemeMode.system,
        AppearanceMode.light => ThemeMode.light,
        AppearanceMode.dark => ThemeMode.dark,
      },
      home: AppShell(
        repository: repository,
        sharedVideoIntentSource: widget.sharedVideoIntentSource,
        settings: _settings,
        onSettingsChanged: _saveSettings,
      ),
    );
  }
}
