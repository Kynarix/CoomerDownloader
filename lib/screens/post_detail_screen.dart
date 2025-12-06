import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:open_filex/open_filex.dart';
import '../models/post.dart';
import '../providers/download_provider.dart';
import '../services/storage_service.dart';
import '../utils/theme.dart';
import 'main_navigation.dart';

// MIME type helper function
String? getMimeType(String path) {
  final ext = path.toLowerCase();
  
  // Video MIME types
  if (ext.endsWith('.mp4')) return 'video/mp4';
  if (ext.endsWith('.m4v')) return 'video/x-m4v';
  if (ext.endsWith('.mov')) return 'video/quicktime';
  if (ext.endsWith('.avi')) return 'video/x-msvideo';
  if (ext.endsWith('.webm')) return 'video/webm';
  if (ext.endsWith('.mkv')) return 'video/x-matroska';
  if (ext.endsWith('.3gp')) return 'video/3gpp';
  if (ext.endsWith('.flv')) return 'video/x-flv';
  if (ext.endsWith('.wmv')) return 'video/x-ms-wmv';
  
  // Image MIME types
  if (ext.endsWith('.jpg') || ext.endsWith('.jpeg')) return 'image/jpeg';
  if (ext.endsWith('.png')) return 'image/png';
  if (ext.endsWith('.gif')) return 'image/gif';
  if (ext.endsWith('.webp')) return 'image/webp';
  if (ext.endsWith('.bmp')) return 'image/bmp';
  
  return null;
}

class PostDetailScreen extends StatefulWidget {
  final Post post;
  final String creatorName;

