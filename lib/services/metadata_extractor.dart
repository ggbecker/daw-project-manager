import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

/// Represents a scale pair (root note and scale type)
class _ScalePair {
  final int root;
  final int name;

  _ScalePair(this.root, this.name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ScalePair &&
          runtimeType == other.runtimeType &&
          root == other.root &&
          name == other.name;

  @override
  int get hashCode => root.hashCode ^ name.hashCode;
}

class ProjectMetadata {
  final double? bpm;
  final String? key;
  final String? dawType;
  final String? dawVersion;

  ProjectMetadata({
    this.bpm,
    this.key,
    this.dawType,
    this.dawVersion,
  });
}

class MetadataExtractor {
  /// Extracts lightweight metadata (DAW type only) - fast, no file parsing
  static Future<ProjectMetadata> extractLightweightMetadata(String filePath) async {
    final ext = p.extension(filePath).toLowerCase();
    final dawType = _getDawTypeFromExtension(ext);
    
    return ProjectMetadata(
      bpm: null,
      key: null,
      dawType: dawType,
      dawVersion: null,
    );
  }

  /// Extracts full metadata from a project file (BPM, key, DAW version)
  static Future<ProjectMetadata> extractMetadata(String filePath) async {
    final ext = p.extension(filePath).toLowerCase();
    final projectDir = File(filePath).parent;
    
    // Determine DAW type from extension
    final dawType = _getDawTypeFromExtension(ext);
    
    double? bpm;
    String? key;
    String? dawVersion;

    // Try to extract from project file first
    if (ext == '.als' || ext == '.alp') {
      final metadata = await _extractFromAbletonFile(filePath);
      bpm = metadata.bpm ?? bpm;
      key = metadata.key ?? key;
      dawVersion = metadata.dawVersion ?? dawVersion;
    } else if (ext == '.cpr' || ext == '.npr') {
      // Nuendo uses similar format to Cubase
      final metadata = await _extractFromCubaseFile(filePath);
      bpm = metadata.bpm ?? bpm;
      key = metadata.key ?? key;
      dawVersion = metadata.dawVersion ?? dawVersion;
    }

    // Also search for bpm and key files in the project directory
    final bpmFromFile = await _searchForBpmFile(projectDir.path);
    if (bpmFromFile != null) {
      bpm = bpmFromFile;
    }

    final keyFromFile = await _searchForKeyFile(projectDir.path);
    if (keyFromFile != null) {
      key = keyFromFile;
    }

    return ProjectMetadata(
      bpm: bpm,
      key: key,
      dawType: dawType,
      dawVersion: dawVersion,
    );
  }

  /// Determines DAW type from file extension
  static String? _getDawTypeFromExtension(String ext) {
    switch (ext) {
      case '.als':
      case '.alp':
        return 'Ableton Live';
      case '.bwproject':
        return 'Bitwig Studio';
      case '.cpr':
        return 'Cubase';
      case '.flp':
        return 'FL Studio';
      case '.logicx':
        return 'Logic Pro';
      case '.maschine':
      case '.maschine2':
        return 'Maschine';
      case '.npr':
        return 'Nuendo';
      case '.ptx':
      case '.pts':
        return 'Pro Tools';
      case '.rpp':
        return 'Reaper';
      case '.song':
        return 'Studio One';
      default:
        return null;
    }
  }

  /// Extracts BPM and key from Ableton Live .als file
  /// .als files are gzipped XML files (or uncompressed XML in older versions)
  static Future<ProjectMetadata> _extractFromAbletonFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ProjectMetadata();
      }

      // Read the file as bytes
      final bytes = await file.readAsBytes();
      
      // Try to decompress as gzip first, fallback to direct UTF-8 if it fails
      String xmlString;
      try {
        final decompressed = gzip.decode(bytes);
        xmlString = utf8.decode(decompressed);
      } catch (_) {
        // If gzip decode fails, try reading as plain UTF-8 (older .als files)
        xmlString = utf8.decode(bytes);
      }
      
