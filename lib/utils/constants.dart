class ApiConstants {
  static const String baseUrl = 'https://coomer.st';
  
  // Image URLs
  static String iconUrl(String service, String id) => 
      'https://img.coomer.st/icons/$service/$id';
  
  static String bannerUrl(String service, String id) => 
      'https://img.coomer.st/banners/$service/$id';
  
  static String thumbnailUrl(String path) => 
      'https://img.coomer.st/thumbnail/data$path';
  
  static String dataUrl(String path) => 
      '$baseUrl/data$path';
}

class AppConstants {
  static const String appName = 'Coomer Downloader';
  static const String appVersion = '1.0.0';
  static const int postsPerPage = 50;
  static const int searchDebounceMs = 500;
  static const int maxConcurrentDownloads = 3;
}

class StorageKeys {
  static const String theme = 'app_theme';
  static const String downloadPath = 'download_path';
  static const String favorites = 'favorites';
  static const String searchHistory = 'search_history';
}
