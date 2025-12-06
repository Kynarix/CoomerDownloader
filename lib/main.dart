import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'providers/download_provider.dart';
import 'services/storage_service.dart';
import 'screens/splash_screen.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services and providers with saved data
  final storageService = StorageService();
  final appProvider = AppProvider();
  final downloadProvider = DownloadProvider();
  
  await Future.wait([
    storageService.init(),
    appProvider.init(),
    downloadProvider.init(),
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.primaryDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(CoomerApp(
    appProvider: appProvider,
    downloadProvider: downloadProvider,
  ));
}

class CoomerApp extends StatelessWidget {
  final AppProvider appProvider;
  final DownloadProvider downloadProvider;
  
  const CoomerApp({
    super.key,
    required this.appProvider,
    required this.downloadProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appProvider),
        ChangeNotifierProvider.value(value: downloadProvider),
      ],
      child: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          // Update system UI based on theme
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: appProvider.themeMode == ThemeMode.dark
                  ? Brightness.light
                  : Brightness.dark,
              systemNavigationBarColor: appProvider.themeMode == ThemeMode.dark
                  ? AppTheme.primaryDark
                  : AppTheme.primaryLight,
              systemNavigationBarIconBrightness:
                  appProvider.themeMode == ThemeMode.dark
                      ? Brightness.light
                      : Brightness.dark,
            ),
          );

          return MaterialApp(
            title: 'Coomer Downloader',
            debugShowCheckedModeBanner: false,
            themeMode: appProvider.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
