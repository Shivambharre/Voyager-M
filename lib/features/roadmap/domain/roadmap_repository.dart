import 'roadmap.dart';

abstract interface class RoadmapRepository {
  Future<List<Roadmap>> getRoadmaps();
  Future<Roadmap?> getRoadmap(String roadmapId);
  Future<void> saveRoadmap(Roadmap roadmap);
  Future<void> deleteRoadmap(String roadmapId);
  Future<List<Topic>> getTopicsForRoadmap(String roadmapId);
  Future<void> saveTopic(Topic topic);
  Future<void> deleteTopic(String topicId);
}

class InMemoryRoadmapRepository implements RoadmapRepository {
  final Map<String, Roadmap> _roadmaps = {
    'core-frontend': const Roadmap(
      id: 'core-frontend',
      title: 'Frontend Foundations',
      description: 'Learn the essentials of UI, architecture, and product thinking.',
      isActive: true,
    ),
    'deep-study': const Roadmap(
      id: 'deep-study',
      title: 'Deep Study System',
      description: 'Build a workflow for sustained learning and active note-taking.',
      isActive: false,
    ),
  };
  final Map<String, Topic> _topics = {
    'ui-fundamentals': const Topic(
      id: 'ui-fundamentals',
      roadmapId: 'core-frontend',
      title: 'UI fundamentals',
      status: TopicStatus.inProgress,
    ),
    'state-models': const Topic(
      id: 'state-models',
      roadmapId: 'core-frontend',
      title: 'State models',
      status: TopicStatus.notStarted,
    ),
    'focus-routine': const Topic(
      id: 'focus-routine',
      roadmapId: 'deep-study',
      title: 'Focus routine',
      status: TopicStatus.notStarted,
    ),
  };

  @override
  Future<List<Roadmap>> getRoadmaps() async => List.unmodifiable(_roadmaps.values);

  @override
  Future<Roadmap?> getRoadmap(String roadmapId) async => _roadmaps[roadmapId];

  @override
  Future<void> saveRoadmap(Roadmap roadmap) async {
    _roadmaps[roadmap.id] = roadmap;
  }

  @override
  Future<void> deleteRoadmap(String roadmapId) async {
    _roadmaps.remove(roadmapId);
    _topics.removeWhere((_, topic) => topic.roadmapId == roadmapId);
  }

  @override
  Future<List<Topic>> getTopicsForRoadmap(String roadmapId) async {
    final topics = _topics.values
        .where((topic) => topic.roadmapId == roadmapId)
        .toList();
    return List.unmodifiable(topics);
  }

  @override
  Future<void> saveTopic(Topic topic) async {
    if (!_roadmaps.containsKey(topic.roadmapId)) {
      throw StateError('Roadmap "${topic.roadmapId}" does not exist.');
    }
    _topics[topic.id] = topic;
  }

  @override
  Future<void> deleteTopic(String topicId) async {
    _topics.remove(topicId);
  }
}
