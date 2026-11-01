import 'local_profile.dart';

abstract interface class LocalProfileRepository {
  Future<LocalProfile> getProfile();
  Future<void> saveProfile(LocalProfile profile);
}
