import 'package:hive_ce/hive.dart';

/// Notification preferences for deadline reminders
@HiveType(typeId: 10)
class NotificationPreferences {
  @HiveField(0)
  final bool enabled;

  @HiveField(1)
  final List<int> reminderDays; // Days before deadline to notify (e.g., [1, 3, 7, 14])

  @HiveField(2)
  final int notificationHour; // Hour of day to send notification (0-23)

  @HiveField(3)
  final bool notifyOnDeadlineDay; // Also notify on the deadline day itself

  @HiveField(4)
  final int notificationMinute; // Minute of hour to send notification (0-59)

  NotificationPreferences({
    this.enabled = true,
    this.reminderDays = const [1, 3, 7, 14],
    this.notificationHour = 9, // Default: 9 AM
    this.notificationMinute = 0, // Default: :00
    this.notifyOnDeadlineDay = true,
  });

  NotificationPreferences copyWith({
    bool? enabled,
    List<int>? reminderDays,
    int? notificationHour,
    int? notificationMinute,
    bool? notifyOnDeadlineDay,
  }) {
    return NotificationPreferences(
      enabled: enabled ?? this.enabled,
      reminderDays: reminderDays ?? this.reminderDays,
      notificationHour: notificationHour ?? this.notificationHour,
      notificationMinute: notificationMinute ?? this.notificationMinute,
      notifyOnDeadlineDay: notifyOnDeadlineDay ?? this.notifyOnDeadlineDay,
    );
  }

  /// Get default notification preferences
  static NotificationPreferences getDefault() {
    return NotificationPreferences(
      enabled: true,
      reminderDays: [1, 3, 7, 14],
      notificationHour: 9,
      notificationMinute: 0,
      notifyOnDeadlineDay: true,
    );
  }
}

class NotificationPreferencesAdapter extends TypeAdapter<NotificationPreferences> {
  @override
  final int typeId = 10;

  @override
  NotificationPreferences read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationPreferences(
      enabled: fields[0] as bool? ?? true,
      reminderDays: (fields[1] as List?)?.cast<int>() ?? [1, 3, 7, 14],
      notificationHour: fields[2] as int? ?? 9,
      notifyOnDeadlineDay: fields[3] as bool? ?? true,
      notificationMinute: fields[4] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationPreferences obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.enabled)
      ..writeByte(1)
      ..write(obj.reminderDays)
      ..writeByte(2)
      ..write(obj.notificationHour)
      ..writeByte(3)
      ..write(obj.notifyOnDeadlineDay)
      ..writeByte(4)
      ..write(obj.notificationMinute);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationPreferencesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
