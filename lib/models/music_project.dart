import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;
import 'todo_item.dart';

@HiveType(typeId: 1)
class MusicProject {
  @HiveField(0)
  final String id; // UUID primary key

  @HiveField(1)
  final String filePath; // absolute path

  @HiveField(2)
  final String fileName; // derived from path at scan time

  @HiveField(3)
  final int fileSizeBytes;

  @HiveField(4)
  final DateTime lastModifiedAt;

  @HiveField(5)
  final String? customDisplayName;

  @HiveField(6)
  final String? thumbnailPath;

  @HiveField(7)
  final String status; // Default: Idea (was 'Draft' in older versions)

  @HiveField(8)
  final String fileExtension; // e.g., .als, .cpr, .flp, .logicx

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  final DateTime updatedAt;

  // Optional musical metadata
  @HiveField(11)
  final double? bpm; // Beats per minute, user editable

  @HiveField(12)
  final String? musicalKey; // e.g., C#m, F major, user editable

  // NOVO CAMPO
  @HiveField(13)
  final String? notes; // Notes about the project, user editable

  @HiveField(14)
  final String? dawType; // DAW type: Ableton, Cubase, FL Studio, Logic Pro, etc.

  @HiveField(15)
  final String? dawVersion; // DAW version (major version number)

  @HiveField(16)
  final List<TodoItem> todos; // TODO list for the track

  @HiveField(17)
  final bool hidden; // Whether the project is hidden from the list

  @HiveField(18)
  final String? previewSongPath; // Path to preview audio file (local path or "drive://fileId" as fallback if download failed)

  @HiveField(19)
  final DateTime? fileCreatedAt; // Actual file creation date from filesystem (never changes once set)

  @HiveField(20)
  final DateTime? statusChangedAt; // When the status was last changed (for tracking completion time)

  @HiveField(21)
  final String? previewSongFileName; // Original filename of the preview song (for display purposes)

  @HiveField(22)
  final String? uploadedPreviewSongHash; // MD5 hash of the preview song file that was successfully uploaded to Drive (for change detection)

  @HiveField(23)
  final DateTime? deadline; // Project deadline date

  @HiveField(24)
  final String? previewSongAutoPath; // Auto-detected mixdown path (not manually set by user)

  const MusicProject({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.fileSizeBytes,
    required this.lastModifiedAt,
    required this.fileExtension,
    required this.createdAt,
    required this.updatedAt,
    this.customDisplayName,
    this.thumbnailPath,
    this.status = 'Idea',
    this.bpm,
    this.musicalKey,
    this.notes, // NOVO CAMPO NO CONSTRUTOR
    this.dawType,
    this.dawVersion,
    this.todos = const [],
    this.hidden = false,
    this.previewSongPath,
    this.fileCreatedAt,
    this.statusChangedAt,
    this.previewSongFileName,
    this.uploadedPreviewSongHash,
    this.deadline,
    this.previewSongAutoPath,
  });

  String get displayName => (customDisplayName != null && customDisplayName!.trim().isNotEmpty)
      ? customDisplayName!.trim()
      : p.basenameWithoutExtension(fileName);

  /// Returns the project age based on file creation date
  /// Falls back to lastModifiedAt if fileCreatedAt is not available
  Duration get projectAge {
    final startDate = fileCreatedAt ?? lastModifiedAt;
    return DateTime.now().difference(startDate);
  }

  /// Returns a human-readable project age string
  String get projectAgeFormatted {
    final age = projectAge;
    final years = age.inDays ~/ 365;
    final months = (age.inDays % 365) ~/ 30;
    final days = age.inDays % 30;
    
    if (years > 0) {
      if (months > 0) {
        return '$years year${years > 1 ? 's' : ''}, $months month${months > 1 ? 's' : ''}';
      }
      return '$years year${years > 1 ? 's' : ''}';
    } else if (months > 0) {
      if (days > 0) {
        return '$months month${months > 1 ? 's' : ''}, $days day${days > 1 ? 's' : ''}';
      }
      return '$months month${months > 1 ? 's' : ''}';
    } else if (days > 0) {
      return '$days day${days > 1 ? 's' : ''}';
    } else if (age.inHours > 0) {
      return '${age.inHours} hour${age.inHours > 1 ? 's' : ''}';
    } else {
      return 'Just now';
    }
  }

