class PostFile {
  final String name;
  final String path;

  PostFile({
    required this.name,
    required this.path,
  });

  factory PostFile.fromJson(Map<String, dynamic> json) {
    return PostFile(
      name: json['name'] ?? '',
      path: json['path'] ?? '',
    );
  }

  // path zaten tam URL olabilir (discord gibi) veya relative path olabilir
  String get url {
    if (path.startsWith('http')) {
      return path;
    }
    return 'https://coomer.st/data$path';
  }
  
  String get thumbnailUrl {
    if (path.startsWith('http')) {
      return path;
    }
    return 'https://img.coomer.st/thumbnail/data$path';
  }

  bool get isImage {
    final ext = name.toLowerCase();
    return ext.endsWith('.jpg') || 
           ext.endsWith('.jpeg') || 
           ext.endsWith('.png') || 
           ext.endsWith('.gif') ||
           ext.endsWith('.webp');
  }

  bool get isVideo {
    final ext = name.toLowerCase();
    return ext.endsWith('.mp4') || 
           ext.endsWith('.mov') || 
           ext.endsWith('.avi') ||
           ext.endsWith('.webm') ||
           ext.endsWith('.m4v');
  }

  String get extension => name.split('.').last.toLowerCase();
}

class PostAttachment {
  final String name;
  final String path;

  PostAttachment({
    required this.name,
    required this.path,
  });

  factory PostAttachment.fromJson(Map<String, dynamic> json) {
    return PostAttachment(
      name: json['name'] ?? '',
      path: json['path'] ?? '',
    );
  }

  String get url {
    if (path.startsWith('http')) {
      return path;
    }
    return 'https://coomer.st/data$path';
  }
}

class Post {
  final String id;
  final String user;
  final String service;
  final String title;
  final String? content;
  final String? published;
  final String? added;
  final String? edited;
  final PostFile? file;  // Tek dosya
  final List<PostFile> files;  // Dosya listesi
  final List<PostAttachment> attachments;

  Post({
    required this.id,
    required this.user,
    required this.service,
    required this.title,
    this.content,
    this.published,
    this.added,
    this.edited,
    this.file,
    required this.files,
    required this.attachments,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    // file alanı (tek dosya)
    PostFile? singleFile;
    if (json['file'] != null && json['file'] is Map) {
      final fileData = json['file'] as Map<String, dynamic>;
      if (fileData['name'] != null && fileData['name'].toString().isNotEmpty) {
        singleFile = PostFile.fromJson(fileData);
      }
    }

    // files alanı (dosya listesi)
    List<PostFile> filesList = [];
    if (json['file'] != null && json['file'] is List) {
      filesList = (json['file'] as List<dynamic>)
          .map((e) => PostFile.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (json['files'] != null) {
      filesList.addAll((json['files'] as List<dynamic>)
          .map((e) => PostFile.fromJson(e as Map<String, dynamic>))
          .toList());
    }

    return Post(
      id: json['id']?.toString() ?? '',
      user: json['user'] ?? '',
      service: json['service'] ?? '',
      title: json['title'] ?? 'Untitled',
      content: json['content'],
      published: json['published'],
      added: json['added'],
      edited: json['edited'],
      file: singleFile,
      files: filesList,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => PostAttachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  // Tüm dosyaları birleştir (C#'taki AllFiles gibi)
  List<PostFile> get allFiles {
    final result = <PostFile>[];
    if (file != null && file!.name.isNotEmpty) {
      result.add(file!);
    }
    result.addAll(files);
    return result;
  }

  int get totalMediaCount => allFiles.length + attachments.length;

  int get imageCount => allFiles.where((f) => f.isImage).length;

  int get videoCount => allFiles.where((f) => f.isVideo).length;

  String? get thumbnail {
    final imageFiles = allFiles.where((f) => f.isImage).toList();
    if (imageFiles.isNotEmpty) {
      return imageFiles.first.thumbnailUrl;
    }
    final videoFiles = allFiles.where((f) => f.isVideo).toList();
    if (videoFiles.isNotEmpty) {
      return videoFiles.first.thumbnailUrl;
    }
    return null;
  }

  String get formattedDate {
    if (published == null) return 'Unknown date';
    try {
      final date = DateTime.parse(published!);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return published!;
    }
  }

  // substring property (C#'taki gibi)
  String get substring {
    if (content == null || content!.isEmpty) return '';
    return content!.length > 50 ? '${content!.substring(0, 50)}...' : content!;
  }
}
