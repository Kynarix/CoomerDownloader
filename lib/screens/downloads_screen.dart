import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/download_item.dart';
import '../providers/download_provider.dart';
import '../widgets/download_item_widget.dart';
import '../utils/theme.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Indirmeler'),
        actions: [
          Consumer<DownloadProvider>(
            builder: (context, provider, child) {
              if (provider.totalInQueue == 0 && provider.totalCompleted == 0) {
                return const SizedBox();
              }
              return PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'pause_all':
                      provider.pauseAllDownloads();
                      break;
                    case 'resume_all':
                      provider.resumeAllDownloads();
                      break;
                    case 'cancel_all':
                      provider.cancelAllDownloads();
                      break;
                    case 'retry_failed':
                      provider.retryFailed();
                      break;
                    case 'clear_completed':
                      provider.clearCompleted();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  // Pause/Resume all
                  if (provider.isDownloading && !provider.isPaused)
                    const PopupMenuItem(
                      value: 'pause_all',
                      child: Row(
                        children: [
                          Icon(Icons.pause_rounded, size: 20),
                          SizedBox(width: 12),
                          Text('Tumunu Duraklat'),
                        ],
                      ),
                    ),
                  if (provider.isPaused || provider.pausedDownloads > 0)
                    const PopupMenuItem(
                      value: 'resume_all',
                      child: Row(
                        children: [
                          Icon(Icons.play_arrow_rounded, size: 20),
                          SizedBox(width: 12),
                          Text('Tumunu Devam Ettir'),
                        ],
                      ),
                    ),
                  if (provider.totalInQueue > 0)
                    const PopupMenuItem(
                      value: 'cancel_all',
                      child: Row(
                        children: [
                          Icon(Icons.cancel_outlined, size: 20),
                          SizedBox(width: 12),
                          Text('Tumunu Iptal Et'),
                        ],
                      ),
                    ),
                  if (provider.failedCount > 0)
                    PopupMenuItem(
                      value: 'retry_failed',
                      child: Row(
                        children: [
                          const Icon(Icons.refresh, size: 20, color: AppTheme.accent),
                          const SizedBox(width: 12),
                          Text(
                            'Basarisizlari Yeniden Dene (${provider.failedCount})',
                            style: const TextStyle(color: AppTheme.accent),
                          ),
                        ],
                      ),
                    ),
                  if (provider.totalCompleted > 0)
                    const PopupMenuItem(
                      value: 'clear_completed',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 20),
                          SizedBox(width: 12),
                          Text('Tamamlananlari Temizle'),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<DownloadProvider>(
        builder: (context, provider, child) {
          if (provider.totalInQueue == 0 && provider.totalCompleted == 0) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.download_outlined,
                    size: 80,
                    color: isDark
                        ? AppTheme.textSecondaryDark.withOpacity(0.3)
                        : AppTheme.textSecondaryLight.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Indirme yok',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Indirdikleriniz burada gorunecek',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Global controls
              if (provider.totalInQueue > 0) ...[
                _buildGlobalControls(context, provider, isDark),
                const SizedBox(height: 16),
              ],
              
              // Failed downloads section
              if (provider.failedCount > 0) ...[
                _buildFailedSection(context, provider, isDark),
                const SizedBox(height: 24),
              ],
              
              // Active downloads
              if (provider.queue.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kuyruk (${provider.activeDownloads}/${provider.totalInQueue})',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (provider.isDownloading && !provider.isPaused)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (provider.isPaused)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Duraklatildi',
                          style: TextStyle(
                            color: AppTheme.warning,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                ...provider.queue.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: DownloadItemWidget(
                        item: item,
                        onCancel: () => provider.cancelDownload(item.id),
                        onPause: () => provider.pauseDownload(item.id),
                        onResume: () => provider.resumeDownload(item.id),
                        onRetry: () => provider.retryDownload(item.id),
                      ),
                    )),
                const SizedBox(height: 24),
              ],
              
              // Completed downloads
              if (provider.completed.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tamamlanan (${provider.totalCompleted})',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () => provider.clearCompleted(),
                      child: Text(
                        'Temizle',
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...provider.completed.reversed.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: DownloadItemWidget(item: item),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildGlobalControls(BuildContext context, DownloadProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: provider.isPaused 
                  ? AppTheme.warning.withOpacity(0.1)
                  : AppTheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              provider.isPaused ? Icons.pause_rounded : Icons.download_rounded,
              color: provider.isPaused ? AppTheme.warning : AppTheme.accent,
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
                  provider.isPaused ? 'Indirmeler Duraklatildi' : 'Indiriliyor',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${provider.activeDownloads} aktif, ${provider.pausedDownloads} duraklatildi, ${provider.failedCount} basarisiz',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          // Control buttons
          if (provider.isPaused || provider.pausedDownloads > 0)
            ElevatedButton.icon(
              onPressed: () => provider.resumeAllDownloads(),
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Devam'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: () => provider.pauseAllDownloads(),
              icon: const Icon(Icons.pause_rounded, size: 18),
              label: const Text('Duraklat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warning,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFailedSection(BuildContext context, DownloadProvider provider, bool isDark) {
    final failedItems = provider.queue.where((i) => i.status == DownloadStatus.failed).toList();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
              const SizedBox(width: 8),
              Text(
                '${failedItems.length} indirme basarisiz oldu',
                style: const TextStyle(
                  color: AppTheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => provider.retryFailed(),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Tumunu Dene'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