  /// Returns the number of days remaining until the deadline
  /// Returns null if no deadline is set
  /// Positive: days remaining, Negative: days overdue, Zero: due today
  int? get daysUntilDeadline {
    if (deadline == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline!.year, deadline!.month, deadline!.day);
    return deadlineDay.difference(today).inDays;
  }

  /// Converts musical key to Camelot Wheel notation
  /// Returns null if musicalKey is null or not recognized
  /// Handles enharmonic notations like "G#/Ab Major"
  String? get camelotCode {
    if (musicalKey == null || musicalKey!.isEmpty) return null;
    
    final key = musicalKey!.toLowerCase().trim();
    
    // Map of musical keys to Camelot codes
    final Map<String, String> camelotMap = {
      // Major keys (B side)
      'c major': '8B', 'c': '8B', 'cmaj': '8B',
      'g major': '9B', 'g': '9B', 'gmaj': '9B',
      'd major': '10B', 'd': '10B', 'dmaj': '10B',
      'a major': '11B', 'a': '11B', 'amaj': '11B',
      'e major': '12B', 'e': '12B', 'emaj': '12B',
      'b major': '1B', 'b': '1B', 'bmaj': '1B',
      'f# major': '2B', 'f#': '2B', 'f#maj': '2B', 'gb major': '2B', 'gb': '2B',
      'c# major': '3B', 'c#': '3B', 'c#maj': '3B', 'db major': '3B', 'db': '3B',
      'ab major': '4B', 'ab': '4B', 'abmaj': '4B', 'g# major': '4B', 'g#': '4B',
      'eb major': '5B', 'eb': '5B', 'ebmaj': '5B', 'd# major': '5B', 'd#': '5B',
      'bb major': '6B', 'bb': '6B', 'bbmaj': '6B', 'a# major': '6B', 'a#': '6B',
      'f major': '7B', 'f': '7B', 'fmaj': '7B',
      
      // Minor keys (A side)
      'a minor': '8A', 'am': '8A', 'amin': '8A',
      'e minor': '9A', 'em': '9A', 'emin': '9A',
      'b minor': '10A', 'bm': '10A', 'bmin': '10A',
      'f# minor': '11A', 'f#m': '11A', 'f#min': '11A', 'gb minor': '11A', 'gbm': '11A',
      'c# minor': '12A', 'c#m': '12A', 'c#min': '12A', 'db minor': '12A', 'dbm': '12A',
      'g# minor': '1A', 'g#m': '1A', 'g#min': '1A', 'ab minor': '1A', 'abm': '1A',
      'd# minor': '2A', 'd#m': '2A', 'd#min': '2A', 'eb minor': '2A', 'ebm': '2A',
      'a# minor': '3A', 'a#m': '3A', 'a#min': '3A', 'bb minor': '3A', 'bbm': '3A',
      'f minor': '4A', 'fm': '4A', 'fmin': '4A',
      'c minor': '5A', 'cm': '5A', 'cmin': '5A',
      'g minor': '6A', 'gm': '6A', 'gmin': '6A',
      'd minor': '7A', 'dm': '7A', 'dmin': '7A',
    };
    
    // Try direct mapping first
    String? result = camelotMap[key];
    if (result != null) return result;
    
    // Handle enharmonic notation (e.g., "G#/Ab Major" or "C#/Db Minor")
    if (key.contains('/')) {
      // Split by space to separate note from scale
      // "g#/ab major" -> ["g#/ab", "major"]
      final parts = key.split(' ');
      if (parts.isEmpty) return null;
      
      // Get the enharmonic notes part (before the space)
      final notePart = parts[0]; // "g#/ab"
      // Get the scale/mode part (after the space, if it exists)
      final scalePart = parts.length > 1 ? ' ${parts.sublist(1).join(' ')}' : '';
      
      // Split enharmonic notes
      // "g#/ab" -> ["g#", "ab"]
      final enharmonicNotes = notePart.split('/');
      
      // Try first enharmonic variant (e.g., "g# major")
      if (enharmonicNotes.isNotEmpty) {
        result = camelotMap[enharmonicNotes[0] + scalePart];
        if (result != null) return result;
      }
      
      // Try second enharmonic variant (e.g., "ab major")
      if (enharmonicNotes.length > 1) {
        result = camelotMap[enharmonicNotes[1] + scalePart];
        if (result != null) return result;
      }
    }
    
    return null;
  }

