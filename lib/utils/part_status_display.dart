import 'package:flutter/material.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/project_part.dart';

/// Presentation for [PartTakeStatus] — the translated label, the badge colour
/// and the icon — kept in one place so the parts list, the plain text export
/// and the CSV export can never drift apart on what a status is called.
extension PartTakeStatusDisplay on PartTakeStatus {
  String label(AppLocalizations l10n) {
    switch (this) {
      case PartTakeStatus.needed:
        return l10n.partStatusNeeded;
      case PartTakeStatus.recording:
        return l10n.partStatusRecording;
      case PartTakeStatus.earlyTake:
        return l10n.partStatusEarlyTake;
      case PartTakeStatus.finalTake:
        return l10n.partStatusFinalTake;
    }
  }

  /// Progresses grey → amber → blue → green, so a glance down the list reads
  /// as "how far along is this song".
  Color get color {
    switch (this) {
      case PartTakeStatus.needed:
        return const Color(0xFF9E9E9E);
      case PartTakeStatus.recording:
        return const Color(0xFFFFA726);
      case PartTakeStatus.earlyTake:
        return const Color(0xFF42A5F5);
      case PartTakeStatus.finalTake:
        return const Color(0xFF66BB6A);
    }
  }

  IconData get icon {
    switch (this) {
      case PartTakeStatus.needed:
        return Icons.radio_button_unchecked;
      case PartTakeStatus.recording:
        return Icons.fiber_manual_record;
      case PartTakeStatus.earlyTake:
        return Icons.hourglass_bottom;
      case PartTakeStatus.finalTake:
        return Icons.check_circle;
    }
  }
}
