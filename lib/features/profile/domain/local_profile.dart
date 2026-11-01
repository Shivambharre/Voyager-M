class LocalProfile {
  const LocalProfile({required this.displayName, required this.username});

  const LocalProfile.defaultProfile()
    : displayName = 'Voyager Learner',
      username = 'learner';

  final String displayName;
  final String username;
}
