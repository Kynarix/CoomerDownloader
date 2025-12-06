import 'package:flutter/material.dart';
import '../models/download_item.dart';
import '../models/post.dart';
import '../services/download_service.dart';
import '../services/storage_service.dart';
import '../utils/theme.dart';

class DownloadProvider extends ChangeNotifier {
  final DownloadService _downloadService = DownloadService();
  final StorageService _storageService = StorageService();

  DownloadProvider() {
    _downloadService.onProgressUpdate = _onProgressUpdate;
    _downloadService.onComplete = _onComplete;
    _downloadService.onError = _onError;
    _downloadService.onStateChange = _onStateChange;
  }

  /// Initialize provider with saved data
  Future<void> init() async {
    await _downloadService.init();
    notifyListeners();
  }

  List<DownloadItem> get queue => _downloadService.queue;
  List<DownloadItem> get completed => _downloadService.completed;
  bool get isDownloading => _downloadService.isDownloading;
  bool get isPaused => _downloadService.isPaused;
  int get failedCount => _downloadService.failedCount;

  int get totalInQueue => queue.length;
  int get totalCompleted => completed.length;
  int get activeDownloads => queue.where((i) => i.status == DownloadStatus.downloading).length;
  int get pausedDownloads => queue.where((i) => i.status == DownloadStatus.paused).length;

  void _onProgressUpdate(DownloadItem item) {
    notifyListeners();
  }

  void _onComplete(DownloadItem item) {
    notifyListeners();
  }

  void _onError(DownloadItem item) {
    notifyListeners();
  }

  void _onStateChange() {
    notifyListeners();
  }

  /// URL daha once indirilmis mi kontrol et
  bool isUrlDownloaded(String url) {
    return _downloadService.isUrlDownloaded(url);
  }

  /// Dosya indirilmis mi kontrol et
  Future<bool> isFileDownloaded(String creatorName, String filename) async {
    return await _storageService.isFileDownloaded(creatorName, filename);
  }

  /// Indirilen dosyanin yolunu al
  Future<String?> getDownloadedFilePath(String creatorName, String filename) async {
    return await _storageService.getFilePath(creatorName, filename);
  }

