import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/creator.dart';
import '../models/post.dart';
import '../services/api_service.dart';

class AppProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  SharedPreferences? _prefs;

  // Storage keys
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyFavorites = 'favorites';
  static const String _keyRecentSearches = 'recent_searches';

  // Theme
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  /// Initialize provider with saved data
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    if (_prefs == null) return;

    // Load theme
    final themeIndex = _prefs!.getInt(_keyThemeMode) ?? 1; // 1 = dark
    _themeMode = themeIndex == 0 ? ThemeMode.light : ThemeMode.dark;

    // Load favorites
    final favoritesJson = _prefs!.getStringList(_keyFavorites) ?? [];
    _favorites.clear();
    for (final json in favoritesJson) {
      try {
        final map = jsonDecode(json) as Map<String, dynamic>;
        _favorites.add(Creator.fromJson(map));
      } catch (e) {
        print('[Provider] Error loading favorite: $e');
      }
    }

    // Load recent searches
    final searches = _prefs!.getStringList(_keyRecentSearches) ?? [];
    _recentSearches.clear();
    _recentSearches.addAll(searches);

    notifyListeners();
  }

  Future<void> _saveFavorites() async {
    if (_prefs == null) return;
    final jsonList = _favorites.map((c) => jsonEncode(c.toJson())).toList();
    await _prefs!.setStringList(_keyFavorites, jsonList);
  }

  Future<void> _saveRecentSearches() async {
    if (_prefs == null) return;
    await _prefs!.setStringList(_keyRecentSearches, _recentSearches);
  }

  Future<void> _saveTheme() async {
    if (_prefs == null) return;
    await _prefs!.setInt(_keyThemeMode, _themeMode == ThemeMode.light ? 0 : 1);
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _saveTheme();
    notifyListeners();
  }

  // Connection Status
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  
  bool _hasDpiBlock = false;
  bool get hasDpiBlock => _hasDpiBlock;
  
  String _connectionMessage = '';
  String get connectionMessage => _connectionMessage;

  Future<void> checkConnection() async {
    final status = await _apiService.checkConnectionStatus();
    _isConnected = status.isConnected;
    _hasDpiBlock = status.hasDpiBlock;
    _connectionMessage = status.message;
    notifyListeners();
  }

  // Search
  String _searchQuery = '';
  String get searchQuery => _searchQuery;
  
  List<Creator> _searchResults = [];
  List<Creator> get searchResults => _searchResults;
  
  bool _isSearching = false;
  bool get isSearching => _isSearching;

  Future<void> search(String query) async {
    _searchQuery = query;
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      _searchResults = await _apiService.searchCreators(query);
    } catch (e) {
      print('[Provider] Search error: $e');
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    notifyListeners();
  }

  // Creator Detail
  Creator? _selectedCreator;
  Creator? get selectedCreator => _selectedCreator;

  List<Post> _creatorPosts = [];
  List<Post> get creatorPosts => _creatorPosts;

  bool _isLoadingPosts = false;
  bool get isLoadingPosts => _isLoadingPosts;

  bool _hasMorePosts = true;
  bool get hasMorePosts => _hasMorePosts;

  int _postsOffset = 0;
  bool _isLoadingAllPosts = false;
  bool get isLoadingAllPosts => _isLoadingAllPosts;

  void selectCreator(Creator creator) {
    _selectedCreator = creator;
    _creatorPosts = [];
    _postsOffset = 0;
    _hasMorePosts = true;
    notifyListeners();
    loadCreatorPosts();
  }

  /// Tum postlari yukle (C# gibi tum sayfalari ceker)
  Future<void> loadAllCreatorPosts() async {
    if (_selectedCreator == null) return;
    if (_isLoadingAllPosts) return;

    _isLoadingAllPosts = true;
    _isLoadingPosts = true;
    _creatorPosts = [];
    notifyListeners();

    try {
      _creatorPosts = await _apiService.getCreatorPosts(
        _selectedCreator!.service,
        _selectedCreator!.id,
      );
      _hasMorePosts = false;
    } catch (e) {
      print('[Provider] Load all posts error: $e');
    } finally {
      _isLoadingAllPosts = false;
      _isLoadingPosts = false;
      notifyListeners();
    }
  }

  /// Sayfali post yukleme (lazy loading)
  Future<void> loadCreatorPosts({bool loadMore = false}) async {
    if (_selectedCreator == null) return;
    if (_isLoadingPosts) return;
    if (loadMore && !_hasMorePosts) return;

    _isLoadingPosts = true;
    if (!loadMore) {
      _creatorPosts = [];
      _postsOffset = 0;
    }
    notifyListeners();

    try {
      final posts = await _apiService.getCreatorPostsPaginated(
        _selectedCreator!.service,
        _selectedCreator!.id,
        offset: _postsOffset,
      );

      if (posts.isEmpty) {
        _hasMorePosts = false;
      } else {
        _creatorPosts.addAll(posts);
        _postsOffset += posts.length;
        _hasMorePosts = posts.length >= 50;
      }
    } catch (e) {
      print('[Provider] Load posts error: $e');
    } finally {
      _isLoadingPosts = false;
      notifyListeners();
    }
  }

  void clearCreator() {
    _selectedCreator = null;
    _creatorPosts = [];
    _postsOffset = 0;
    _hasMorePosts = true;
    notifyListeners();
  }

  // Favorites
  final List<Creator> _favorites = [];
  List<Creator> get favorites => List.unmodifiable(_favorites);

  bool isFavorite(Creator creator) {
    return _favorites.any((c) => c.id == creator.id && c.service == creator.service);
  }

  void toggleFavorite(Creator creator) {
    if (isFavorite(creator)) {
      _favorites.removeWhere((c) => c.id == creator.id && c.service == creator.service);
    } else {
      _favorites.add(creator);
    }
    _saveFavorites();
    notifyListeners();
  }

  // Recent searches
  final List<String> _recentSearches = [];
  List<String> get recentSearches => List.unmodifiable(_recentSearches);

  void addRecentSearch(String query) {
    if (query.isEmpty) return;
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
    if (_recentSearches.length > 10) {
      _recentSearches.removeLast();
    }
    _saveRecentSearches();
    notifyListeners();
  }

  void clearRecentSearches() {
    _recentSearches.clear();
    _saveRecentSearches();
    notifyListeners();
  }
}
