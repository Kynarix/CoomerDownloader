import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  int? _androidSdkVersion;

  /// Android SDK versiyonunu al
  Future<int> getAndroidSdkVersion() async {
    if (_androidSdkVersion != null) return _androidSdkVersion!;
    
    if (!Platform.isAndroid) return 0;
    
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      _androidSdkVersion = androidInfo.version.sdkInt;
      print('[Permission] Android SDK Version: $_androidSdkVersion');
      return _androidSdkVersion!;
    } catch (e) {
      print('[Permission] Error getting Android SDK version: $e');
      return 30; // Default Android 11
    }
  }

  /// Gerekli tum izinleri kontrol et ve iste
  Future<bool> requestAllPermissions() async {
    if (Platform.isAndroid) {
      return await _requestAndroidPermissions();
    } else if (Platform.isIOS) {
      return await _requestIOSPermissions();
    }
    return true;
  }

  Future<bool> _requestAndroidPermissions() async {
    final sdkVersion = await getAndroidSdkVersion();
    print('[Permission] Requesting permissions for SDK $sdkVersion');
    
    if (sdkVersion >= 33) {
      // Android 13+ (API 33+) - Granular media permissions
      print('[Permission] Using Android 13+ permissions');
      
      Map<Permission, PermissionStatus> statuses = await [
        Permission.photos,
        Permission.videos,
        Permission.notification,
      ].request();
      
      final photosGranted = statuses[Permission.photos]?.isGranted ?? false;
      final videosGranted = statuses[Permission.videos]?.isGranted ?? false;
      final notificationGranted = statuses[Permission.notification]?.isGranted ?? false;
      
      print('[Permission] Photos: $photosGranted, Videos: $videosGranted, Notification: $notificationGranted');
      return photosGranted && videosGranted;
      
    } else if (sdkVersion >= 30) {
      // Android 11-12 (API 30-32) - MANAGE_EXTERNAL_STORAGE needed
      print('[Permission] Using Android 11-12 permissions');
      
      // Oncelikle MANAGE_EXTERNAL_STORAGE kontrolu
      final manageStatus = await Permission.manageExternalStorage.status;
      print('[Permission] Manage External Storage status: $manageStatus');
      
      if (!manageStatus.isGranted) {
        // Kullaniciya ayarlara yonlendirme gerekiyor
        final result = await Permission.manageExternalStorage.request();
        print('[Permission] Manage External Storage request result: $result');
        
        if (!result.isGranted) {
          // Normal storage iznini dene
          final storageResult = await Permission.storage.request();
          print('[Permission] Storage fallback result: $storageResult');
          return storageResult.isGranted;
        }
      }
      
      return true;
      
    } else {
      // Android 10 ve alti (API 29-)
      print('[Permission] Using Android 10 and below permissions');
      
      final storageStatus = await Permission.storage.request();
      print('[Permission] Storage status: $storageStatus');
      return storageStatus.isGranted;
    }
  }

  Future<bool> _requestIOSPermissions() async {
    final photos = await Permission.photos.request();
    return photos.isGranted;
  }

  /// Izin durumunu kontrol et
  Future<bool> hasStoragePermission() async {
    if (Platform.isAndroid) {
      final sdkVersion = await getAndroidSdkVersion();
      
      if (sdkVersion >= 33) {
        final photos = await Permission.photos.isGranted;
        final videos = await Permission.videos.isGranted;
        return photos && videos;
      } else if (sdkVersion >= 30) {
        final manage = await Permission.manageExternalStorage.isGranted;
        if (manage) return true;
        final storage = await Permission.storage.isGranted;
        return storage;
      } else {
        return await Permission.storage.isGranted;
      }
    }
    return true;
  }

  /// Ayarlara yonlendir
  Future<bool> openSettings() async {
    return await openAppSettings();
  }

  /// MANAGE_EXTERNAL_STORAGE ayar sayfasini ac
  Future<bool> openManageStorageSettings() async {
    if (Platform.isAndroid) {
      final sdkVersion = await getAndroidSdkVersion();
      if (sdkVersion >= 30) {
        // Android 11+ icin ozel ayar sayfasi
        final status = await Permission.manageExternalStorage.status;
        if (!status.isGranted) {
          await Permission.manageExternalStorage.request();
          return await Permission.manageExternalStorage.isGranted;
        }
      }
    }
    return await openAppSettings();
  }

  /// Izin durumunu detayli kontrol et
  Future<Map<String, bool>> checkAllPermissions() async {
    final result = <String, bool>{};
    
    if (Platform.isAndroid) {
      final sdkVersion = await getAndroidSdkVersion();
      
      if (sdkVersion >= 33) {
        result['photos'] = await Permission.photos.isGranted;
        result['videos'] = await Permission.videos.isGranted;
        result['notification'] = await Permission.notification.isGranted;
      } else if (sdkVersion >= 30) {
        result['manageExternalStorage'] = await Permission.manageExternalStorage.isGranted;
        result['storage'] = await Permission.storage.isGranted;
      } else {
        result['storage'] = await Permission.storage.isGranted;
      }
    }
    
    return result;
  }
}
