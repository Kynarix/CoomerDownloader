import 'package:flutter/material.dart';
import '../models/download_item.dart';
import '../models/post.dart';
import '../services/download_service.dart';
import '../services/storage_service.dart';

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

  void downloadFile({
    required String url,
    required String filename,
    required String creatorName,
    required String postId,
  }) {
    final item = DownloadItem(
      id: '${DateTime.now().millisecondsSinceEpoch}_${url.hashCode}',
      url: url,
      filename: filename,
      creatorName: creatorName,
      postId: postId,
    );
    _downloadService.addToQueue(item);
    notifyListeners();
  }

  void downloadPost({
    required Post post,
    required String creatorName,
  }) {
    final items = <DownloadItem>[];

    // allFiles kullan (file + files birlesiimi)
    for (var i = 0; i < post.allFiles.length; i++) {
      final file = post.allFiles[i];
      items.add(DownloadItem(
        id: '${DateTime.now().millisecondsSinceEpoch}_${file.url.hashCode}_$i',
        url: file.url,
        filename: file.name,
        creatorName: creatorName,
        postId: post.id,
      ));
    }

    for (var i = 0; i < post.attachments.length; i++) {
      final attachment = post.attachments[i];
      items.add(DownloadItem(
        id: '${DateTime.now().millisecondsSinceEpoch}_${attachment.url.hashCode}_att_$i',
        url: attachment.url,
        filename: attachment.name,
        creatorName: creatorName,
        postId: post.id,
      ));
    }

    _downloadService.addMultipleToQueue(items);
    notifyListeners();
  }

  void downloadAllPosts({
    required List<Post> posts,
    required String creatorName,
  }) {
    for (var post in posts) {
      downloadPost(post: post, creatorName: creatorName);
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
