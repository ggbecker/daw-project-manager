enum AutoBackupInterval {
  off,
  every30min,
  hourly,
  every6hours,
  daily;

  Duration? get duration {
    switch (this) {
      case AutoBackupInterval.off:
        return null;
      case AutoBackupInterval.every30min:
        return const Duration(minutes: 30);
      case AutoBackupInterval.hourly:
        return const Duration(hours: 1);
      case AutoBackupInterval.every6hours:
        return const Duration(hours: 6);
      case AutoBackupInterval.daily:
        return const Duration(hours: 24);
    }
  }

  static AutoBackupInterval fromStorageKey(String? key) {
    return AutoBackupInterval.values.firstWhere(
      (e) => e.name == key,
      orElse: () => AutoBackupInterval.off,
    );
  }
}
