import '../domain/roadmap.dart';
import '../domain/roadmap_repository.dart';

class InMemoryRoadmapRepository implements RoadmapRepository {
  final Map<String, Roadmap> _roadmaps = {
    'demo-roadmap': const Roadmap(
      id: 'demo-roadmap',
      title: 'Demo learning path',
      description:
          'Mock-only roadmap data. Delete it to start with a blank list.',
      isActive: true,
    ),
  };
  final Map<String, Topic> _topics = {
    'demo-topic': const Topic(
      id: 'demo-topic',
      roadmapId: 'demo-roadmap',
      title: 'Sample topic',
      status: TopicStatus.inProgress,
    ),
  };

  @override
  Future<List<Roadmap>> getRoadmaps() async =>
      List.unmodifiable(_roadmaps.values);

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
    final topics =
        _topics.values.where((topic) => topic.roadmapId == roadmapId).toList()
          ..sort((first, second) => first.position.compareTo(second.position));
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
