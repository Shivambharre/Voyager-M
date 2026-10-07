import 'package:flutter/material.dart';

import '../../../core/design/brutalist_components.dart';
import '../../../core/design/design_tokens.dart';
import '../domain/roadmap.dart';
import '../domain/roadmap_repository.dart';

class RoadmapsPage extends StatefulWidget {
  const RoadmapsPage({required this.repository, super.key});

  final RoadmapRepository repository;

  @override
  State<RoadmapsPage> createState() => _RoadmapsPageState();
}

class _RoadmapsPageState extends State<RoadmapsPage> {
  late Future<List<_RoadmapSummary>> _roadmaps;

  @override
  void initState() {
    super.initState();
    _roadmaps = _loadRoadmaps();
  }

  Future<List<_RoadmapSummary>> _loadRoadmaps() async {
    final roadmaps = await widget.repository.getRoadmaps();
    return Future.wait(
      roadmaps.map((roadmap) async {
        final topics = await widget.repository.getTopicsForRoadmap(roadmap.id);
        final completed = topics
            .where((topic) => topic.status == TopicStatus.completed)
            .length;
        return _RoadmapSummary(
          roadmap: roadmap,
          topicCount: topics.length,
          completedCount: completed,
        );
      }),
    );
  }

  void _reload() {
    final roadmaps = _loadRoadmaps();
    setState(() {
      _roadmaps = roadmaps;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_RoadmapSummary>>(
      future: _roadmaps,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(DesignTokens.space4),
            child: BrutalistErrorState(
              message: 'Your roadmaps could not be loaded.',
              onRetry: _reload,
            ),
          );
        }
        if (!snapshot.hasData) return const BrutalistLoadingState();

        final summaries = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(DesignTokens.space4),
          children: [
            Text(
              'ONE STEP AT A TIME.',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: DesignTokens.space2),
            Text(
              'Organize each subject into a learning path.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: context.mutedColor),
            ),
            const SizedBox(height: DesignTokens.space4),
            BrutalistButton(
              key: const Key('create-roadmap-button'),
              label: 'Create roadmap',
              icon: Icons.add,
              onPressed: _createRoadmap,
            ),
            const SizedBox(height: DesignTokens.space5),
            const BrutalistSectionHeader(title: 'Your learning paths'),
            const SizedBox(height: DesignTokens.space3),
            if (summaries.isEmpty)
              BrutalistEmptyState(
                title: 'No roadmaps yet',
                message:
                    'Create a roadmap to organize your lessons and topics.',
                action: BrutalistButton(
                  label: 'Create roadmap',
                  icon: Icons.add,
                  onPressed: _createRoadmap,
                ),
              )
            else
              for (var index = 0; index < summaries.length; index++) ...[
                _RoadmapCard(
                  summary: summaries[index],
                  onTap: () => _openRoadmap(summaries[index].roadmap),
                ),
                if (index != summaries.length - 1)
                  const SizedBox(height: DesignTokens.space3),
              ],
          ],
        );
      },
    );
  }

  Future<void> _createRoadmap() async {
    final values = await _showRoadmapForm(context);
    if (values == null || !mounted) return;

    final roadmaps = await widget.repository.getRoadmaps();
    await widget.repository.saveRoadmap(
      Roadmap(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: values.title,
        description: values.description,
        isActive: roadmaps.every((roadmap) => !roadmap.isActive),
      ),
    );
    _reload();
  }

  Future<void> _openRoadmap(Roadmap roadmap) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _RoadmapDetailPage(
          repository: widget.repository,
          roadmapId: roadmap.id,
        ),
      ),
    );
    if (mounted) _reload();
  }
}

class _RoadmapSummary {
  const _RoadmapSummary({
    required this.roadmap,
    required this.topicCount,
    required this.completedCount,
  });

  final Roadmap roadmap;
  final int topicCount;
  final int completedCount;

  double get progress => topicCount == 0 ? 0 : completedCount / topicCount;
}

class _RoadmapCard extends StatelessWidget {
  const _RoadmapCard({required this.summary, required this.onTap});

