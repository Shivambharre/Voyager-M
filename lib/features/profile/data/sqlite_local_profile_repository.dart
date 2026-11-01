import '../../../core/database/database.dart';
import '../domain/local_profile.dart';
import '../domain/local_profile_repository.dart';

class SqliteLocalProfileRepository implements LocalProfileRepository {
  const SqliteLocalProfileRepository(this._database);

  final AppDatabase _database;

  @override
  Future<LocalProfile> getProfile() async {
    final rows = await _database.query(
      'local_profile',
      where: 'id = ?',
      whereArgs: ['local'],
    );
    if (rows.isEmpty) return const LocalProfile.defaultProfile();
    return LocalProfile(
      displayName: rows.first['display_name']! as String,
      username: rows.first['username']! as String,
    );
  }

  @override
  Future<void> saveProfile(LocalProfile profile) async {
    await _database.upsert(
      'local_profile',
      {
        'id': 'local',
        'display_name': profile.displayName,
        'username': profile.username,
        'updated_at_utc': DateTime.now().toUtc().toIso8601String(),
      },
      keyWhere: 'id = ?',
      keyArgs: ['local'],
    );
  }
}
