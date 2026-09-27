import 'package:flutter/material.dart';

import '../../../core/design/brutalist_components.dart';
import '../../../core/design/design_system_showcase.dart';
import '../../../core/design/design_tokens.dart';
import '../../../features/roadmap/domain/roadmap.dart';
import '../../../features/roadmap/domain/roadmap_repository.dart';
import '../../player/presentation/learning_player_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    required this.repository,
    required this.isDarkMode,
    required this.onToggleTheme,
    super.key,
  });

  final RoadmapRepository repository;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const _titles = ['HOME', 'ROADMAPS', 'LIBRARY', 'NOTES', 'SETTINGS'];

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomePage(
        onOpenPlayer: _openPlayer,
        onNavigate: (index) => setState(() => _selectedIndex = index),
      ),
      _RoadmapsPage(
        repository: widget.repository,
        onOpenPlayer: _openPlayer,
      ),
      const _LibraryPage(),
      const _NotesPage(),
      _SettingsPage(
        isDarkMode: widget.isDarkMode,
        onToggleTheme: widget.onToggleTheme,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(DesignTokens.borderStrong),
          child: Container(height: DesignTokens.borderStrong, color: context.outlineColor),
        ),
        actions: [
          IconButton(
            tooltip: 'Open design system showcase',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const DesignSystemShowcase(),
              ),
            ),
            icon: const Icon(Icons.palette_outlined),
          ),
          IconButton(
            tooltip: widget.isDarkMode ? 'Use light appearance' : 'Use dark appearance',
            onPressed: widget.onToggleTheme,
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
          ),
          const SizedBox(width: DesignTokens.space2),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: SizedBox.expand(child: pages[_selectedIndex]),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: _BrutalistNavigationBar(
            selectedIndex: _selectedIndex,
            onSelected: (index) => setState(() => _selectedIndex = index),
          ),
        ),
      ),
    );
  }

  void _openPlayer() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const LearningPlayerScreen(),
      ),
    );
  }
}