  Future<bool> downloadFile({
    required String url,
    required String filename,
    required String creatorName,
    required String postId,
    BuildContext? context,
  }) async {
    // Zaten indirilmiş mi kontrol et
    final isDownloaded = await isFileDownloaded(creatorName, filename);
    if (isDownloaded) {
      // Uyarı göster
      if (context != null) {
        final shouldDownload = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Icerik Zaten Indirilmis'),
            content: Text(
              '$filename zaten indirilmis. Tekrar indirmek istiyor musunuz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Iptal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.accent,
                ),
                child: const Text('Tekrar Indir'),
              ),
            ],
          ),
        );
        
        if (shouldDownload != true) {
          return false;
        }
      } else {
        // Context yoksa direkt devam et
        return false;
      }
    }
    
    final item = DownloadItem(
      id: '${DateTime.now().millisecondsSinceEpoch}_${url.hashCode}',
      url: url,
      filename: filename,
      creatorName: creatorName,
      postId: postId,
    );
    _downloadService.addToQueue(item);
    notifyListeners();
    return true;
  }

  Future<bool> downloadPost({
    required Post post,
    required String creatorName,
    BuildContext? context,
  }) async {
    // Zaten indirilmiş dosyaları kontrol et
    final alreadyDownloaded = <String>[];
    final toDownload = <DownloadItem>[];

    // allFiles kullan (file + files birlesiimi)
    for (var i = 0; i < post.allFiles.length; i++) {
      final file = post.allFiles[i];
      final isDownloaded = await isFileDownloaded(creatorName, file.name);
      if (isDownloaded) {
        alreadyDownloaded.add(file.name);
      } else {
        toDownload.add(DownloadItem(
          id: '${DateTime.now().millisecondsSinceEpoch}_${file.url.hashCode}_$i',
          url: file.url,
          filename: file.name,
          creatorName: creatorName,
          postId: post.id,
        ));
      }
    }

    for (var i = 0; i < post.attachments.length; i++) {
      final attachment = post.attachments[i];
      final isDownloaded = await isFileDownloaded(creatorName, attachment.name);
      if (isDownloaded) {
        alreadyDownloaded.add(attachment.name);
      } else {
        toDownload.add(DownloadItem(
          id: '${DateTime.now().millisecondsSinceEpoch}_${attachment.url.hashCode}_att_$i',
          url: attachment.url,
          filename: attachment.name,
          creatorName: creatorName,
          postId: post.id,
        ));
      }
    }

    // Eğer bazı dosyalar zaten indirilmişse uyarı göster
    if (alreadyDownloaded.isNotEmpty && context != null) {
      // 0: İptal, 1: Sadece yenileri indir, 2: Tümünü tekrar indir
      final result = await showDialog<int>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Bazi Icerikler Zaten Indirilmis'),
          content: Text(
            '${alreadyDownloaded.length} dosya zaten indirilmis.\n'
            '${toDownload.length} yeni dosya mevcut.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 0),
              child: const Text('Iptal'),
            ),
            if (toDownload.isNotEmpty)
              TextButton(
                onPressed: () => Navigator.pop(ctx, 1),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.info,
                ),
                child: const Text('Sadece Yenileri'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 2),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.accent,
              ),
              child: const Text('Tumunu Indir'),
            ),
          ],
        ),
      );

      if (result == 0 || result == null) {
        return false;
      }

      if (result == 1) {
        // Sadece yeni dosyaları indir
        if (toDownload.isNotEmpty) {
          _downloadService.addMultipleToQueue(toDownload);
          notifyListeners();
        }
        return true;
      }

      // result == 2: Tekrar indirmek istiyorsa tüm dosyaları ekle
      final allItems = <DownloadItem>[];
      for (var i = 0; i < post.allFiles.length; i++) {
        final file = post.allFiles[i];
        allItems.add(DownloadItem(
          id: '${DateTime.now().millisecondsSinceEpoch}_${file.url.hashCode}_$i',
          url: file.url,
          filename: file.name,
          creatorName: creatorName,
          postId: post.id,
        ));
      }
      for (var i = 0; i < post.attachments.length; i++) {
        final attachment = post.attachments[i];
        allItems.add(DownloadItem(
          id: '${DateTime.now().millisecondsSinceEpoch}_${attachment.url.hashCode}_att_$i',
          url: attachment.url,
          filename: attachment.name,
          creatorName: creatorName,
          postId: post.id,
        ));
      }
      _downloadService.addMultipleToQueue(allItems);
      notifyListeners();
      return true;
    }

    // Yeni dosyalar varsa indir
    if (toDownload.isNotEmpty) {
      _downloadService.addMultipleToQueue(toDownload);
      notifyListeners();
    }
    return true;
  }

  Future<void> downloadAllPosts({
    required List<Post> posts,
    required String creatorName,
    BuildContext? context,
  }) async {
    for (var post in posts) {
      await downloadPost(post: post, creatorName: creatorName, context: context);
    }
  }

  /// Tek bir indirmeyi duraklat
  void pauseDownload(String itemId) {
    _downloadService.pauseDownload(itemId);
    notifyListeners();
  }

  /// Tek bir indirmeyi devam ettir
  void resumeDownload(String itemId) {
    _downloadService.resumeDownload(itemId);
    notifyListeners();
  }

  /// Tum indirmeleri duraklat
  void pauseAllDownloads() {
    _downloadService.pauseAllDownloads();
    notifyListeners();
  }

  /// Tum indirmeleri devam ettir
  void resumeAllDownloads() {
    _downloadService.resumeAllDownloads();
    notifyListeners();
  }

  /// Tek bir basarisiz indirmeyi tekrar dene
  void retryDownload(String itemId) {
    _downloadService.retryDownload(itemId);
    notifyListeners();
  }

  void cancelDownload(String itemId) {
    _downloadService.cancelDownload(itemId);
    notifyListeners();
  }

  void cancelAllDownloads() {
    _downloadService.cancelAllDownloads();
    notifyListeners();
  }

  void clearCompleted() {
    _downloadService.clearCompleted();
    notifyListeners();
  }

  void retryFailed() {
    _downloadService.retryFailed();
    notifyListeners();
  }
}
