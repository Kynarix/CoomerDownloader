import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/download_item.dart';
import 'storage_service.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(minutes: 10),
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    },
  ));

  final StorageService _storageService = StorageService();
  SharedPreferences? _prefs;

  static const String _keyCompletedDownloads = 'completed_downloads';
  static const String _keyDownloadedUrls = 'downloaded_urls';

  final List<DownloadItem> _queue = [];
  final List<DownloadItem> _completed = [];
  final Set<String> _downloadedUrls = {};
  final Map<String, CancelToken> _cancelTokens = {};
  
  bool _isDownloading = false;
  bool _isPaused = false;
  static const int _maxConcurrent = 3;
  int _activeDownloads = 0;

  List<DownloadItem> get queue => List.unmodifiable(_queue);
  List<DownloadItem> get completed => List.unmodifiable(_completed);
  Set<String> get downloadedUrls => Set.unmodifiable(_downloadedUrls);
  bool get isDownloading => _isDownloading;
  bool get isPaused => _isPaused;
  int get failedCount => _queue.where((i) => i.status == DownloadStatus.failed).length;

  Function(DownloadItem)? onProgressUpdate;
  Function(DownloadItem)? onComplete;
  Function(DownloadItem)? onError;
  Function()? onStateChange;

  /// Initialize service with saved data
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    if (_prefs == null) return;

    // Load completed downloads
    final completedJson = _prefs!.getStringList(_keyCompletedDownloads) ?? [];
    _completed.clear();
    for (final json in completedJson) {
      try {
        final map = jsonDecode(json) as Map<String, dynamic>;
        final item = DownloadItem.fromJson(map);
        // Dosya hala mevcut mu kontrol et
        if (item.localPath != null && await File(item.localPath!).exists()) {
          _completed.add(item);
          _downloadedUrls.add(item.url);
        }
      } catch (e) {
        print('[DownloadService] Error loading download: $e');
      }
    }

    // Load downloaded URLs
    final urls = _prefs!.getStringList(_keyDownloadedUrls) ?? [];
    _downloadedUrls.addAll(urls);

    print('[DownloadService] Loaded ${_completed.length} completed downloads');
  }

  Future<void> _saveCompletedDownloads() async {
    if (_prefs == null) return;
    final jsonList = _completed.map((item) => jsonEncode(item.toJson())).toList();
    await _prefs!.setStringList(_keyCompletedDownloads, jsonList);
    await _prefs!.setStringList(_keyDownloadedUrls, _downloadedUrls.toList());
  }

  /// URL daha once indirilmis mi kontrol et
  bool isUrlDownloaded(String url) {
    return _downloadedUrls.contains(url);
  }

  /// Filename ile indirme durumunu kontrol et
  Future<String?> getDownloadedFilePath(String creatorName, String filename) async {
    final creatorPath = await _storageService.getCreatorPath(creatorName);
    final filePath = '$creatorPath/$filename';
    if (await File(filePath).exists()) {
      return filePath;
    }
    return null;
  }

  void addToQueue(DownloadItem item) {
    if (_queue.any((i) => i.url == item.url)) return;
    if (_completed.any((i) => i.url == item.url)) return;
    if (_downloadedUrls.contains(item.url)) return;
    
    _queue.add(item);
    _processQueue();
  }

  void addMultipleToQueue(List<DownloadItem> items) {
    for (var item in items) {
      if (!_queue.any((i) => i.url == item.url) &&
          !_completed.any((i) => i.url == item.url) &&
          !_downloadedUrls.contains(item.url)) {
        _queue.add(item);
      }
    }
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isPaused) return;
    if (_activeDownloads >= _maxConcurrent) return;
    
    final pendingItems = _queue
        .where((item) => item.status == DownloadStatus.pending)
        .take(_maxConcurrent - _activeDownloads)
        .toList();

    for (var item in pendingItems) {
      _downloadItem(item);
    }
  }

  Future<void> _downloadItem(DownloadItem item) async {
    _activeDownloads++;
    _isDownloading = true;
    item.status = DownloadStatus.downloading;
    onProgressUpdate?.call(item);
    onStateChange?.call();

    final cancelToken = CancelToken();
    _cancelTokens[item.id] = cancelToken;

    try {
      // Creator klasorunu al/olustur
      final creatorPath = await _storageService.getCreatorPath(item.creatorName);
      final savePath = '$creatorPath/${item.filename}';
      
      print('[Download] Saving to: $savePath');
      
      await _dio.download(
        item.url,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            item.progress = received / total;
            item.downloadedBytes = received;
            item.totalBytes = total;
            onProgressUpdate?.call(item);
          }
        },
      );

      item.status = DownloadStatus.completed;
      item.localPath = savePath;
      item.progress = 1.0;
      _queue.remove(item);
      _completed.add(item);
      _downloadedUrls.add(item.url);
      _saveCompletedDownloads();
      onComplete?.call(item);
      
      print('[Download] Completed: ${item.filename}');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        // Iptal edildi - duraklatma veya kullanici iptali
        if (item.status != DownloadStatus.paused) {
          item.status = DownloadStatus.cancelled;
          item.error = 'Iptal edildi';
        }
      } else {
        item.status = DownloadStatus.failed;
        item.error = e.message ?? 'Indirme basarisiz';
      }
      print('[Download] Error: ${e.message}');
      onError?.call(item);
    } catch (e) {
      item.status = DownloadStatus.failed;
      item.error = e.toString();
      print('[Download] Error: $e');
      onError?.call(item);
    } finally {
      _cancelTokens.remove(item.id);
      _activeDownloads--;
      if (_activeDownloads == 0) {
        _isDownloading = false;
      }
      onStateChange?.call();
      _processQueue();
    }
  }

  /// Tek bir indirmeyi duraklat
  void pauseDownload(String itemId) {
    final cancelToken = _cancelTokens[itemId];
    if (cancelToken != null) {
      final item = _queue.firstWhere(
        (i) => i.id == itemId,
        orElse: () => DownloadItem(id: '', url: '', filename: '', creatorName: '', postId: ''),
      );
      if (item.id.isNotEmpty) {
        item.status = DownloadStatus.paused;
      }
      cancelToken.cancel();
    } else {
      // Bekleyen item'i duraklat
      final item = _queue.firstWhere(
        (i) => i.id == itemId && i.status == DownloadStatus.pending,
        orElse: () => DownloadItem(id: '', url: '', filename: '', creatorName: '', postId: ''),
      );
      if (item.id.isNotEmpty) {
        item.status = DownloadStatus.paused;
        onStateChange?.call();
      }
    }
  }

  /// Tek bir indirmeyi devam ettir
  void resumeDownload(String itemId) {
    final item = _queue.firstWhere(
      (i) => i.id == itemId && i.status == DownloadStatus.paused,
      orElse: () => DownloadItem(id: '', url: '', filename: '', creatorName: '', postId: ''),
    );
    if (item.id.isNotEmpty) {
      item.status = DownloadStatus.pending;
      item.progress = 0.0;
      item.downloadedBytes = 0;
      onStateChange?.call();
      _processQueue();
    }
  }

  /// Tum indirmeleri duraklat
  void pauseAllDownloads() {
    _isPaused = true;
    
    // Aktif indirmeleri duraklat
    for (var token in _cancelTokens.values) {
      token.cancel();
    }
    
    // Bekleyen ve indirilen itemleri duraklat
    for (var item in _queue) {
      if (item.status == DownloadStatus.downloading || 
          item.status == DownloadStatus.pending) {
        item.status = DownloadStatus.paused;
      }
    }
    
    onStateChange?.call();
  }

  /// Tum indirmeleri devam ettir
  void resumeAllDownloads() {
    _isPaused = false;
    
    // Duraklatilmis itemleri pending yap
    for (var item in _queue) {
      if (item.status == DownloadStatus.paused) {
        item.status = DownloadStatus.pending;
        item.progress = 0.0;
        item.downloadedBytes = 0;
      }
    }
    
    onStateChange?.call();
    _processQueue();
  }

  /// Tek bir basarisiz indirmeyi tekrar dene
  void retryDownload(String itemId) {
    final item = _queue.firstWhere(
      (i) => i.id == itemId && i.status == DownloadStatus.failed,
      orElse: () => DownloadItem(id: '', url: '', filename: '', creatorName: '', postId: ''),
    );
    if (item.id.isNotEmpty) {
      item.status = DownloadStatus.pending;
      item.progress = 0.0;
      item.downloadedBytes = 0;
      item.error = null;
      onStateChange?.call();
      _processQueue();
    }
  }

  void cancelDownload(String itemId) {
    final cancelToken = _cancelTokens[itemId];
    if (cancelToken != null) {
      cancelToken.cancel();
    }
    
    final item = _queue.firstWhere(
      (i) => i.id == itemId,
      orElse: () => DownloadItem(
        id: '',
        url: '',
        filename: '',
        creatorName: '',
        postId: '',
      ),
    );
    
    if (item.id.isNotEmpty) {
      item.status = DownloadStatus.cancelled;
      _queue.remove(item);
      onStateChange?.call();
    }
  }

  void cancelAllDownloads() {
    for (var token in _cancelTokens.values) {
      token.cancel();
    }
    _cancelTokens.clear();
    
    for (var item in _queue) {
      item.status = DownloadStatus.cancelled;
    }
    _queue.clear();
    _activeDownloads = 0;
    _isDownloading = false;
    _isPaused = false;
    onStateChange?.call();
  }

  void clearCompleted() {
    _completed.clear();
    _saveCompletedDownloads();
    onStateChange?.call();
  }

  void retryFailed() {
    final failedItems = _queue
        .where((item) => item.status == DownloadStatus.failed)
        .toList();
    
    for (var item in failedItems) {
      item.status = DownloadStatus.pending;
      item.progress = 0.0;
      item.downloadedBytes = 0;
      item.error = null;
    }
    onStateChange?.call();
    _processQueue();
  }
}
