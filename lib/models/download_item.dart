enum DownloadStatus {
  pending,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

class DownloadItem {
  final String id;
  final String url;
  final String filename;
  final String creatorName;
  final String postId;
  DownloadStatus status;
  double progress;
  String? localPath;
  String? error;
  int downloadedBytes;
  int totalBytes;

  DownloadItem({
    required this.id,
    required this.url,
    required this.filename,
    required this.creatorName,
    required this.postId,
    this.status = DownloadStatus.pending,
    this.progress = 0.0,
    this.localPath,
    this.error,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
  });

  factory DownloadItem.fromJson(Map<String, dynamic> json) {
    return DownloadItem(
      id: json['id'] ?? '',
      url: json['url'] ?? '',
      filename: json['filename'] ?? '',
      creatorName: json['creatorName'] ?? '',
      postId: json['postId'] ?? '',
      status: DownloadStatus.values[json['status'] ?? 3],
      progress: (json['progress'] ?? 1.0).toDouble(),
      localPath: json['localPath'],
      error: json['error'],
      downloadedBytes: json['downloadedBytes'] ?? 0,
      totalBytes: json['totalBytes'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'filename': filename,
      'creatorName': creatorName,
      'postId': postId,
      'status': status.index,
      'progress': progress,
      'localPath': localPath,
      'error': error,
      'downloadedBytes': downloadedBytes,
      'totalBytes': totalBytes,
    };
  }

  bool get isImage {
    final ext = filename.toLowerCase();
    return ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg') ||
        ext.endsWith('.png') ||
        ext.endsWith('.gif') ||
        ext.endsWith('.webp');
  }

  bool get isVideo {
    final ext = filename.toLowerCase();
    return ext.endsWith('.mp4') ||
        ext.endsWith('.mov') ||
        ext.endsWith('.avi') ||
        ext.endsWith('.webm') ||
        ext.endsWith('.m4v');
  }

  String get statusText {
    switch (status) {
      case DownloadStatus.pending:
        return 'Bekliyor';
      case DownloadStatus.downloading:
        return 'Indiriliyor... ${(progress * 100).toStringAsFixed(0)}%';
      case DownloadStatus.paused:
        return 'Duraklatildi ${(progress * 100).toStringAsFixed(0)}%';
      case DownloadStatus.completed:
        return 'Tamamlandi';
      case DownloadStatus.failed:
        return 'Basarisiz';
      case DownloadStatus.cancelled:
        return 'Iptal Edildi';
    }
  }

  String get formattedSize {
    if (totalBytes == 0) return '';
    
    String formatBytes(int bytes) {
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
    
    return '${formatBytes(downloadedBytes)} / ${formatBytes(totalBytes)}';
  }
}
