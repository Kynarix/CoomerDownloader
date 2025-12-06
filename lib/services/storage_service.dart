import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  String? _downloadPath;
  SharedPreferences? _prefs;
  static const String _keyCustomDownloadPath = 'custom_download_path';

  /// Initialize service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final customPath = _prefs?.getString(_keyCustomDownloadPath);
    if (customPath != null && customPath.isNotEmpty) {
      final dir = Directory(customPath);
      if (await dir.exists()) {
        _downloadPath = customPath;
      }
    }
  }

  /// Downloads/CoomerDownloader klasor yolunu al
  Future<String> getDownloadPath() async {
    if (_downloadPath != null) return _downloadPath!;

    Directory downloadDir;

    if (Platform.isAndroid) {
      // Android Downloads klasoru
      downloadDir = Directory('/storage/emulated/0/Download/CoomerDownloader');
    } else if (Platform.isIOS) {
      // iOS Documents klasoru
      final docDir = await getApplicationDocumentsDirectory();
      downloadDir = Directory('${docDir.path}/CoomerDownloader');
    } else {
      // Desktop
      final docDir = await getApplicationDocumentsDirectory();
      downloadDir = Directory('${docDir.path}/CoomerDownloader');
    }

    // Klasor yoksa olustur
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }

    _downloadPath = downloadDir.path;
    return _downloadPath!;
  }

  /// Indirme konumunu degistir
  Future<bool> setDownloadPath(String newPath) async {
    try {
      final dir = Directory(newPath);
      
      // Klasor yoksa olustur
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      // Kaydet
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs!.setString(_keyCustomDownloadPath, newPath);
      _downloadPath = newPath;
      
      return true;
    } catch (e) {
      print('[Storage] Error setting download path: $e');
      return false;
    }
  }

  /// Varsayilan indirme konumuna don
  Future<void> resetDownloadPath() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(_keyCustomDownloadPath);
    _downloadPath = null;
    await getDownloadPath(); // Varsayilani yukle
  }

  /// Creator icin klasor olustur
  Future<String> getCreatorPath(String creatorName) async {
    final basePath = await getDownloadPath();
    // Gecersiz karakterleri temizle
    final safeName = creatorName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final creatorDir = Directory('$basePath/$safeName');
    
    if (!await creatorDir.exists()) {
      await creatorDir.create(recursive: true);
    }
    
    return creatorDir.path;
  }

  /// Dosya kaydet
  Future<String> saveFile(String creatorName, String filename, List<int> bytes) async {
    final creatorPath = await getCreatorPath(creatorName);
    final file = File('$creatorPath/$filename');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Indirilen tum dosyalari listele
  Future<List<DownloadedFile>> getDownloadedFiles() async {
    final basePath = await getDownloadPath();
    final baseDir = Directory(basePath);
    
    if (!await baseDir.exists()) {
      return [];
    }

    final files = <DownloadedFile>[];
    
    await for (final entity in baseDir.list(recursive: true)) {
      if (entity is File) {
        final stat = await entity.stat();
        final relativePath = entity.path.replaceFirst('$basePath/', '');
        final parts = relativePath.split('/');
        
        files.add(DownloadedFile(
          path: entity.path,
          name: parts.last,
          creatorName: parts.length > 1 ? parts.first : 'Unknown',
          size: stat.size,
          modifiedDate: stat.modified,
        ));
      }
    }

    // Tarihe gore sirala (en yeni en ustte)
    files.sort((a, b) => b.modifiedDate.compareTo(a.modifiedDate));
    
    return files;
  }

  /// Creator'a gore grupla
  Future<Map<String, List<DownloadedFile>>> getDownloadedFilesByCreator() async {
    final files = await getDownloadedFiles();
    final grouped = <String, List<DownloadedFile>>{};
    
    for (final file in files) {
      grouped.putIfAbsent(file.creatorName, () => []).add(file);
    }
    
    return grouped;
  }

  /// Dosya sil
  Future<bool> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      print('[Storage] Error deleting file: $e');
    }
    return false;
  }

  /// Creator klasorunu sil
  Future<bool> deleteCreatorFolder(String creatorName) async {
    try {
      final creatorPath = await getCreatorPath(creatorName);
      final dir = Directory(creatorPath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        return true;
      }
    } catch (e) {
      print('[Storage] Error deleting creator folder: $e');
    }
    return false;
  }

  /// Tum indirmeleri sil
  Future<bool> deleteAllDownloads() async {
    try {
      final basePath = await getDownloadPath();
      final baseDir = Directory(basePath);
      if (await baseDir.exists()) {
        await for (final entity in baseDir.list()) {
          if (entity is Directory) {
            await entity.delete(recursive: true);
          } else if (entity is File) {
            await entity.delete();
          }
        }
        return true;
      }
    } catch (e) {
      print('[Storage] Error deleting all downloads: $e');
    }
    return false;
  }

  /// Toplam boyut hesapla
  Future<int> getTotalSize() async {
    final files = await getDownloadedFiles();
    return files.fold<int>(0, (sum, file) => sum + file.size);
  }

  /// Dosya mevcut mu kontrol et
  Future<bool> isFileDownloaded(String creatorName, String filename) async {
    final creatorPath = await getCreatorPath(creatorName);
    final file = File('$creatorPath/$filename');
    return file.exists();
  }

  /// Dosya yolunu al (varsa)
  Future<String?> getFilePath(String creatorName, String filename) async {
    final creatorPath = await getCreatorPath(creatorName);
    final filePath = '$creatorPath/$filename';
    final file = File(filePath);
    if (await file.exists()) {
      return filePath;
    }
    return null;
  }

  /// Boyutu formatla
  String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

class DownloadedFile {
  final String path;
  final String name;
  final String creatorName;
  final int size;
  final DateTime modifiedDate;

  DownloadedFile({
    required this.path,
    required this.name,
    required this.creatorName,
    required this.size,
    required this.modifiedDate,
  });

  bool get isImage {
    final ext = name.toLowerCase();
    return ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg') ||
        ext.endsWith('.png') ||
        ext.endsWith('.gif') ||
        ext.endsWith('.webp');
  }

  bool get isVideo {
    final ext = name.toLowerCase();
    return ext.endsWith('.mp4') ||
        ext.endsWith('.mov') ||
        ext.endsWith('.avi') ||
        ext.endsWith('.webm') ||
        ext.endsWith('.m4v');
  }

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(modifiedDate);
    
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes} dakika once';
      }
      return '${diff.inHours} saat once';
    } else if (diff.inDays == 1) {
      return 'Dun';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} gun once';
    } else {
      return '${modifiedDate.day}/${modifiedDate.month}/${modifiedDate.year}';
    }
  }
}