  /// Returns compatible Camelot codes for harmonic mixing
  /// Returns null if musicalKey is null or not recognized
  List<String>? get compatibleCamelotCodes {
    final current = camelotCode;
    if (current == null) return null;
    
    // Extract number and letter from Camelot code (e.g., "8B" -> 8, "B")
    final number = int.tryParse(current.substring(0, current.length - 1));
    final letter = current[current.length - 1];
    
    if (number == null) return null;
    
    // Calculate compatible codes:
    // 1. Same number (relative major/minor)
    // 2. +1 or -1 (adjacent on wheel)
    // 3. +7 or -7 (energy boost/drop)
    final compatible = <String>[];
    
    // Same number, opposite letter (relative major/minor)
    compatible.add('$number${letter == 'A' ? 'B' : 'A'}');
    
    // Adjacent codes (+1, -1)
    final next = number == 12 ? 1 : number + 1;
    final prev = number == 1 ? 12 : number - 1;
    compatible.add('$next$letter');
    compatible.add('$prev$letter');
    
    // Energy boost/drop (+7, -7)
    final boost = number + 7 > 12 ? number + 7 - 12 : number + 7;
    final drop = number - 7 < 1 ? number - 7 + 12 : number - 7;
    compatible.add('$boost$letter');
    compatible.add('$drop$letter');
    
    return compatible;
  }

  /// Returns a human-readable deadline status string
  String? get deadlineStatus {
    final days = daysUntilDeadline;
    if (days == null) return null;

    if (days < 0) {
      final overdueDays = days.abs();
      if (overdueDays == 1) return '1 day overdue';
      return '$overdueDays days overdue';
    } else if (days == 0) {
      return 'Due today';
    } else if (days == 1) {
      return '1 day left';
    } else if (days <= 7) {
      return '$days days left';
    } else if (days <= 30) {
      final weeks = days ~/ 7;
      return '$weeks week${weeks > 1 ? 's' : ''} left';
    } else {
      final months = days ~/ 30;
      if (months == 1) return '1 month left';
      return '$months months left';
    }
  }

  /// Returns the time it took to complete the project (from creation to finished status)
  /// Returns null if status is not 'Finished' or dates are not available
  Duration? get timeToCompletion {
    if (status != 'Finished' || statusChangedAt == null) {
      return null;
    }
    final startDate = fileCreatedAt ?? createdAt;
    return statusChangedAt!.difference(startDate);
  }

  /// Returns a human-readable time to completion string
  String? get timeToCompletionFormatted {
    final duration = timeToCompletion;
    if (duration == null) return null;
    
    final years = duration.inDays ~/ 365;
    final months = (duration.inDays % 365) ~/ 30;
    final days = duration.inDays % 30;
    
    if (years > 0) {
      if (months > 0) {
        return '$years year${years > 1 ? 's' : ''}, $months month${months > 1 ? 's' : ''}';
      }
      return '$years year${years > 1 ? 's' : ''}';
    } else if (months > 0) {
      if (days > 0) {
        return '$months month${months > 1 ? 's' : ''}, $days day${days > 1 ? 's' : ''}';
      }
      return '$months month${months > 1 ? 's' : ''}';
    } else if (days > 0) {
      return '$days day${days > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    } else {
      return 'Less than an hour';
    }
  }

  MusicProject copyWith({
    String? id,
    String? filePath,
    String? fileName,
    int? fileSizeBytes,
    DateTime? lastModifiedAt,
    String? customDisplayName,
    String? thumbnailPath,
    String? status,
    String? fileExtension,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? bpm,
    String? musicalKey,
    String? notes,
    bool clearNotes = false,
    String? dawType,
    String? dawVersion,
    List<TodoItem>? todos,
    bool? hidden,
    String? previewSongPath,
    bool clearPreviewSongPath = false,
    DateTime? fileCreatedAt,
    DateTime? statusChangedAt,
    String? previewSongFileName,
    bool clearPreviewSongFileName = false,
    String? uploadedPreviewSongHash,
    bool clearUploadedPreviewSongHash = false,
    DateTime? deadline,
    bool clearDeadline = false,
    String? previewSongAutoPath,
    bool clearPreviewSongAutoPath = false,
  }) {
    return MusicProject(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      customDisplayName: customDisplayName ?? this.customDisplayName,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      status: status ?? this.status,
      fileExtension: fileExtension ?? this.fileExtension,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bpm: bpm ?? this.bpm,
      musicalKey: musicalKey ?? this.musicalKey,
      notes: clearNotes ? null : (notes ?? this.notes),
      dawType: dawType ?? this.dawType,
      dawVersion: dawVersion ?? this.dawVersion,
      todos: todos ?? this.todos,
      hidden: hidden ?? this.hidden,
      previewSongPath: clearPreviewSongPath ? null : (previewSongPath ?? this.previewSongPath),
      fileCreatedAt: fileCreatedAt ?? this.fileCreatedAt,
      statusChangedAt: statusChangedAt ?? this.statusChangedAt,
      previewSongFileName: clearPreviewSongFileName ? null : (previewSongFileName ?? this.previewSongFileName),
      uploadedPreviewSongHash: clearUploadedPreviewSongHash ? null : (uploadedPreviewSongHash ?? this.uploadedPreviewSongHash),
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      previewSongAutoPath: clearPreviewSongAutoPath ? null : (previewSongAutoPath ?? this.previewSongAutoPath),
    );
  }
}