      // Parse XML
      final document = XmlDocument.parse(xmlString);
      final root = document.rootElement;

      double? bpm;
      String? key;
      String? dawVersion;

      // Extract version from MinorVersion attribute
      final minorVersion = root.getAttribute('MinorVersion');
      if (minorVersion != null && minorVersion.isNotEmpty) {
        // Extract major version (e.g., "12.0_12300" -> "12")
        final parts = minorVersion.split('.');
        if (parts.isNotEmpty) {
          dawVersion = parts[0];
        }
      }

      // Extract BPM - look for Tempo element with Manual child
      final tempoElements = root.findAllElements('Tempo');
      if (tempoElements.isNotEmpty) {
        final tempoElement = tempoElements.first;
        // Look for Manual element inside Tempo
        final manualElements = tempoElement.findElements('Manual');
        if (manualElements.isNotEmpty) {
          final manualElement = manualElements.first;
          final tempoValue = manualElement.getAttribute('Value');
          if (tempoValue != null) {
            bpm = double.tryParse(tempoValue);
          }
        }
        // Fallback: try direct Value attribute on Tempo element
        if (bpm == null) {
          final tempoValue = tempoElement.getAttribute('Value');
          if (tempoValue != null) {
            bpm = double.tryParse(tempoValue);
          }
        }
      }

      // Also try ManualTimeSignature element which might have BPM
      if (bpm == null) {
        final timeSigElements = root.findAllElements('ManualTimeSignature');
        for (final element in timeSigElements) {
          final tempoValue = element.getAttribute('Tempo');
          if (tempoValue != null) {
            final parsed = double.tryParse(tempoValue);
            if (parsed != null) {
              bpm = parsed;
              break;
            }
          }
        }
      }

      // Extract key from ScaleInformation elements (iterate over all instances)
      final scaleInfoElements = root.findAllElements('ScaleInformation').toList();
      
      if (scaleInfoElements.isNotEmpty) {
        final scalePairs = <_ScalePair>[];
        
        // Extract Root and Name from each ScaleInformation instance
        for (final scaleInfoElement in scaleInfoElements) {
          // Extract Root note (0-11)
          final rootElements = scaleInfoElement.findElements('Root');
          int? rootValue;
          if (rootElements.isNotEmpty) {
            final rootElement = rootElements.first;
            // Try Value attribute first, then text content
            final rootValueStr = rootElement.getAttribute('Value') ?? rootElement.innerText.trim();
            if (rootValueStr.isNotEmpty) {
              rootValue = int.tryParse(rootValueStr);
            }
          }
          
          // Extract Scale type/Name (0-34)
          final nameElements = scaleInfoElement.findElements('Name');
          int? nameValue;
          if (nameElements.isNotEmpty) {
            final nameElement = nameElements.first;
            // Try Value attribute first, then text content
            final nameValueStr = nameElement.getAttribute('Value') ?? nameElement.innerText.trim();
            if (nameValueStr.isNotEmpty) {
              nameValue = int.tryParse(nameValueStr);
            }
          }
          
          // Only add non-zero pairs (0,0 means C Major default/unset)
          if (rootValue != null && nameValue != null) {
            if (rootValue != 0 || nameValue != 0) {
              scalePairs.add(_ScalePair(rootValue, nameValue));
            }
          }
        }
        
        // Process the collected scale pairs
        if (scalePairs.isNotEmpty) {
          // Get unique pairs
          final uniquePairs = scalePairs.toSet();
          
          if (uniquePairs.length == 1) {
            // All non-zero instances have the same value
            final pair = uniquePairs.first;
            final rootNote = _getRootNote(pair.root);
            final scaleType = _getScaleType(pair.name);
            if (rootNote != null && scaleType != null) {
              key = '$rootNote $scaleType';
            }
          } else {
            // Multiple different values - combine them with commas
            final keyParts = <String>[];
            for (final pair in uniquePairs) {
              final rootNote = _getRootNote(pair.root);
              final scaleType = _getScaleType(pair.name);
              if (rootNote != null && scaleType != null) {
                keyParts.add('$rootNote $scaleType');
              }
            }
            if (keyParts.isNotEmpty) {
              key = keyParts.join(', ');
            }
          }
        }
      }