  final _RoadmapSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final roadmap = summary.roadmap;
    return BrutalistCard(
      key: Key('roadmap-${roadmap.id}'),
      color: roadmap.isActive ? context.accentColor : context.surfaceColor,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  roadmap.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (roadmap.isActive)
                const BrutalistChip(label: 'Active', selected: true),
            ],
          ),
          if (roadmap.description.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.space2),
            Text(
              roadmap.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: DesignTokens.space3),
          Text(
            '${summary.completedCount} of ${summary.topicCount} topics complete',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: DesignTokens.space2),
          BrutalistProgressBar(value: summary.progress),
          const SizedBox(height: DesignTokens.space3),
          Row(
            children: [
              Text(
                'OPEN ROADMAP',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoadmapDetailPage extends StatefulWidget {
  const _RoadmapDetailPage({required this.repository, required this.roadmapId});

  final RoadmapRepository repository;
  final String roadmapId;

  @override
  State<_RoadmapDetailPage> createState() => _RoadmapDetailPageState();
}

class _RoadmapDetailPageState extends State<_RoadmapDetailPage> {
  late Future<_RoadmapDetailData> _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<_RoadmapDetailData> _load() async {
    final roadmap = await widget.repository.getRoadmap(widget.roadmapId);
    if (roadmap == null) throw StateError('This roadmap no longer exists.');
    final topics = await widget.repository.getTopicsForRoadmap(roadmap.id);
    return _RoadmapDetailData(roadmap, topics);
  }

  void _reload() {
    final data = _load();
    setState(() {
      _data = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ROADMAP'),
        actions: [
          IconButton(
            tooltip: 'Edit roadmap',
            onPressed: _editRoadmap,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete roadmap',
            onPressed: _deleteRoadmap,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: FutureBuilder<_RoadmapDetailData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(DesignTokens.space4),
              child: BrutalistErrorState(
                message: 'This roadmap could not be loaded.',
                onRetry: _reload,
              ),
            );
          }
          if (!snapshot.hasData) return const BrutalistLoadingState();

          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(DesignTokens.space4),
            children: [
              Text(
                data.roadmap.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (data.roadmap.description.isNotEmpty) ...[
                const SizedBox(height: DesignTokens.space2),
                Text(
                  data.roadmap.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: DesignTokens.space3),
              Align(
                alignment: Alignment.centerLeft,
                child: BrutalistButton(
                  label: data.roadmap.isActive
                      ? 'Active roadmap'
                      : 'Set active',
                  icon: data.roadmap.isActive
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  secondary: !data.roadmap.isActive,
                  onPressed: data.roadmap.isActive ? null : _setActive,
                ),
              ),
              const SizedBox(height: DesignTokens.space5),
              BrutalistSectionHeader(
                title: 'Topics (${data.topics.length})',
                trailing: IconButton(
                  tooltip: 'Add topic',
                  onPressed: _addTopic,
                  icon: const Icon(Icons.add),
                ),
              ),
              const SizedBox(height: DesignTokens.space3),
              if (data.topics.isEmpty)
                BrutalistEmptyState(
                  title: 'No topics yet',
                  message: 'Add topics to break this learning path into steps.',
                  action: BrutalistButton(
                    label: 'Add topic',
                    icon: Icons.add,
                    onPressed: _addTopic,
                  ),
                )
              else
                for (final topic in data.topics) ...[
                  _TopicRow(
                    topic: topic,
                    onStatusChanged: (status) => _setTopicStatus(topic, status),
                    onDelete: () => _deleteTopic(topic),
                  ),
                  const SizedBox(height: DesignTokens.space2),
                ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _editRoadmap() async {
    final data = await _data;
    if (!mounted) return;
    final values = await _showRoadmapForm(context, initial: data.roadmap);
    if (values == null) return;
    await widget.repository.saveRoadmap(
      Roadmap(
        id: data.roadmap.id,
        title: values.title,
        description: values.description,
        isActive: data.roadmap.isActive,
      ),
    );
    _reload();
  }

  Future<void> _setActive() async {
    final roadmaps = await widget.repository.getRoadmaps();
    for (final roadmap in roadmaps) {
      final shouldBeActive = roadmap.id == widget.roadmapId;
      if (roadmap.isActive != shouldBeActive) {
        await widget.repository.saveRoadmap(
          Roadmap(
            id: roadmap.id,
            title: roadmap.title,
            description: roadmap.description,
            isActive: shouldBeActive,
          ),
        );
      }
    }
    _reload();
  }

  Future<void> _addTopic() async {
    final title = await _showTopicForm(context);
    if (title == null) return;
    final data = await _data;
    final position = data.topics.isEmpty
        ? 0
        : data.topics
                  .map((topic) => topic.position)
                  .reduce((a, b) => a > b ? a : b) +
              1;
    await widget.repository.saveTopic(
      Topic(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        roadmapId: widget.roadmapId,
        title: title,
        status: TopicStatus.notStarted,
        position: position,
      ),
    );
    _reload();
  }

  Future<void> _setTopicStatus(Topic topic, TopicStatus status) async {
    await widget.repository.saveTopic(
      Topic(
        id: topic.id,
        roadmapId: topic.roadmapId,
        title: topic.title,
        status: status,
        position: topic.position,
      ),
    );
    _reload();
  }

  Future<void> _deleteTopic(Topic topic) async {
    await widget.repository.deleteTopic(topic.id);
    _reload();
  }

  Future<void> _deleteRoadmap() async {
    final roadmap = (await _data).roadmap;
    if (!mounted) return;
    final confirmed = await showBrutalistDialog<bool>(
      context: context,
      title: 'Delete roadmap?',
      content: Text('"${roadmap.title}" and its topics will be removed.'),
      actions: [
        BrutalistButton(
          label: 'Cancel',
          secondary: true,
          onPressed: () => Navigator.pop(context, false),
        ),
        BrutalistButton(
          key: const Key('confirm-delete-roadmap'),
          label: 'Delete',
          icon: Icons.delete_outline,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
    if (confirmed != true || !mounted) return;
    await widget.repository.deleteRoadmap(widget.roadmapId);
    if (mounted) Navigator.pop(context);
  }
}

class _RoadmapDetailData {
  const _RoadmapDetailData(this.roadmap, this.topics);

  final Roadmap roadmap;
  final List<Topic> topics;
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({
    required this.topic,
    required this.onStatusChanged,
    required this.onDelete,
  });

  final Topic topic;
  final ValueChanged<TopicStatus> onStatusChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return BrutalistCard(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space3),
      child: Row(
        children: [
          Expanded(child: Text(topic.title)),
          DropdownButton<TopicStatus>(
            value: topic.status,
            onChanged: (value) {
              if (value != null) onStatusChanged(value);
            },
            items: [
              for (final status in TopicStatus.values)
                DropdownMenuItem(
                  value: status,
                  child: Text(_statusLabel(status)),
                ),
            ],
          ),
          IconButton(
            tooltip: 'Delete topic',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  String _statusLabel(TopicStatus status) => switch (status) {
    TopicStatus.notStarted => 'Not started',
    TopicStatus.inProgress => 'In progress',
    TopicStatus.completed => 'Complete',
  };
}

class _RoadmapFormValues {
  const _RoadmapFormValues(this.title, this.description);

  final String title;
  final String description;
}

Future<_RoadmapFormValues?> _showRoadmapForm(
  BuildContext context, {
  Roadmap? initial,
}) => showDialog<_RoadmapFormValues>(
  context: context,
  builder: (_) => _RoadmapFormDialog(initial: initial),
);

Future<String?> _showTopicForm(BuildContext context) => showDialog<String>(
  context: context,
  builder: (_) => const _TopicFormDialog(),
);

class _RoadmapFormDialog extends StatefulWidget {
  const _RoadmapFormDialog({this.initial});

  final Roadmap? initial;

  @override
  State<_RoadmapFormDialog> createState() => _RoadmapFormDialogState();
}

class _RoadmapFormDialogState extends State<_RoadmapFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initial?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.initial?.description ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FormDialogFrame(
      title: widget.initial == null ? 'Create roadmap' : 'Edit roadmap',
      children: [
        BrutalistInput(
          key: const Key('roadmap-title-field'),
          controller: _titleController,
          hint: 'Roadmap name',
        ),
        const SizedBox(height: DesignTokens.space3),
        BrutalistInput(
          key: const Key('roadmap-description-field'),
          controller: _descriptionController,
          hint: 'Description (optional)',
          minLines: 2,
          maxLines: 4,
        ),
        const SizedBox(height: DesignTokens.space4),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: DesignTokens.space2,
          runSpacing: DesignTokens.space2,
          children: [
            BrutalistButton(
              label: 'Cancel',
              secondary: true,
              onPressed: () => Navigator.pop(context),
            ),
            BrutalistButton(
              key: const Key('save-roadmap-button'),
              label: widget.initial == null ? 'Create' : 'Save',
              icon: Icons.save_outlined,
              onPressed: () {
                final title = _titleController.text.trim();
                if (title.isEmpty) return;
                Navigator.pop(
                  context,
                  _RoadmapFormValues(title, _descriptionController.text.trim()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _TopicFormDialog extends StatefulWidget {
  const _TopicFormDialog();

  @override
  State<_TopicFormDialog> createState() => _TopicFormDialogState();
}

class _TopicFormDialogState extends State<_TopicFormDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _FormDialogFrame(
      title: 'Add topic',
      children: [
        BrutalistInput(
          key: const Key('topic-title-field'),
          controller: _controller,
          hint: 'Topic name',
        ),
        const SizedBox(height: DesignTokens.space4),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: DesignTokens.space2,
          runSpacing: DesignTokens.space2,
          children: [
            BrutalistButton(
              label: 'Cancel',
              secondary: true,
              onPressed: () => Navigator.pop(context),
            ),
            BrutalistButton(
              key: const Key('save-topic-button'),
              label: 'Add topic',
              icon: Icons.add,
              onPressed: () {
                final title = _controller.text.trim();
                if (title.isNotEmpty) Navigator.pop(context, title);
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _FormDialogFrame extends StatelessWidget {
  const _FormDialogFrame({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(DesignTokens.space4),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: BrutalistCard(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: DesignTokens.space3),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
