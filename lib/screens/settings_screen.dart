import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_provider.dart';
import '../services/storage_service.dart';
import '../utils/theme.dart';
import 'downloaded_files_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storageService = StorageService();
  
  String _downloadPath = '';
  int _totalSize = 0;
  int _totalFiles = 0;

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    final path = await _storageService.getDownloadPath();
    final size = await _storageService.getTotalSize();
    final files = await _storageService.getDownloadedFiles();
    
    setState(() {
      _downloadPath = path;
      _totalSize = size;
      _totalFiles = files.length;
    });
  }

  Future<void> _changeDownloadPath() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Indirme Konumunu Sec',
      );
      
      if (selectedDirectory != null) {
        final success = await _storageService.setDownloadPath(selectedDirectory);
        if (success) {
          await _loadStorageInfo();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Indirme konumu degistirildi')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Konum degistirilemedi')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  Future<void> _resetDownloadPath() async {
    await _storageService.resetDownloadPath();
    await _loadStorageInfo();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Varsayilan konuma donuldu')),
      );
    }
  }

  Future<void> _openGitHub() async {
    final uri = Uri.parse('https://github.com/kynarix');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Appearance section
          Text(
            'Gorunum',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Consumer<AppProvider>(
              builder: (context, provider, child) {
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isDark ? Icons.dark_mode : Icons.light_mode,
                      color: AppTheme.accent,
                      size: 20,
                    ),
                  ),
                  title: const Text('Tema'),
                  subtitle: Text(isDark ? 'Karanlik' : 'Aydinlik'),
                  trailing: Switch(
                    value: isDark,
                    onChanged: (value) => provider.toggleTheme(),
                    activeTrackColor: AppTheme.accent,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          
          // Downloads section
          Text(
            'Indirilenler',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.folder_outlined,
                      color: AppTheme.info,
                      size: 20,
                    ),
                  ),
                  title: const Text('Indirme Konumu'),
                  subtitle: Text(
                    _downloadPath.replaceAll('/storage/emulated/0/', ''),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.edit_outlined, size: 20),
                  onTap: () => _showDownloadPathOptions(),
                ),
                Divider(
                  height: 1,
                  indent: 68,
                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                ),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.storage_outlined,
                      color: AppTheme.success,
                      size: 20,
                    ),
                  ),
                  title: const Text('Indirilen Dosyalar'),
                  subtitle: Text('$_totalFiles dosya - ${_storageService.formatSize(_totalSize)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DownloadedFilesScreen(),
                      ),
                    ).then((_) => _loadStorageInfo());
                  },
                ),
                Divider(
                  height: 1,
                  indent: 68,
                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                ),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: AppTheme.warning,
                      size: 20,
                    ),
                  ),
                  title: const Text('Tum Indirmeleri Sil'),
                  subtitle: const Text('Tum indirilen dosyalari kaldir'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Tum Indirmeleri Sil'),
                        content: const Text(
                          'Tum indirilen dosyalar silinecek. Bu islem geri alinamaz. Devam etmek istiyor musunuz?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Iptal'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await _storageService.deleteAllDownloads();
                              _loadStorageInfo();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Tum dosyalar silindi'),
                                  ),
                                );
                              }
                            },
                            child: const Text('Sil', style: TextStyle(color: AppTheme.error)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Cache section
          Text(
            'Onbellek',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.cached_outlined,
                  color: AppTheme.error,
                  size: 20,
                ),
              ),
              title: const Text('Onbellegi Temizle'),
              subtitle: const Text('Resim onbellegi ve gecici dosyalar'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Onbellegi Temizle'),
                    content: const Text(
                      'Tum onbellek dosyalari silinecek. Devam etmek istiyor musunuz?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Iptal'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Onbellek temizlendi'),
                            ),
                          );
                        },
                        child: const Text('Temizle'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          
          // About section
          Text(
            'Hakkinda',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const ListTile(
                  leading: SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: Text(
                        'C',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accent,
                        ),
                      ),
                    ),
                  ),
                  title: Text('Coomer Downloader'),
                  subtitle: Text('Versiyon 1.0.0'),
                ),
                Divider(
                  height: 1,
                  indent: 68,
                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                ),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.code,
                      color: AppTheme.success,
                      size: 20,
                    ),
                  ),
                  title: const Text('Gelistirici'),
                  subtitle: const Text('by Kynarix'),
                ),
                Divider(
                  height: 1,
                  indent: 68,
                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                ),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.forum,
                      color: AppTheme.accent,
                      size: 20,
                    ),
                  ),
                  title: const Text('CheatGlobal'),
                  subtitle: const Text('Forum Konusu'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () async {
                    final uri = Uri.parse('https://cheatglobal.com/konu/onlyfans-fansly-downloader-android.99634/');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                Divider(
                  height: 1,
                  indent: 68,
                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                ),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF24292e).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.code_rounded,
                      color: isDark ? Colors.white : const Color(0xFF24292e),
                      size: 20,
                    ),
                  ),
                  title: const Text('GitHub'),
                  subtitle: const Text('@kynarix'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: _openGitHub,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Footer
          Center(
            child: Text(
              'Coomer Downloader v1.0.0',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                  ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showDownloadPathOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.cardDark : AppTheme.cardLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Indirme Konumu',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _downloadPath,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.folder_open,
                  color: AppTheme.accent,
                  size: 20,
                ),
              ),
              title: const Text('Konum Sec'),
              subtitle: const Text('Yeni indirme klasoru sec'),
              onTap: () {
                Navigator.pop(context);
                _changeDownloadPath();
              },
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.restore,
                  color: AppTheme.warning,
                  size: 20,
                ),
              ),
              title: const Text('Varsayilana Don'),
              subtitle: const Text('Download/CoomerDownloader'),
              onTap: () {
                Navigator.pop(context);
                _resetDownloadPath();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