class _BrutalistNavigationBar extends StatelessWidget {
  const _BrutalistNavigationBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    (Icons.home_outlined, 'Home'),
    (Icons.account_tree_outlined, 'Roadmaps'),
    (Icons.video_library_outlined, 'Library'),
    (Icons.edit_note, 'Notes'),
    (Icons.settings_outlined, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(top: BorderSide(color: context.outlineColor, width: 3)),
      ),
      child: Row(
        children: [
          for (var index = 0; index < _items.length; index++)
            Expanded(
              child: Semantics(
                button: true,
                selected: selectedIndex == index,
                label: _items[index].$2,
                child: InkWell(
                  onTap: () => onSelected(index),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 64),
                    color: selectedIndex == index
                        ? context.accentColor
                        : context.surfaceColor,
                    padding: const EdgeInsets.symmetric(vertical: DesignTokens.space2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_items[index].$1, color: DesignTokens.ink, size: 21),
                        const SizedBox(height: DesignTokens.space1),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _items[index].$2.toUpperCase(),
                            style: const TextStyle(
                              color: DesignTokens.ink,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PagePadding extends StatelessWidget {
  const _PagePadding({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.space4),
      children: children,
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({
    required this.onOpenPlayer,
    required this.onNavigate,
  });

  final VoidCallback onOpenPlayer;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return _PagePadding(
      children: [
        Text(
          'A LITTLE PROGRESS\nGOES A LONG WAY.',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
        ),
        const SizedBox(height: DesignTokens.space2),
        Text(
          'Your study space. Nothing more, nothing less.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.mutedColor,
              ),
        ),
        const SizedBox(height: DesignTokens.space5),
        BrutalistCard(
          color: context.accentColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.play_circle_outline, size: 20),
                  const SizedBox(width: DesignTokens.space2),
                  Text('CONTINUE LEARNING', style: Theme.of(context).textTheme.labelMedium),
                ],
              ),
              const SizedBox(height: DesignTokens.space4),
              Text('Neural Networks', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: DesignTokens.space1),
              Text('VIDEO 07  /  FOUNDATIONS', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: DesignTokens.space4),
              const BrutalistProgressBar(value: 0.72, label: 'YOUR PROGRESS'),
              const SizedBox(height: DesignTokens.space4),
              BrutalistButton(
                label: 'Continue',
                icon: Icons.play_arrow,
                onPressed: onOpenPlayer,
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.space6),
        BrutalistSectionHeader(
          title: 'Your roadmaps',
          trailing: TextButton(
            onPressed: () => onNavigate(1),
            child: const Text('VIEW ALL'),
          ),
        ),
        const SizedBox(height: DesignTokens.space3),
        _RoadmapPreview(
          title: 'Machine learning',
          detail: '6 topics  ·  4 complete',
          progress: 0.68,
          icon: Icons.auto_graph,
          onTap: () => onNavigate(1),
        ),
        const SizedBox(height: DesignTokens.space3),
        _RoadmapPreview(
          title: 'Deep study system',
          detail: '3 topics  ·  1 complete',
          progress: 0.33,
          icon: Icons.menu_book_outlined,
          onTap: () => onNavigate(1),
        ),
        const SizedBox(height: DesignTokens.space6),
        const BrutalistSectionHeader(title: 'Quick actions'),
        const SizedBox(height: DesignTokens.space3),
        Wrap(
          spacing: DesignTokens.space3,
          runSpacing: DesignTokens.space3,
          children: [
            BrutalistButton(
              label: 'Add material',
              icon: Icons.add_link,
              secondary: true,
              onPressed: () => _showNotice(context, 'Add material is ready for the library workflow.'),
            ),
            BrutalistButton(
              label: 'New roadmap',
              icon: Icons.account_tree_outlined,
              secondary: true,
              onPressed: () => onNavigate(1),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.space5),
      ],
    );
  }
}

class _RoadmapPreview extends StatelessWidget {
  const _RoadmapPreview({
    required this.title,
    required this.detail,
    required this.progress,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String detail;
  final double progress;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BrutalistCard(
      onTap: onTap,
      padding: const EdgeInsets.all(DesignTokens.space3),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.accentColor,
              border: Border.all(color: context.outlineColor, width: 2),
            ),
            child: Icon(icon),
          ),
          const SizedBox(width: DesignTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                Text(detail, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: DesignTokens.space2),
                BrutalistProgressBar(value: progress),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.space2),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _RoadmapsPage extends StatefulWidget {
  const _RoadmapsPage({
    required this.repository,
    required this.onOpenPlayer,
  });

  final RoadmapRepository repository;
  final VoidCallback onOpenPlayer;

  @override
  State<_RoadmapsPage> createState() => _RoadmapsPageState();
}

class _RoadmapsPageState extends State<_RoadmapsPage> {
  late Future<List<Roadmap>> _roadmaps;

  @override
  void initState() {
    super.initState();
    _roadmaps = widget.repository.getRoadmaps();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Roadmap>>(
      future: _roadmaps,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(DesignTokens.space4),
            child: BrutalistErrorState(
              message: 'Your roadmaps could not be loaded.',
              onRetry: () => setState(() {
                _roadmaps = widget.repository.getRoadmaps();
              }),
            ),
          );
        }
        if (!snapshot.hasData) return const BrutalistLoadingState();

        final roadmaps = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(DesignTokens.space4),
          children: [
            Text('ONE STEP AT A TIME.', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: DesignTokens.space2),
            Text(
              'Keep each subject organized into a clear learning path.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.mutedColor),
            ),
            const SizedBox(height: DesignTokens.space4),
            BrutalistButton(
              label: 'Create roadmap',
              icon: Icons.add,
              onPressed: () => _showNotice(context, 'Roadmap builder is the next step.'),
            ),
            const SizedBox(height: DesignTokens.space5),
            const BrutalistSectionHeader(title: 'Your learning paths'),
            const SizedBox(height: DesignTokens.space3),
            if (roadmaps.isEmpty)
              BrutalistEmptyState(
                title: 'No roadmaps yet',
                message: 'Build your first learning roadmap to bring videos and topics together.',
                action: BrutalistButton(
                  label: 'Create roadmap',
                  onPressed: () => _showNotice(context, 'Roadmap builder is the next step.'),
                ),
              )
            else
              for (var index = 0; index < roadmaps.length; index++) ...[
                _RoadmapListCard(
                  roadmap: roadmaps[index],
                  progress: index == 0 ? 0.68 : 0.33,
                  onTap: widget.onOpenPlayer,
                ),
                if (index != roadmaps.length - 1)
                  const SizedBox(height: DesignTokens.space3),
              ],
          ],
        );
      },
    );
  }
}

class _RoadmapListCard extends StatelessWidget {
  const _RoadmapListCard({
    required this.roadmap,
    required this.progress,
    required this.onTap,
  });

  final Roadmap roadmap;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BrutalistCard(
      color: roadmap.isActive ? context.accentColor : context.surfaceColor,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(roadmap.title, style: Theme.of(context).textTheme.titleLarge),
              ),
              if (roadmap.isActive)
                const BrutalistChip(label: 'Active', selected: true),
            ],
          ),
          const SizedBox(height: DesignTokens.space2),
          Text(roadmap.description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: DesignTokens.space4),
          BrutalistProgressBar(value: progress, label: 'ROADMAP PROGRESS'),
          const SizedBox(height: DesignTokens.space3),
          Row(
            children: [
              const Icon(Icons.play_circle_outline, size: 18),
              const SizedBox(width: DesignTokens.space1),
              Text('OPEN STUDY PATH', style: Theme.of(context).textTheme.labelSmall),
              const Spacer(),
              const Icon(Icons.arrow_forward),
            ],
          ),
        ],
      ),
    );
  }
}

