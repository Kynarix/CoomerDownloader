import 'dart:io';
import 'package:flutter/material.dart';
import '../services/permission_service.dart';
import '../utils/theme.dart';
import 'main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  String _statusText = 'Baslatiliyor...';
  bool _permissionDenied = false;
  bool _needsManageStorage = false;
  int _androidVersion = 0;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    
    _controller.forward();
    _initializeApp();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _statusText = 'Izinler kontrol ediliyor...';
    });
    
    final permissionService = PermissionService();
    
    // Android versiyonunu al
    if (Platform.isAndroid) {
      _androidVersion = await permissionService.getAndroidSdkVersion();
    }
    
    // Mevcut izin durumunu kontrol et
    final hasPermission = await permissionService.hasStoragePermission();
    
    if (hasPermission) {
      _proceedToApp();
      return;
    }
    
    // Izinleri iste
    final granted = await permissionService.requestAllPermissions();
    
    if (granted) {
      _proceedToApp();
    } else {
      // Android 11+ icin MANAGE_EXTERNAL_STORAGE kontrolu
      if (Platform.isAndroid && _androidVersion >= 30 && _androidVersion < 33) {
        setState(() {
          _statusText = 'Ozel izin gerekli!';
          _permissionDenied = true;
          _needsManageStorage = true;
        });
      } else {
        setState(() {
          _statusText = 'Izinler gerekli!';
          _permissionDenied = true;
          _needsManageStorage = false;
        });
      }
    }
  }

  void _proceedToApp() async {
    setState(() {
      _statusText = 'Hazir!';
    });
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    }
  }

  Future<void> _retryPermissions() async {
    setState(() {
      _permissionDenied = false;
      _needsManageStorage = false;
      _statusText = 'Izinler kontrol ediliyor...';
    });
    
    final permissionService = PermissionService();
    final hasPermission = await permissionService.requestAllPermissions();
    
    if (hasPermission) {
      _proceedToApp();
    } else {
      if (Platform.isAndroid && _androidVersion >= 30 && _androidVersion < 33) {
        setState(() {
          _statusText = 'Ozel izin gerekli!';
          _permissionDenied = true;
          _needsManageStorage = true;
        });
      } else {
        setState(() {
          _statusText = 'Izinler gerekli!';
          _permissionDenied = true;
        });
      }
    }
  }

  Future<void> _openSettings() async {
    final permissionService = PermissionService();
    if (_needsManageStorage) {
      await permissionService.openManageStorageSettings();
    } else {
      await permissionService.openSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accent.withValues(alpha: 0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'C',
                          style: TextStyle(
                            fontSize: 60,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Title
                    const Text(
                      'Coomer',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Downloader',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(height: 50),
                    // Status
                    if (!_permissionDenied) ...[
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      _statusText,
                      style: TextStyle(
                        fontSize: 14,
                        color: _permissionDenied 
                            ? AppTheme.error 
                            : AppTheme.textSecondaryDark,
                      ),
                    ),
                    // Permission denied actions
                    if (_permissionDenied) ...[
                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          _needsManageStorage
                              ? 'Android 11+ icin "Tum dosyalara erisim" izni gerekli.\n\nAyarlar > Izinler > Tum dosyalara erisim\'i acin.'
                              : 'Dosyalari indirmek icin depolama iznine ihtiyacimiz var.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondaryDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton(
                            onPressed: _openSettings,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.accent),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            child: Text(
                              _needsManageStorage ? 'Izin Ver' : 'Ayarlar',
                              style: const TextStyle(color: AppTheme.accent),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _retryPermissions,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            child: const Text(
                              'Tekrar Dene',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      if (_needsManageStorage) ...[
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () async {
                            final permissionService = PermissionService();
                            await permissionService.openSettings();
                          },
                          child: const Text(
                            'Uygulama Ayarlarina Git',
                            style: TextStyle(
                              color: AppTheme.textSecondaryDark,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
