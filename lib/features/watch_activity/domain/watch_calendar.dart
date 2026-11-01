abstract interface class WatchCalendar {
  DateTime localDateTime(DateTime instant);
  DateTime nextMidnightAfter(DateTime instant);
}

class SystemWatchCalendar implements WatchCalendar {
  const SystemWatchCalendar();

  @override
  DateTime localDateTime(DateTime instant) => instant.toLocal();

  @override
  DateTime nextMidnightAfter(DateTime instant) {
    final local = localDateTime(instant);
    return DateTime(local.year, local.month, local.day + 1);
  }
}