  const PostDetailScreen({
    super.key,
    required this.post,
    required this.creatorName,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final StorageService _storageService = StorageService();
  Map<String, String?> _downloadedFiles = {};

  @override
  void initState() {
    super.initState();
    _checkDownloadedFiles();
  }

  Future<void> _checkDownloadedFiles() async {
    final files = <String, String?>{};
    
    for (final file in widget.post.allFiles) {
      final path = await _storageService.getFilePath(widget.creatorName, file.name);
      files[file.url] = path;
    }
    
    for (final attachment in widget.post.attachments) {
      final path = await _storageService.getFilePath(widget.creatorName, attachment.name);
      files[attachment.url] = path;
    }
    
    if (mounted) {
      setState(() {
        _downloadedFiles = files;
      });
    }
  }

  bool _isDownloaded(String url) {
    return _downloadedFiles[url] != null;
  }

  String? _getFilePath(String url) {
    return _downloadedFiles[url];
  }

  Future<void> _openFile(String? path) async {
    if (path == null) return;
    final mimeType = getMimeType(path);
    final result = await OpenFilex.open(path, type: mimeType);
    if (result.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dosya acilamadi: ${result.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.post.title.isEmpty ? 'Post' : widget.post.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            onPressed: () async {
              final downloaded = await context.read<DownloadProvider>().downloadPost(
                    post: widget.post,
                    creatorName: widget.creatorName,
                    context: context,
                  );
              if (downloaded && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${widget.post.totalMediaCount} dosya indirme listesine eklendi',
                    ),
                  ),
                );
                // Refresh download status
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) _checkDownloadedFiles();
                });
              }
            },
            icon: const Icon(Icons.download_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post info
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.post.title.isEmpty ? 'Untitled' : widget.post.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.post.formattedDate,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.photo_library_outlined,
                        size: 14,
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.post.imageCount} foto',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (widget.post.videoCount > 0) ...[
                        const SizedBox(width: 16),
                        Icon(
                          Icons.videocam_outlined,
                          size: 14,
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.post.videoCount} video',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                  if (widget.post.content != null && widget.post.content!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      widget.post.content!,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ],
              ),
            ),
            // Divider
            Divider(
              height: 1,
              color: isDark ? Colors.grey[800] : Colors.grey[300],
            ),
            // Media grid - allFiles kullan
            if (widget.post.allFiles.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Medya (${widget.post.allFiles.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: widget.post.allFiles.length,
                itemBuilder: (context, index) {
                  final file = widget.post.allFiles[index];
                  final isDownloaded = _isDownloaded(file.url);
                  final filePath = _getFilePath(file.url);
                  
                  return GestureDetector(
                    onTap: () {
                      if (isDownloaded && filePath != null) {
                        _openFile(filePath);
                      } else {
                        _showMediaViewer(context, index);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
                        border: isDownloaded
                            ? Border.all(color: AppTheme.success, width: 2)
                            : null,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: file.thumbnailUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor:
                                  isDark ? Colors.grey[800]! : Colors.grey[300]!,
                              highlightColor:
                                  isDark ? Colors.grey[700]! : Colors.grey[100]!,
                              child: Container(color: Colors.white),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: isDark ? Colors.grey[800] : Colors.grey[300],
                              child: Icon(
                                file.isVideo
                                    ? Icons.videocam_outlined
                                    : Icons.image_outlined,
                                color:
                                    isDark ? Colors.grey[600] : Colors.grey[500],
                              ),
                            ),
                          ),
                          if (file.isVideo)
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          // Downloaded indicator
                          if (isDownloaded)
                            Positioned(
                              top: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppTheme.success,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          // Download button (only if not downloaded)
                          if (!isDownloaded)
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () async {
                                  final downloaded = await context.read<DownloadProvider>().downloadFile(
                                        url: file.url,
                                        filename: file.name,
                                        creatorName: widget.creatorName,
                                        postId: widget.post.id,
                                        context: context,
                                      );
                                  if (downloaded && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${file.name} indiriliyor'),
                                        action: SnackBarAction(
                                          label: 'Indirmeler',
                                          textColor: AppTheme.accent,
                                          onPressed: () {
                                            Navigator.of(context).pushAndRemoveUntil(
                                              MaterialPageRoute(
                                                builder: (_) => const MainNavigation(initialIndex: 1),
                                              ),
                                              (route) => false,
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                    // Refresh after download
                                    Future.delayed(const Duration(seconds: 3), () {
                                      if (mounted) _checkDownloadedFiles();
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.download_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          // Open button (if downloaded)
                          if (isDownloaded)
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppTheme.success,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.open_in_new,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
            // Attachments
            if (widget.post.attachments.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Text(
                  'Ekler (${widget.post.attachments.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: widget.post.attachments.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final attachment = widget.post.attachments[index];
                  final isDownloaded = _isDownloaded(attachment.url);
                  final filePath = _getFilePath(attachment.url);
                  
                  return GestureDetector(
                    onTap: isDownloaded ? () => _openFile(filePath) : null,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
                        borderRadius: BorderRadius.circular(12),
                        border: isDownloaded
                            ? Border.all(color: AppTheme.success, width: 2)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isDownloaded
                                  ? AppTheme.success.withValues(alpha: 0.1)
                                  : AppTheme.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isDownloaded ? Icons.check : Icons.attach_file,
                              color: isDownloaded ? AppTheme.success : AppTheme.accent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  attachment.name,
                                  style: Theme.of(context).textTheme.titleMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (isDownloaded)
                                  Text(
                                    'Indirildi - Acmak icin tiklayin',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.success,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (isDownloaded)
                            IconButton(
                              onPressed: () => _openFile(filePath),
                              icon: const Icon(Icons.open_in_new),
                              color: AppTheme.success,
                            )
                          else
                            IconButton(
                              onPressed: () async {
                                final downloaded = await context.read<DownloadProvider>().downloadFile(
                                      url: attachment.url,
                                      filename: attachment.name,
                                      creatorName: widget.creatorName,
                                      postId: widget.post.id,
                                      context: context,
                                    );
                                if (downloaded && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('${attachment.name} indiriliyor'),
                                      action: SnackBarAction(
                                        label: 'Indirmeler',
                                        textColor: AppTheme.accent,
                                        onPressed: () {
                                          Navigator.of(context).pushAndRemoveUntil(
                                            MaterialPageRoute(
                                              builder: (_) => const MainNavigation(initialIndex: 1),
                                            ),
                                            (route) => false,
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                  Future.delayed(const Duration(seconds: 3), () {
                                    if (mounted) _checkDownloadedFiles();
                                  });
                                }
                              },
                              icon: const Icon(Icons.download_rounded),
                              color: AppTheme.accent,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  void _showMediaViewer(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _MediaViewerScreen(
          files: widget.post.allFiles,
          initialIndex: initialIndex,
          creatorName: widget.creatorName,
          postId: widget.post.id,
          downloadedFiles: _downloadedFiles,
          onDownloadComplete: _checkDownloadedFiles,
        ),
      ),
    );
  }
}

class _MediaViewerScreen extends StatefulWidget {
  final List<PostFile> files;
  final int initialIndex;
  final String creatorName;
  final String postId;
  final Map<String, String?> downloadedFiles;
  final VoidCallback onDownloadComplete;

  const _MediaViewerScreen({
    required this.files,
    required this.initialIndex,
    required this.creatorName,
    required this.postId,
    required this.downloadedFiles,
    required this.onDownloadComplete,
  });

  @override
  State<_MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<_MediaViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  late Map<String, String?> _downloadedFiles;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _downloadedFiles = Map.from(widget.downloadedFiles);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _isDownloaded(String url) {
    return _downloadedFiles[url] != null;
  }

  String? _getFilePath(String url) {
    return _downloadedFiles[url];
  }

  Future<void> _openFile(String? path) async {
    if (path == null) return;
    final mimeType = getMimeType(path);
    final result = await OpenFilex.open(path, type: mimeType);
    if (result.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dosya acilamadi: ${result.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentFile = widget.files[_currentIndex];
    final isCurrentDownloaded = _isDownloaded(currentFile.url);
    final currentFilePath = _getFilePath(currentFile.url);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Text(
              '${_currentIndex + 1} / ${widget.files.length}',
              style: const TextStyle(color: Colors.white),
            ),
            if (isCurrentDownloaded) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.success,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Indirildi',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (isCurrentDownloaded)
            IconButton(
              onPressed: () => _openFile(currentFilePath),
              icon: const Icon(Icons.open_in_new, color: AppTheme.success),
              tooltip: 'Dosyayi Ac',
            )
          else
            IconButton(
              onPressed: () async {
                final file = widget.files[_currentIndex];
                final downloaded = await context.read<DownloadProvider>().downloadFile(
                      url: file.url,
                      filename: file.name,
                      creatorName: widget.creatorName,
                      postId: widget.postId,
                      context: context,
                    );
                if (downloaded) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${file.name} indiriliyor'),
                      action: SnackBarAction(
                        label: 'Indirmeler',
                        textColor: AppTheme.accent,
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const MainNavigation(initialIndex: 1),
                            ),
                            (route) => false,
                          );
                        },
                      ),
                    ),
                  );
                  widget.onDownloadComplete();
                }
              },
              icon: const Icon(Icons.download_rounded, color: Colors.white),
            ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.files.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final file = widget.files[index];
          final filePath = _getFilePath(file.url);
          final isDownloaded = filePath != null;

          return GestureDetector(
            onDoubleTap: isDownloaded ? () => _openFile(filePath) : null,
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: file.url,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        file.isVideo
                            ? Icons.videocam_outlined
                            : Icons.image_not_supported_outlined,
                        color: Colors.grey,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        file.isVideo
                            ? 'Video onizleme desteklenmiyor'
                            : 'Gorsel yuklenemedi',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      if (isDownloaded) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _openFile(filePath),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Dosyayi Ac'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