      // Fallback: look for MusicalKey or KeySignature elements
      if (key == null || key.isEmpty) {
        final keyElements = root.findAllElements('MusicalKey');
        if (keyElements.isNotEmpty) {
          final keyElement = keyElements.first;
          key = keyElement.getAttribute('Value') ?? keyElement.innerText;
        }
      }

      // Try alternative key element names
      if (key == null || key.isEmpty) {
        final keySigElements = root.findAllElements('KeySignature');
        if (keySigElements.isNotEmpty) {
          final keySigElement = keySigElements.first;
          key = keySigElement.getAttribute('Value') ?? keySigElement.innerText;
        }
      }

      // Try to find key in MasterTrack or other common locations
      if (key == null || key.isEmpty) {
        final masterTrack = root.findAllElements('MasterTrack');
        for (final track in masterTrack) {
          final keyAttr = track.getAttribute('MusicalKey') ?? track.getAttribute('Key');
          if (keyAttr != null && keyAttr.isNotEmpty) {
            key = keyAttr;
            break;
          }
        }
      }

      return ProjectMetadata(
        bpm: bpm,
        key: key?.trim().isEmpty == true ? null : key?.trim(),
        dawVersion: dawVersion,
      );
    } catch (e) {
      // If parsing fails, return empty metadata
      return ProjectMetadata();
    }
  }

  /// Extracts version and BPM from Cubase .cpr file
  /// Version: Looks for hex pattern: 00 10 56 65 72 73 69 6F 6E (which is "00 10 Version")
  /// BPM: Looks for "MusicalTempo" tag followed by "Float" type, then reads 8 bytes as IEEE 754 double
  static Future<ProjectMetadata> _extractFromCubaseFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ProjectMetadata();
      }

      // Read file as bytes
      final bytes = await file.readAsBytes();
      
      String? dawVersion;
      double? bpm;
      
      // === Extract DAW Version ===
      // Hex pattern: 00 10 56 65 72 73 69 6F 6E (which is "00 10 Version" in ASCII)
      final versionPattern = [0x00, 0x10, 0x56, 0x65, 0x72, 0x73, 0x69, 0x6F, 0x6E];
      
      // Find the pattern in the file
      int? patternIndex;
      for (int i = 0; i <= bytes.length - versionPattern.length; i++) {
        bool found = true;
        for (int j = 0; j < versionPattern.length; j++) {
          if (bytes[i + j] != versionPattern[j]) {
            found = false;
            break;
          }
        }
        if (found) {
          patternIndex = i;
          break;
        }
      }
      
      if (patternIndex != null) {
        // Skip the pattern (9 bytes) and look for version string
        // Version typically starts with a space (0x20) followed by digits and dots
        int versionStart = patternIndex + versionPattern.length;
        
        // Find the start of the version (skip whitespace if any)
        while (versionStart < bytes.length && bytes[versionStart] == 0x20) {
          versionStart++;
        }
        
        // Extract version string until we hit a null byte or non-printable character
        final versionBytes = <int>[];
        for (int i = versionStart; i < bytes.length; i++) {
          final byte = bytes[i];
          // Stop at null byte or non-printable characters (except space, dot, digits)
          if (byte == 0x00 || (byte < 0x20 && byte != 0x09 && byte != 0x0A && byte != 0x0D)) {
            break;
          }
          // Include space, dot, digits, and letters
          if ((byte >= 0x20 && byte <= 0x7E) || byte == 0x09 || byte == 0x0A || byte == 0x0D) {
            versionBytes.add(byte);
          } else {
            break;
          }
        }
        
        if (versionBytes.isNotEmpty) {
          // Convert to string and extract major version
          final versionString = utf8.decode(versionBytes).trim();
          // Extract major version (e.g., "13.0.4" -> "13")
          final parts = versionString.split('.');
          if (parts.isNotEmpty) {
            dawVersion = parts[0].trim();
          }
        }
      }
      
      // === Extract BPM from MusicalTempo metadata ===
      // Cubase stores tempo as a 64-bit double-precision float (IEEE 754, big-endian)
      // The format is: "MusicalTempo" ... "Float" ... [8 bytes of tempo value]
      bpm = _extractCubaseBpm(bytes);
      
      // === Extract Key/Scale from MusicalSignature metadata ===
      // The key is stored in a CmRational object after the MusicalSignature tag
      final key = _extractCubaseKey(bytes);
      
      return ProjectMetadata(bpm: bpm, key: key, dawVersion: dawVersion);
    } catch (e) {
      // If parsing fails, return empty metadata
      return ProjectMetadata();
    }
  }
  
  /// Extracts BPM from Cubase file by searching for MusicalTempo metadata
  /// The tempo is stored as IEEE 754 64-bit double (big-endian) after the "Float" type indicator
  static double? _extractCubaseBpm(Uint8List bytes) {
    try {
      // Search for "MusicalTempo" string in the binary file
      final musicalTempoTag = utf8.encode('MusicalTempo');
      final floatTag = utf8.encode('Float');
      
      int? musicalTempoIndex;
      for (int i = 0; i <= bytes.length - musicalTempoTag.length; i++) {
        bool found = true;
        for (int j = 0; j < musicalTempoTag.length; j++) {
          if (bytes[i + j] != musicalTempoTag[j]) {
            found = false;
            break;
          }
        }
        if (found) {
          musicalTempoIndex = i;
          break;
        }
      }
      
      if (musicalTempoIndex == null) {
        return null;
      }
      
      // Search for "Float" type indicator after MusicalTempo
      // Limit search to a reasonable range (e.g., 100 bytes after the tag)
      final searchEnd = (musicalTempoIndex + musicalTempoTag.length + 100).clamp(0, bytes.length);
      int? floatIndex;
      
      for (int i = musicalTempoIndex + musicalTempoTag.length; i <= searchEnd - floatTag.length; i++) {
        bool found = true;
        for (int j = 0; j < floatTag.length; j++) {
          if (bytes[i + j] != floatTag[j]) {
            found = false;
            break;
          }
        }
        if (found) {
          floatIndex = i;
          break;
        }
      }
      
      if (floatIndex == null) {
        return null;
      }
      
      // After "Float", skip padding bytes (typically 2-4 bytes) and read the 8-byte double value
      // The exact offset may vary, so we'll try a few common offsets
      final possibleOffsets = [2, 3, 4, 5, 6];
      
      for (final offset in possibleOffsets) {
        final valueStart = floatIndex + floatTag.length + offset;
        
        if (valueStart + 8 > bytes.length) {
          continue;
        }
        
        // Read 8 bytes as big-endian IEEE 754 double
        final byteData = ByteData.sublistView(bytes, valueStart, valueStart + 8);
        final tempoValue = byteData.getFloat64(0, Endian.big);
        
        // Validate: BPM should be in a reasonable range (e.g., 20-999)
        if (tempoValue >= 20.0 && tempoValue <= 999.0) {
          // Round to 2 decimal places for cleaner display
          return double.parse(tempoValue.toStringAsFixed(2));
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// Extracts key/scale from Cubase file by searching for MusicalSignature metadata
  /// The key is stored in a CmRational object with the following structure:
  /// CmRational (10 bytes) + null (1 byte) + scale_field (4 bytes) + key_root (4 bytes)
  /// - Scale type is at offset +4: 0x00 = Major, 0x02 = Minor
  /// - Key root identifier is at offset +5 to +8 (4 bytes)
  static String? _extractCubaseKey(Uint8List bytes) {
    try {
      // Search for "MusicalSignature" string in the binary file
      final musicalSigTag = utf8.encode('MusicalSignature');
      final cmRationalTag = utf8.encode('CmRational');
      
      int? musicalSigIndex;
      for (int i = 0; i <= bytes.length - musicalSigTag.length; i++) {
        bool found = true;
        for (int j = 0; j < musicalSigTag.length; j++) {
          if (bytes[i + j] != musicalSigTag[j]) {
            found = false;
            break;
          }
        }
        if (found) {
          musicalSigIndex = i;
          break;
        }
      }
      
      if (musicalSigIndex == null) {
        return null;
      }
      
      // Search for "CmRational" type indicator after MusicalSignature
      // Limit search to a reasonable range (e.g., 200 bytes after the tag)
      final searchEnd = (musicalSigIndex + musicalSigTag.length + 200).clamp(0, bytes.length);
      int? cmRationalIndex;
      
      for (int i = musicalSigIndex + musicalSigTag.length; i <= searchEnd - cmRationalTag.length; i++) {
        bool found = true;
        for (int j = 0; j < cmRationalTag.length; j++) {
          if (bytes[i + j] != cmRationalTag[j]) {
            found = false;
            break;
          }
        }
        if (found) {
          cmRationalIndex = i;
          break;
        }
      }
      
      if (cmRationalIndex == null) {
        return null;
      }
      
      // Structure after CmRational (10 bytes):
      // Offset +0: 1 null byte
      // Offset +1-4: 4-byte field, last byte (offset +4) is scale type (00=Major, 02=Minor)
      // Offset +5-8: 4-byte key root identifier
      final dataStart = cmRationalIndex + cmRationalTag.length;
      
      if (dataStart + 9 > bytes.length) {
        return null;
      }
      
      // Read scale type flag at offset +4
      final scaleFlag = bytes[dataStart + 4];
      final isMinor = scaleFlag == 0x02;
      
      // Read 4-byte key root pattern at offset +5
      final keyRootBytes = bytes.sublist(dataStart + 5, dataStart + 9);
      final keyRootHex = keyRootBytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');
      
      // Look up the key root in known patterns
      final keyRoot = _getCubaseKeyRoot(keyRootHex);
      
      if (keyRoot != null) {
        // Combine key root with scale type
        final scaleType = isMinor ? 'Minor' : 'Major';
        return '$keyRoot $scaleType';
      }
      
      // If we don't recognize the root pattern but know the scale type,
      // try to decode it mathematically
      return _decodeCubaseKeyPattern(keyRootBytes, isMinor);
    } catch (e) {
      return null;
    }
  }
  
  /// Known Cubase key root patterns (from binary analysis)
  /// Maps 4-byte hex pattern to root note name
  static String? _getCubaseKeyRoot(String hexPattern) {
    // These patterns were extracted from actual .cpr files
    // The encoding appears to be a complex format, not simple indices
    const knownRoots = {
      // C root patterns (from c_major.cpr, 145bpm.cpr)
      '3D 10 04 10': 'C',
      '39 88 15 50': 'C',  // Alternative C pattern (from 135bpm.cpr)
      '39 88 20 50': 'C',  // Another C variant
      
      // D root patterns
      '3C 4A D8 A0': 'D',  // D Major pattern (from d_major.cpr)
      'B3 D6 64 40': 'D',  // D Minor pattern (from d_minor.cpr)
      '3B 37 A6 10': 'D',  // D Minor alternative (from 120d_minor.cpr)
      
      // Additional patterns to be discovered...
      // Note: The same root note can have different patterns depending on
      // whether it's Major or Minor, suggesting the encoding is complex
    };
    
    return knownRoots[hexPattern];
  }
  
  /// Attempts to decode Cubase key pattern mathematically
  /// This is a fallback when the pattern isn't in our known list
  static String? _decodeCubaseKeyPattern(List<int> keyRootBytes, bool isMinor) {
    if (keyRootBytes.length < 4) return null;
    
    // The CmRational encoding is complex and doesn't follow a simple pattern
    // Different root notes have vastly different byte patterns
    // For now, we can only reliably determine Major vs Minor from the flag
    
    // If we have valid bytes but don't recognize the pattern,
    // we could return just the scale type
    // But it's better to return null than an incomplete result
    
    return null;
  }

  /// Searches for BPM information in text files
  static Future<double?> _searchForBpmFile(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      return null;
    }

    final patterns = ['bpm', 'bpm.txt', 'bpm.log', 'tempo', 'tempo.txt'];
    
    for (final pattern in patterns) {
      try {
        final file = File(p.join(directoryPath, pattern));
        if (await file.exists()) {
          final content = await file.readAsString();
          final trimmed = content.trim();
          final bpm = double.tryParse(trimmed);
          if (bpm != null && bpm > 0 && bpm < 1000) {
            return bpm;
          }
        }
      } catch (_) {
        // Continue searching
      }
    }

    // Also search in subdirectories (limited depth)
    try {
      await for (final entity in directory.list(recursive: false)) {
        if (entity is File) {
          final fileName = p.basename(entity.path).toLowerCase();
          if (patterns.any((p) => fileName.contains(p))) {
            try {
              final content = await entity.readAsString();
              final trimmed = content.trim();
              final bpm = double.tryParse(trimmed);
              if (bpm != null && bpm > 0 && bpm < 1000) {
                return bpm;
              }
            } catch (_) {
              // Continue
            }
          }
        }
      }
    } catch (_) {
      // Ignore errors
    }

    return null;
  }

  /// Searches for key information in text files
  static Future<String?> _searchForKeyFile(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      return null;
    }

    final patterns = ['key', 'key.txt', 'key.log', 'musicalkey', 'musicalkey.txt'];
    
    for (final pattern in patterns) {
      try {
        final file = File(p.join(directoryPath, pattern));
        if (await file.exists()) {
          final content = await file.readAsString();
          final trimmed = content.trim();
          if (trimmed.isNotEmpty) {
            return trimmed;
          }
        }
      } catch (_) {
        // Continue searching
      }
    }

    // Also search in subdirectories (limited depth)
    try {
      await for (final entity in directory.list(recursive: false)) {
        if (entity is File) {
          final fileName = p.basename(entity.path).toLowerCase();
          if (patterns.any((p) => fileName.contains(p))) {
            try {
              final content = await entity.readAsString();
              final trimmed = content.trim();
              if (trimmed.isNotEmpty) {
                return trimmed;
              }
            } catch (_) {
              // Continue
            }
          }
        }
      }
    } catch (_) {
      // Ignore errors
    }

    return null;
  }

  /// Maps root note integer (0-11) to note name
  static String? _getRootNote(int value) {
    const rootNotes = [
      "C",
      "C#/Db",
      "D",
      "D#/Eb",
      "E",
      "F",
      "F#/Gb",
      "G",
      "G#/Ab",
      "A",
      "A#/Bb",
      "B"
    ];
    if (value >= 0 && value < rootNotes.length) {
      return rootNotes[value];
    }
    return null;
  }

  /// Maps scale type integer (0-34) to scale name
  static String? _getScaleType(int value) {
    const scaleTypes = [
      "Major",
      "Minor",
      "Dorian",
      "Mixolydian",
      "Lydian",
      "Phrygian",
      "Locrian",
      "Whole Tone",
      "Half-whole Dim.",
      "Whole-half Dim.",
      "Minor Blues",
      "Minor Pentatonic",
      "Major Pentatonic",
      "Harmonic Minor",
      "Harmonic Major",
      "Dorian ♯4",
      "Phrygian Dominant",
      "Melodic Minor",
      "Lydian Augmented",
      "Lydian Dominant",
      "Super Locrian",
      "8-Tone Spanish",
      "Bhairav",
      "Hungarian Minor",
      "Hirajoshi",
      "In-Sen",
      "Iwato",
      "Kumoi",
      "Pelog Selisir",
      "Pelog Tembung",
      "Messiaen 3",
      "Messiaen 4",
      "Messiaen 5",
      "Messiaen 6",
      "Messiaen 7"
    ];
    if (value >= 0 && value < scaleTypes.length) {
      return scaleTypes[value];
    }
    return null;
  }
}

