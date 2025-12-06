import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/creator.dart';
import '../models/post.dart';

class ConnectionStatus {
  final bool isConnected;
  final bool hasDpiBlock;
  final String message;

  ConnectionStatus({
    required this.isConnected,
    required this.hasDpiBlock,
    required this.message,
  });
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  late final Dio _dio;
  
  ApiService._internal() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      // ONEMLI: responseType'i plain olarak ayarla
      responseType: ResponseType.plain,
    ));
  }

  static const String _baseUrl = 'https://coomer.st';
  static const List<String> _services = ['onlyfans', 'fansly'];

  // Her request icin ozel header'lar - API bunu istiyor!
  Options get _requestOptions => Options(
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'text/css',  // API BU HEADER'I ISTIYOR!
      'Accept-Language': 'en-US,en;q=0.9',
      'Referer': 'https://coomer.st/',
    },
  );

  /// Kullanici adi ile creator ara
  Future<List<Creator>> searchCreators(String query) async {
    print('[API] SearchCreators called with query: "$query"');
    
    if (query.trim().isEmpty) {
      print('[API] Query is empty');
      return [];
    }

    final foundCreators = <Creator>[];
    final username = query.trim();

    print('[API] Searching for "$username" in ${_services.length} services');

    for (final service in _services) {
      try {
        final url = '$_baseUrl/api/v1/$service/user/$username/profile';
        print('[API] Trying: $url');
        
        final response = await _dio.get(url, options: _requestOptions);
        print('[API] $service responded with: ${response.statusCode}');

        if (response.statusCode == 200 && response.data != null) {
          final content = response.data.toString();
          print('[API] $service content length: ${content.length}');
          print('[API] $service content: ${content.substring(0, content.length > 300 ? 300 : content.length)}');
          
          // JSON parse et
          try {
            final Map<String, dynamic> jsonData = jsonDecode(content);
            final creator = Creator.fromJson(jsonData);
            
            print('[API] Creator deserialized: id=${creator.id}, name=${creator.name}');
            
            if (creator.id.isNotEmpty) {
              final creatorWithService = Creator(
                id: creator.id,
                name: creator.name,
                service: creator.service.isEmpty ? service : creator.service,
                indexed: creator.indexed,
                updated: creator.updated,
                publicId: creator.publicId,
                relationId: creator.relationId,
                postCount: creator.postCount,
                dmCount: creator.dmCount,
                shareCount: creator.shareCount,
                chatCount: creator.chatCount,
              );
              foundCreators.add(creatorWithService);
              print('[API] Found creator on $service!');
            }
          } catch (parseError) {
            print('[API] JSON parse error: $parseError');
          }
        }
      } on DioException catch (e) {
        print('[API] DioException for $service: ${e.type} - ${e.message}');
        print('[API] Response data: ${e.response?.data}');
        print('[API] Response status: ${e.response?.statusCode}');
        continue;
      } catch (e) {
        print('[API] ERROR for $service: $e');
        continue;
      }
    }

    print('[API] Search complete. Total found: ${foundCreators.length}');
    return foundCreators;
  }

  /// Creator'in tum postlarini cek
  Future<List<Post>> getCreatorPosts(String service, String creatorId) async {
    try {
      final allPosts = <Post>[];
      int offset = 0;
      const pageSize = 50;
      bool hasMorePosts = true;

      print('[API] Starting to fetch all posts for $service/$creatorId');

      while (hasMorePosts) {
        final url = offset == 0 
            ? '$_baseUrl/api/v1/$service/user/$creatorId/posts'
            : '$_baseUrl/api/v1/$service/user/$creatorId/posts?o=$offset';
            
        print('[API] Fetching page at offset $offset: $url');

        final response = await _dio.get(url, options: _requestOptions);
        print('[API] Response status: ${response.statusCode}');

        if (response.statusCode == 200 && response.data != null) {
          try {
            final List<dynamic> data = jsonDecode(response.data.toString());
            
            if (data.isNotEmpty) {
              final posts = data.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
              print('[API] Received ${posts.length} posts at offset $offset');
              allPosts.addAll(posts);

              if (posts.length < pageSize) {
                print('[API] Received less than $pageSize posts, reached end');
                hasMorePosts = false;
              } else {
                offset += pageSize;
              }
            } else {
              print('[API] No more posts found at offset $offset');
              hasMorePosts = false;
            }
          } catch (parseError) {
            print('[API] JSON parse error: $parseError');
            hasMorePosts = false;
          }
        } else {
          print('[API] Failed to get posts at offset $offset: ${response.statusCode}');
          hasMorePosts = false;
        }
      }

      print('[API] Total posts fetched: ${allPosts.length}');
      return allPosts;
    } on DioException catch (e) {
      print('[API] DioException getting posts: ${e.message}');
      return [];
    } catch (e) {
      print('[API] ERROR getting posts: $e');
      return [];
    }
  }

  /// Sayfali post cekme
  Future<List<Post>> getCreatorPostsPaginated(
    String service,
    String creatorId, {
    int offset = 0,
  }) async {
    try {
      final url = offset == 0 
          ? '$_baseUrl/api/v1/$service/user/$creatorId/posts'
          : '$_baseUrl/api/v1/$service/user/$creatorId/posts?o=$offset';
          
      print('[API] Fetching posts: $url');

      final response = await _dio.get(url, options: _requestOptions);

      if (response.statusCode == 200 && response.data != null) {
        try {
          final List<dynamic> data = jsonDecode(response.data.toString());
          return data.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
        } catch (e) {
          print('[API] Parse error: $e');
        }
      }
      return [];
    } on DioException catch (e) {
      print('[API] DioException: ${e.message}');
      return [];
    } catch (e) {
      print('[API] ERROR: $e');
      return [];
    }
  }

  /// Baglanti durumu kontrol
  Future<ConnectionStatus> checkConnectionStatus() async {
    try {
      print('[API] Checking connection to coomer.st...');

      try {
        final response = await _dio.get('$_baseUrl/', options: _requestOptions);
        
        if (response.statusCode == 200) {
          print('[API] HTTP request successful');
          return ConnectionStatus(
            isConnected: true,
            hasDpiBlock: false,
            message: 'Connection successful',
          );
        }
      } on DioException catch (e) {
        print('[API] HTTP request failed: ${e.message}');
        
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError) {
          print('[API] DPI block detected!');
          return ConnectionStatus(
            isConnected: false,
            hasDpiBlock: true,
            message: 'DPI block detected',
          );
        }
      }

      return ConnectionStatus(
        isConnected: false,
        hasDpiBlock: false,
        message: 'Connection failed',
      );
    } catch (e) {
      print('[API] Connection check failed: $e');
      return ConnectionStatus(
        isConnected: false,
        hasDpiBlock: false,
        message: 'Error: $e',
      );
    }
  }

  /// Dosya indir
  Future<List<int>> downloadFile(String url) async {
    final response = await _dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data ?? [];
  }
}
