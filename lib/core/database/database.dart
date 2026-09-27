abstract class AppDatabase {
  Future<void> initialize();
  Future<void> close();
}

class SqfliteAppDatabase implements AppDatabase {
  @override
  Future<void> initialize() async {
    // SQLite setup will live here in future iterations.
  }

  @override
  Future<void> close() async {
    // Close database connections here.
  }
}