class MusicProjectAdapter extends TypeAdapter<MusicProject> {
  @override
  final int typeId = 1;

  @override
  MusicProject read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return MusicProject(
      id: fields[0] as String,
      filePath: fields[1] as String,
      fileName: fields[2] as String,
      fileSizeBytes: fields[3] as int,
      lastModifiedAt: fields[4] as DateTime,
      customDisplayName: fields[5] as String?,
      thumbnailPath: fields[6] as String?,
      // Migrate old "Draft" status to "Idea" for backward compatibility
      status: (fields[7] as String) == 'Draft' ? 'Idea' : (fields[7] as String),
      fileExtension: fields[8] as String,
      createdAt: fields[9] as DateTime,
      updatedAt: fields[10] as DateTime,
      bpm: fields[11] as double?,
      musicalKey: fields[12] as String?,
      notes: fields.containsKey(13) ? fields[13] as String? : null, // NOVO CAMPO
      dawType: fields.containsKey(14) ? fields[14] as String? : null,
      dawVersion: fields.containsKey(15) ? fields[15] as String? : null,
      todos: fields.containsKey(16) && fields[16] != null 
          ? (fields[16] as List).cast<TodoItem>()
          : const [],
      hidden: fields.containsKey(17) ? (fields[17] as bool) : false,
      previewSongPath: fields.containsKey(18) ? fields[18] as String? : null,
      fileCreatedAt: fields.containsKey(19) ? fields[19] as DateTime? : null,
      statusChangedAt: fields.containsKey(20) ? fields[20] as DateTime? : null,
      previewSongFileName: fields.containsKey(21) ? fields[21] as String? : null,
      uploadedPreviewSongHash: fields.containsKey(22) ? fields[22] as String? : null,
      deadline: fields.containsKey(23) ? fields[23] as DateTime? : null,
      previewSongAutoPath: fields.containsKey(24) ? fields[24] as String? : null,
    );
  }

  @override
  void write(BinaryWriter writer, MusicProject obj) {
    writer
      ..writeByte(25) // 25 fields (0-24)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.filePath)
      ..writeByte(2)
      ..write(obj.fileName)
      ..writeByte(3)
      ..write(obj.fileSizeBytes)
      ..writeByte(4)
      ..write(obj.lastModifiedAt)
      ..writeByte(5)
      ..write(obj.customDisplayName)
      ..writeByte(6)
      ..write(obj.thumbnailPath)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.fileExtension)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.bpm)
      ..writeByte(12)
      ..write(obj.musicalKey)
      ..writeByte(13)
      ..write(obj.notes)
      ..writeByte(14)
      ..write(obj.dawType)
      ..writeByte(15)
      ..write(obj.dawVersion)
      ..writeByte(16)
      ..write(obj.todos)
      ..writeByte(17)
      ..write(obj.hidden)
      ..writeByte(18)
      ..write(obj.previewSongPath)
      ..writeByte(19)
      ..write(obj.fileCreatedAt)
      ..writeByte(20)
      ..write(obj.statusChangedAt)
      ..writeByte(21)
      ..write(obj.previewSongFileName)
      ..writeByte(22)
      ..write(obj.uploadedPreviewSongHash)
      ..writeByte(23)
      ..write(obj.deadline)
      ..writeByte(24)
      ..write(obj.previewSongAutoPath);
  }
}
