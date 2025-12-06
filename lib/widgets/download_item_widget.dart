import 'package:flutter/material.dart';
import '../models/download_item.dart';
import '../utils/theme.dart';

class DownloadItemWidget extends StatelessWidget {
  final DownloadItem item;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;
  final VoidCallback? onPause;
  final VoidCallback? onResume;

  const DownloadItemWidget({
    super.key,
    required this.item,
    this.onCancel,
    this.onRetry,
    this.onPause,
    this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getIcon(),
              color: _getStatusColor(),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.filename,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      item.creatorName,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.statusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusColor(),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // Size info
                if (item.formattedSize.isNotEmpty && 
                    (item.status == DownloadStatus.downloading || 
                     item.status == DownloadStatus.paused)) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.formattedSize,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
                // Progress bar
                if (item.status == DownloadStatus.downloading || 
                    item.status == DownloadStatus.paused) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: item.progress,
                      backgroundColor: isDark
                          ? Colors.grey[800]
                          : Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        item.status == DownloadStatus.paused 
                            ? AppTheme.warning 
                            : AppTheme.accent,
                      ),
                      minHeight: 4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Action buttons
          _buildActionButtons(isDark),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    switch (item.status) {
      case DownloadStatus.downloading:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pause button
            IconButton(
              onPressed: onPause,
              icon: const Icon(Icons.pause_rounded),
              iconSize: 20,
              color: AppTheme.warning,
              tooltip: 'Duraklat',
            ),
            // Cancel button
            IconButton(
              onPressed: onCancel,
              icon: const Icon(Icons.close),
              iconSize: 20,
              color: isDark
                  ? AppTheme.textSecondaryDark
                  : AppTheme.textSecondaryLight,
              tooltip: 'Iptal',
            ),
          ],
        );
      
      case DownloadStatus.paused:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Resume button
            IconButton(
              onPressed: onResume,
              icon: const Icon(Icons.play_arrow_rounded),
              iconSize: 20,
              color: AppTheme.success,
              tooltip: 'Devam Et',
            ),
            // Cancel button
            IconButton(
              onPressed: onCancel,
              icon: const Icon(Icons.close),
              iconSize: 20,
              color: isDark
                  ? AppTheme.textSecondaryDark
                  : AppTheme.textSecondaryLight,
              tooltip: 'Iptal',
            ),
          ],
        );
      
      case DownloadStatus.pending:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pause button
            IconButton(
              onPressed: onPause,
              icon: const Icon(Icons.pause_rounded),
              iconSize: 20,
              color: AppTheme.warning,
              tooltip: 'Duraklat',
            ),
            // Cancel button
            IconButton(
              onPressed: onCancel,
              icon: const Icon(Icons.close),
              iconSize: 20,
              color: isDark
                  ? AppTheme.textSecondaryDark
                  : AppTheme.textSecondaryLight,
              tooltip: 'Iptal',
            ),
          ],
        );
      
      case DownloadStatus.failed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Retry button
            IconButton(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              iconSize: 20,
              color: AppTheme.accent,
              tooltip: 'Tekrar Dene',
            ),
            // Cancel button
            IconButton(
              onPressed: onCancel,
              icon: const Icon(Icons.close),
              iconSize: 20,
              color: isDark
                  ? AppTheme.textSecondaryDark
                  : AppTheme.textSecondaryLight,
              tooltip: 'Kaldir',
            ),
          ],
        );
      
      case DownloadStatus.completed:
        return IconButton(
          onPressed: () {},
          icon: const Icon(Icons.check_circle),
          iconSize: 20,
          color: AppTheme.success,
        );
      
      case DownloadStatus.cancelled:
        return IconButton(
          onPressed: onCancel,
          icon: const Icon(Icons.close),
          iconSize: 20,
          color: isDark
              ? AppTheme.textSecondaryDark
              : AppTheme.textSecondaryLight,
        );
    }
  }

  IconData _getIcon() {
    if (item.isImage) return Icons.image_outlined;
    if (item.isVideo) return Icons.videocam_outlined;
    return Icons.insert_drive_file_outlined;
  }

  Color _getStatusColor() {
    switch (item.status) {
      case DownloadStatus.pending:
        return AppTheme.info;
      case DownloadStatus.downloading:
        return AppTheme.accent;
      case DownloadStatus.paused:
        return AppTheme.warning;
      case DownloadStatus.completed:
        return AppTheme.success;
      case DownloadStatus.failed:
        return AppTheme.error;
      case DownloadStatus.cancelled:
        return AppTheme.warning;
    }
  }
}