class _LibraryPage extends StatefulWidget {
  const _LibraryPage();

  @override
  State<_LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<_LibraryPage> {
  final _searchController = TextEditingController();
  var _query = '';
  var _filter = 'ALL';

  static const _items = [
    ('Gradient Descent, Clearly Explained', 'StatQuest  ·  18:32', 'VIDEO'),
    ('Neural Networks from Scratch', '3Blue1Brown  ·  24:10', 'VIDEO'),
    ('Linear Algebra Essentials', 'Khan Academy  ·  12 items', 'PLAYLIST'),
    ('Probability for Machine Learning', 'MIT OpenCourseWare  ·  31:06', 'SAVED'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _items.where((item) {
      final matchesSearch = '${item.$1} ${item.$2}'.toLowerCase().contains(_query.toLowerCase());
      final matchesFilter = _filter == 'ALL' || item.$3 == _filter;
      return matchesSearch && matchesFilter;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(DesignTokens.space4),
      children: [
        const BrutalistSectionHeader(title: 'Your study library'),
        const SizedBox(height: DesignTokens.space2),
        Text(
          'Only material you chose to keep.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.mutedColor),
        ),
        const SizedBox(height: DesignTokens.space4),
        BrutalistSearchField(
          controller: _searchController,
          hint: 'Search videos and playlists',
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: DesignTokens.space3),
        Wrap(
          spacing: DesignTokens.space2,
          runSpacing: DesignTokens.space2,
          children: [
            for (final filter in ['ALL', 'VIDEO', 'PLAYLIST', 'SAVED'])
              BrutalistChip(
                label: filter,
                selected: filter == _filter,
                onTap: () => setState(() => _filter = filter),
              ),
          ],
        ),
        const SizedBox(height: DesignTokens.space4),
        if (visible.isEmpty)
          const BrutalistEmptyState(
            title: 'No matching material',
            message: 'Try a different search or clear the selected filter.',
          )
        else
          for (final item in visible) ...[
            BrutalistListItem(
              title: item.$1,
              subtitle: item.$2,
              icon: item.$3 == 'PLAYLIST' ? Icons.queue_music : Icons.play_circle_outline,
              trailing: const Icon(Icons.bookmark_border),
              onTap: () => _showNotice(context, 'Open this saved study material.'),
            ),
            const SizedBox(height: DesignTokens.space3),
          ],
        BrutalistButton(
          label: 'Add video or playlist',
          icon: Icons.add_link,
          onPressed: () => _showNotice(context, 'Paste a learning video or playlist link.'),
        ),
      ],
    );
  }
}

class _NotesPage extends StatefulWidget {
  const _NotesPage();

  @override
  State<_NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<_NotesPage> {
  final _noteController = TextEditingController();
  final List<String> _notes = [
    'Gradient descent minimizes the cost function by taking repeated steps in the direction of steepest descent.',
    'A neural network learns useful representations through layers of weighted transformations.',
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.space4),
      children: [
        const BrutalistSectionHeader(title: 'Study notes'),
        const SizedBox(height: DesignTokens.space2),
        Text(
          'Ideas and important moments, kept with your learning.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.mutedColor),
        ),
        const SizedBox(height: DesignTokens.space4),
        BrutalistCard(
          color: context.raisedColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('ADD A NOTE', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: DesignTokens.space2),
              BrutalistInput(
                controller: _noteController,
                hint: 'Write down what you learned...',
                minLines: 3,
                maxLines: 6,
              ),
              const SizedBox(height: DesignTokens.space3),
              Align(
                alignment: Alignment.centerLeft,
                child: BrutalistButton(
                  label: 'Save note',
                  icon: Icons.save_outlined,
                  onPressed: _saveNote,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.space5),
        const BrutalistSectionHeader(title: 'Recent notes'),
        const SizedBox(height: DesignTokens.space3),
        for (var index = 0; index < _notes.length; index++) ...[
          BrutalistCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const BrutalistChip(label: '12:42', selected: true),
                    const SizedBox(width: DesignTokens.space2),
                    Text('NEURAL NETWORKS', style: Theme.of(context).textTheme.labelSmall),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Attach a file',
                      onPressed: () => _showNotice(context, 'Attach an image or PDF to this topic.'),
                      icon: const Icon(Icons.attach_file),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space2),
                Text(_notes[index], style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.space3),
        ],
        const BrutalistSectionHeader(title: 'Attachments'),
        const SizedBox(height: DesignTokens.space3),
        const Wrap(
          spacing: DesignTokens.space2,
          runSpacing: DesignTokens.space2,
          children: [
            BrutalistChip(label: 'handwritten-notes.png'),
            BrutalistChip(label: 'lecture-notes.pdf'),
          ],
        ),
      ],
    );
  }

  void _saveNote() {
    final text = _noteController.text.trim();
    if (text.isEmpty) {
      _showNotice(context, 'Write a note before saving.');
      return;
    }
    setState(() {
      _notes.insert(0, text);
      _noteController.clear();
    });
    _showNotice(context, 'Note saved for this study session.');
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.space4),
      children: [
        const Text('MAKE IT YOURS.', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
        const SizedBox(height: DesignTokens.space5),
        const _SettingsSectionLabel(label: 'APPEARANCE'),
        BrutalistCard(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space3),
          shadow: false,
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dark appearance', style: TextStyle(fontWeight: FontWeight.w700)),
                    Text('Keep the strong contrast, day or night.'),
                  ],
                ),
              ),
              Semantics(
                label: 'Dark appearance',
                child: Switch(
                  value: isDarkMode,
                  onChanged: (_) => onToggleTheme(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.space4),
        const _SettingsSectionLabel(label: 'PLAYBACK'),
        const _SettingsRow(
          icon: Icons.speed,
          title: 'Default speed',
          subtitle: '1.0×',
        ),
        const SizedBox(height: DesignTokens.space2),
        const _SettingsRow(
          icon: Icons.replay,
          title: 'Resume playback',
          subtitle: 'Continue where you left off',
        ),
        const SizedBox(height: DesignTokens.space4),
        const _SettingsSectionLabel(label: 'STORAGE'),
        BrutalistCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Storage usage', style: Theme.of(context).textTheme.titleSmall)),
                  Text('1.2 GB / 5 GB', style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
              const SizedBox(height: DesignTokens.space3),
              const BrutalistProgressBar(value: 0.24),
              const SizedBox(height: DesignTokens.space3),
              BrutalistButton(
                label: 'Clear cached files',
                secondary: true,
                onPressed: () => _showNotice(context, 'No cached files need clearing.'),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.space4),
        const _SettingsSectionLabel(label: 'LEARNING'),
        const _SettingsRow(
          icon: Icons.check_circle_outline,
          title: 'Completion behavior',
          subtitle: 'Confirm before completing a topic',
        ),
        const SizedBox(height: DesignTokens.space4),
        const _SettingsSectionLabel(label: 'ABOUT'),
        const _SettingsRow(
          icon: Icons.info_outline,
          title: 'Voyager Learning',
          subtitle: 'Version 0.1.0 · Local-first study',
        ),
      ],
    );
  }
}

class _SettingsSectionLabel extends StatelessWidget {
  const _SettingsSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space2),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: context.blueAccentColor,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return BrutalistListItem(
      title: title,
      subtitle: subtitle,
      icon: icon,
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showNotice(context, '$title settings'),
    );
  }
}

void _showNotice(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
  );
}
