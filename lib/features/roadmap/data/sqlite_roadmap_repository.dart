import '../../../core/database/database.dart';
import '../domain/roadmap.dart';
import '../domain/roadmap_repository.dart';

class SqliteRoadmapRepository implements RoadmapRepository {
  const SqliteRoadmapRepository(this._database);

  final AppDatabase _database;

  @override
  Future<List<Roadmap>> getRoadmaps() async {
    final rows = await _database.query('roadmaps', orderBy: 'title COLLATE NOCASE');
    return rows.map(_roadmapFromRow).toList(growable: false);
  }

  @override
  Future<Roadmap?> getRoadmap(String roadmapId) async {
    final rows = await _database.query(
      'roadmaps',
      where: 'id = ?',
      whereArgs: [roadmapId],
    );
    return rows.isEmpty ? null : _roadmapFromRow(rows.first);
  }

  @override
  Future<void> saveRoadmap(Roadmap roadmap) async {
    await _database.upsert('roadmaps', {
      'id': roadmap.id,
      'title': roadmap.title,
      'description': roadmap.description,
      'is_active': roadmap.isActive ? 1 : 0,
    }, keyWhere: 'id = ?', keyArgs: [roadmap.id]);
  }

  @override
  Future<void> deleteRoadmap(String roadmapId) async {
    await _database.delete(
      'roadmaps',
      where: 'id = ?',
      whereArgs: [roadmapId],
    );
  }

  @override
  Future<List<Topic>> getTopicsForRoadmap(String roadmapId) async {
    final rows = await _database.query(
      'topics',
      where: 'roadmap_id = ?',
      whereArgs: [roadmapId],
      orderBy: 'position, title COLLATE NOCASE',
    );
    return rows.map(_topicFromRow).toList(growable: false);
  }

  @override
  Future<void> saveTopic(Topic topic) async {
    await _database.upsert('topics', {
      'id': topic.id,
      'roadmap_id': topic.roadmapId,
      'title': topic.title,
      'status': topic.status.name,
      'position': topic.position,
    }, keyWhere: 'id = ?', keyArgs: [topic.id]);
  }

  @override
  Future<void> deleteTopic(String topicId) async {
    await _database.delete(
      'topics',
      where: 'id = ?',
      whereArgs: [topicId],
    );
  }

  Roadmap _roadmapFromRow(Map<String, Object?> row) => Roadmap(
        id: row['id']! as String,
        title: row['title']! as String,
        description: row['description']! as String,
        isActive: row['is_active'] == 1,
      );

  Topic _topicFromRow(Map<String, Object?> row) {
    final status = TopicStatus.values.firstWhere(
      (value) => value.name == row['status'],
      orElse: () => throw FormatException('Unknown topic status: ${row['status']}'),
    );
    return Topic(
      id: row['id']! as String,
      roadmapId: row['roadmap_id']! as String,
      title: row['title']! as String,
      status: status,
      position: row['position']! as int,
    );
  }
}
