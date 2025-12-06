import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import '../services/storage_service.dart';
import '../utils/theme.dart';

class DownloadedFilesScreen extends StatefulWidget {
  const DownloadedFilesScreen({super.key});

  @override
  State<DownloadedFilesScreen> createState() => _DownloadedFilesScreenState();
}

class _DownloadedFilesScreenState extends State<DownloadedFilesScreen> {
  final StorageService _storageService = StorageService();
  
  Map<String, List<DownloadedFile>> _filesByCreator = {};
  bool _isLoading = true;
  int _totalSize = 0;
  String? _expandedCreator;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
    });

    final files = await _storageService.getDownloadedFilesByCreator();
    final totalSize = await _storageService.getTotalSize();

    setState(() {
      _filesByCreator = files;
      _totalSize = totalSize;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Indirilenler'),
        actions: [
          if (_filesByCreator.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'delete_all') {
                  _showDeleteAllDialog();
                } else if (value == 'open_folder') {
                  _openDownloadFolder();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'open_folder',
                  child: Row(
                    children: [
                      Icon(Icons.folder_open, size: 20),
                      SizedBox(width: 12),
                      Text('Klasoru Ac'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 20, color: AppTheme.error),
                      SizedBox(width: 12),
                      Text('Tumunu Sil', style: TextStyle(color: AppTheme.error)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filesByCreator.isEmpty
              ? _buildEmptyState(isDark)
              : _buildFilesList(isDark),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 80,
            color: isDark
                ? AppTheme.textSecondaryDark.withValues(alpha: 0.3)
                : AppTheme.textSecondaryLight.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Henuz indirilen dosya yok',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Indirdiginiz dosyalar burada gorunecek',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildFilesList(bool isDark) {
    final creators = _filesByCreator.keys.toList();

    return Column(
      children: [
        // Summary header
        Container(
          padding: const EdgeInsets.all(16),
          color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
          child: Row(
            children: [
              Icon(
                Icons.storage,
                color: AppTheme.accent,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_filesByCreator.values.fold<int>(0, (sum, list) => sum + list.length)} dosya',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      _storageService.formatSize(_totalSize),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Text(
                '${creators.length} creator',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Creator list
        Expanded(
          child: ListView.builder(
            itemCount: creators.length,
            itemBuilder: (context, index) {
              final creator = creators[index];
              final files = _filesByCreator[creator]!;
              final isExpanded = _expandedCreator == creator;

              return Column(
                children: [
                  // Creator header
                  InkWell(
                    onTap: () {
                      setState(() {
                        _expandedCreator = isExpanded ? null : creator;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                creator.isNotEmpty ? creator[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accent,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  creator,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  '${files.length} dosya - ${_storageService.formatSize(files.fold<int>(0, (sum, f) => sum + f.size))}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _showDeleteCreatorDialog(creator),
                            icon: const Icon(Icons.delete_outline),
                            iconSize: 20,
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          ),
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Files list
                  if (isExpanded)
                    ...files.map((file) => _buildFileItem(file, isDark)),
                  if (index < creators.length - 1)
                    Divider(
                      height: 1,
                      color: isDark ? Colors.grey[800] : Colors.grey[300],
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFileItem(DownloadedFile file, bool isDark) {
    return InkWell(
      onTap: () => _openFile(file),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(left: 16),
        child: Row(
        children: [
          // Thumbnail
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: file.isImage
                ? Image.file(
                    File(file.path),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.image_outlined,
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                    ),
                  )
                : Icon(
                    file.isVideo ? Icons.videocam_outlined : Icons.insert_drive_file_outlined,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${file.formattedSize} - ${file.formattedDate}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      ),
                ),
              ],
            ),
          ),
          // Actions
          IconButton(
            onPressed: () => _shareFile(file),
            icon: const Icon(Icons.share_outlined),
            iconSize: 20,
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          ),
          IconButton(
            onPressed: () => _showDeleteFileDialog(file),
            icon: const Icon(Icons.delete_outline),
            iconSize: 20,
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          ),
        ],
      ),
      ),
    );
  }

  Future<void> _openFile(DownloadedFile file) async {
    String? mimeType;
    final ext = file.name.toLowerCase();
    
    // Video MIME types
    if (ext.endsWith('.mp4')) {
      mimeType = 'video/mp4';
    } else if (ext.endsWith('.m4v')) {
      mimeType = 'video/x-m4v';
    } else if (ext.endsWith('.mov')) {
      mimeType = 'video/quicktime';
    } else if (ext.endsWith('.avi')) {
      mimeType = 'video/x-msvideo';
    } else if (ext.endsWith('.webm')) {
      mimeType = 'video/webm';
    } else if (ext.endsWith('.mkv')) {
      mimeType = 'video/x-matroska';
    }
    // Image MIME types
    else if (ext.endsWith('.jpg') || ext.endsWith('.jpeg')) {
      mimeType = 'image/jpeg';
    } else if (ext.endsWith('.png')) {
      mimeType = 'image/png';
    } else if (ext.endsWith('.gif')) {
      mimeType = 'image/gif';
    } else if (ext.endsWith('.webp')) {
      mimeType = 'image/webp';
    }
    
    final result = await OpenFilex.open(file.path, type: mimeType);
    if (result.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dosya acilamadi: ${result.message}')),
      );
    }
  }

  Future<void> _shareFile(DownloadedFile file) async {
    await Share.shareXFiles([XFile(file.path)]);
  }

  Future<void> _openDownloadFolder() async {
    final path = await _storageService.getDownloadPath();
    // Android'de dosya yöneticisi ile açma
    try {
      final uri = Uri.parse('content://com.android.externalstorage.documents/document/primary:Download%2FCoomerDownloader');
      await launchUrl(uri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Klasor: $path')),
        );
      }
    }
  }

  void _showDeleteFileDialog(DownloadedFile file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dosyayi Sil'),
        content: Text('${file.name} silinecek. Devam etmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Iptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _storageService.deleteFile(file.path);
              _loadFiles();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dosya silindi')),
                );
              }
            },
            child: const Text('Sil', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  void _showDeleteCreatorDialog(String creator) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Creator Klasorunu Sil'),
        content: Text('$creator icin tum dosyalar silinecek. Devam etmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Iptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _storageService.deleteCreatorFolder(creator);
              _loadFiles();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$creator klasoru silindi')),
                );
              }
            },
            child: const Text('Sil', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tum Indirmeleri Sil'),
        content: const Text('Tum indirilen dosyalar silinecek. Bu islem geri alinamaz. Devam etmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Iptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _storageService.deleteAllDownloads();
              _loadFiles();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tum dosyalar silindi')),
                );
              }
            },
            child: const Text('Tumu Sil', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}

