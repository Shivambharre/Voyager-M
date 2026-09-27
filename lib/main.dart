import 'package:flutter/material.dart';

import 'core/design/app_theme.dart';
import 'core/di/service_locator.dart';
import 'features/home/presentation/app_shell.dart';
import 'features/roadmap/domain/roadmap_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const VoyagerApp());
}

class VoyagerApp extends StatefulWidget {
  const VoyagerApp({
    this.repository,
    super.key,
  });

  final RoadmapRepository? repository;

  @override
  State<VoyagerApp> createState() => _VoyagerAppState();
}

class _VoyagerAppState extends State<VoyagerApp> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    final repository = widget.repository ??
        serviceLocator.get<RoadmapRepository>();

    return MaterialApp(
      title: 'Voyager Learning',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: AppShell(
        repository: repository,
        isDarkMode: _isDarkMode,
        onToggleTheme: () => setState(() => _isDarkMode = !_isDarkMode),
      ),
    );
  }
}
