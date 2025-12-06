import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  Function(NotificationResponse)? onNotificationTapped;
  int _fileNotificationId = 100; // Her dosya için unique ID

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        // Bildirime veya action butonuna tıklandığında
        if (response.actionId == 'open_downloads' || response.payload == 'open_downloads') {
          onNotificationTapped?.call(response);
        }
      },
    );

    if (Platform.isAndroid) {
      await _requestAndroidPermissions();
      await _createNotificationChannel();
    }

    _initialized = true;
  }

  Future<void> _createNotificationChannel() async {
    final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      // İndirme durumu kanalı
      const downloadChannel = AndroidNotificationChannel(
        'download_channel',
        'Indirmeler',
        description: 'Indirme durumu bildirimleri',
        importance: Importance.high,
        playSound: false,
        enableVibration: false,
        showBadge: true,
      );
      await androidImplementation.createNotificationChannel(downloadChannel);
      
      // Dosya bildirimleri kanalı
      const fileChannel = AndroidNotificationChannel(
        'file_download_channel',
        'Dosya Indirmeleri',
        description: 'Indirilen dosya bildirimleri',
        importance: Importance.defaultImportance,
        playSound: false,
        enableVibration: false,
        showBadge: true,
      );
      await androidImplementation.createNotificationChannel(fileChannel);
    }
  }

  Future<void> _requestAndroidPermissions() async {
    if (Platform.isAndroid) {
      try {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        
        // Android 13+ (API 33+) için bildirim izni iste
        if (androidInfo.version.sdkInt >= 33) {
          final status = await Permission.notification.status;
          if (!status.isGranted) {
            await Permission.notification.request();
          }
        }
      } catch (e) {
        print('[NotificationService] Error requesting permissions: $e');
      }
    }
  }

  Future<bool> _checkNotificationPermission() async {
    if (Platform.isAndroid) {
      try {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        
        if (androidInfo.version.sdkInt >= 33) {
          final status = await Permission.notification.status;
          return status.isGranted;
        }
        return true; // Android 12 ve altı için izin gerekmez
      } catch (e) {
        print('[NotificationService] Error checking permission: $e');
        return true; // Hata durumunda izin verilmiş say
      }
    }
    return true; // iOS için varsayılan olarak true
  }

  Future<void> showDownloadStartedNotification({
    required String filename,
    required int totalFiles,
  }) async {
    // İzin kontrolü
    if (!await _checkNotificationPermission()) {
      print('[NotificationService] Notification permission not granted');
      return;
    }
    const androidDetails = AndroidNotificationDetails(
      'download_channel',
      'Indirmeler',
      channelDescription: 'Indirme durumu bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: false,
      showProgress: false,
      enableVibration: false,
      playSound: false,
      actions: [
        AndroidNotificationAction(
          'open_downloads',
          'Indirmeler',
          showsUserInterface: true,
          cancelNotification: false,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      1,
      'Indirme Basladi',
      totalFiles > 1 
          ? '$totalFiles dosya indirme listesine eklendi'
          : '1 dosya indirme listesine eklendi',
      details,
      payload: 'open_downloads',
    );
  }

  Future<void> showDownloadProgressNotification({
    required String filename,
    required double progress,
    required int currentFile,
    required int totalFiles,
  }) async {
    // İzin kontrolü
    if (!await _checkNotificationPermission()) {
      return;
    }
    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: true,
      presentSound: false,
    );

    final androidProgressDetails = AndroidNotificationDetails(
      'download_channel',
      'Indirmeler',
      channelDescription: 'Indirme durumu bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      showProgress: true,
      maxProgress: 100,
      progress: (progress * 100).toInt(),
      enableVibration: false,
      playSound: false,
      onlyAlertOnce: true,
      category: AndroidNotificationCategory.progress,
      actions: const [
        AndroidNotificationAction(
          'open_downloads',
          'Indirmeler',
          showsUserInterface: true,
          cancelNotification: false,
        ),
      ],
    );

    final details = NotificationDetails(
      android: androidProgressDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      1,
      totalFiles > 1 
          ? 'Indiriliyor ($currentFile/$totalFiles)'
          : 'Indiriliyor',
      filename,
      details,
      payload: 'open_downloads',
    );
  }

  Future<void> showDownloadCompleteNotification({
    required String filename,
    required int totalFiles,
  }) async {
    // İzin kontrolü
    if (!await _checkNotificationPermission()) {
      return;
    }
    const androidDetails = AndroidNotificationDetails(
      'download_channel',
      'Indirmeler',
      channelDescription: 'Indirme durumu bildirimleri',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      enableVibration: true,
      playSound: true,
      category: AndroidNotificationCategory.status,
      actions: [
        AndroidNotificationAction(
          'open_downloads',
          'Indirmeler',
          showsUserInterface: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      2,
      'Indirme Tamamlandi',
      totalFiles > 1 
          ? '$totalFiles dosya basariyla indirildi'
          : '$filename basariyla indirildi',
      details,
      payload: 'open_downloads',
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> cancelDownloadNotification() async {
    await _notifications.cancel(1);
  }

  /// Her dosya için ayrı bildirim göster
  Future<void> showFileCompletedNotification({
    required String filename,
    required String creatorName,
  }) async {
    if (!await _checkNotificationPermission()) {
      return;
    }

    // Dosya tipine göre ikon belirle
    final isVideo = filename.toLowerCase().endsWith('.mp4') ||
        filename.toLowerCase().endsWith('.mov') ||
        filename.toLowerCase().endsWith('.avi') ||
        filename.toLowerCase().endsWith('.webm');
    
    final isImage = filename.toLowerCase().endsWith('.jpg') ||
        filename.toLowerCase().endsWith('.jpeg') ||
        filename.toLowerCase().endsWith('.png') ||
        filename.toLowerCase().endsWith('.gif') ||
        filename.toLowerCase().endsWith('.webp');

    String subtitle;
    if (isVideo) {
      subtitle = '🎬 Video indirildi';
    } else if (isImage) {
      subtitle = '🖼️ Resim indirildi';
    } else {
      subtitle = '📁 Dosya indirildi';
    }

    const androidDetails = AndroidNotificationDetails(
      'file_download_channel',
      'Dosya Indirmeleri',
      channelDescription: 'Indirilen dosya bildirimleri',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      enableVibration: false,
      playSound: false,
      autoCancel: true,
      groupKey: 'com.coomerdownloader.downloads',
      setAsGroupSummary: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
      threadIdentifier: 'downloads',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Her dosya için unique ID kullan
    _fileNotificationId++;
    
    await _notifications.show(
      _fileNotificationId,
      '$creatorName - $subtitle',
      filename,
      details,
      payload: 'open_downloads',
    );
  }

  /// Grup bildirimi göster (Android için)
  Future<void> showGroupSummaryNotification({
    required int totalFiles,
  }) async {
    if (!await _checkNotificationPermission()) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'file_download_channel',
      'Dosya Indirmeleri',
      channelDescription: 'Indirilen dosya bildirimleri',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      groupKey: 'com.coomerdownloader.downloads',
      setAsGroupSummary: true,
      autoCancel: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      99, // Grup özeti için sabit ID
      'Coomer Downloader',
      '$totalFiles dosya indirildi',
      details,
      payload: 'open_downloads',
    );
  }
}

