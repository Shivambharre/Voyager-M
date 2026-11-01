import '../domain/local_profile.dart';
import '../domain/local_profile_repository.dart';

class InMemoryLocalProfileRepository implements LocalProfileRepository {
  LocalProfile _profile = const LocalProfile.defaultProfile();

  @override
  Future<LocalProfile> getProfile() async => _profile;

  @override
  Future<void> saveProfile(LocalProfile profile) async {
    _profile = profile;
  }
}
