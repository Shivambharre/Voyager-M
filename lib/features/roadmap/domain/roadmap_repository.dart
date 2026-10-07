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
