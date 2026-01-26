import 'package:flutter/material.dart';
import '../models/backup_progress.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Dialog for showing backup download progress (Mobile)
class DownloadProgressDialog extends StatelessWidget {
  final Stream<BackupProgress> progressStream;

  const DownloadProgressDialog({
    super.key,
    required this.progressStream,
  });

  String _getStageText(BackupProgressStage stage, BuildContext context) {
    switch (stage) {
      case BackupProgressStage.downloadingDatabase:
        return AppLocalizations.of(context)!.downloadingDatabase;
      case BackupProgressStage.downloadingPreviewSongs:
        return AppLocalizations.of(context)!.downloadingPreviewSongs;
      case BackupProgressStage.downloadingProfilePhotos:
        return AppLocalizations.of(context)!.downloadingProfilePhotos;
      case BackupProgressStage.mergingData:
        return AppLocalizations.of(context)!.mergingData;
      case BackupProgressStage.completed:
        return AppLocalizations.of(context)!.completed;
      default:
        return AppLocalizations.of(context)!.mergingData;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: Row(
        children: [
          const Icon(Icons.cloud_download, size: 24),
          const SizedBox(width: 8),
          Text(AppLocalizations.of(context)!.downloadingBackupTitle),
        ],
      ),
      content: StreamBuilder<BackupProgress>(
        stream: progressStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox(
              height: 150,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final progress = snapshot.data!;
          final percentage = (progress.progress * 100).toStringAsFixed(0);

          return SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stage indicator
                Text(
                  _getStageText(progress.stage, context),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Progress indicator with counter
                if (progress.totalItems > 0)
                  Text(
                    '${progress.currentIndex} / ${progress.totalItems}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                    ),
                  ),
                if (progress.totalItems > 0) const SizedBox(height: 8),
                
                // Progress bar
                LinearProgressIndicator(
                  value: progress.progress,
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                
                // Percentage
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
