class Creator {
  final String id;
  final String name;
  final String service;
  final String? indexed;
  final String? updated;
  final String? publicId;
  final String? relationId;
  final int? postCount;
  final int? dmCount;
  final int? shareCount;
  final int? chatCount;

  Creator({
    required this.id,
    required this.name,
    required this.service,
    this.indexed,
    this.updated,
    this.publicId,
    this.relationId,
    this.postCount,
    this.dmCount,
    this.shareCount,
    this.chatCount,
  });

  factory Creator.fromJson(Map<String, dynamic> json) {
    return Creator(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown',
      service: json['service'] ?? 'onlyfans',
      indexed: json['indexed'],
      updated: json['updated'],
      publicId: json['public_id'],
      relationId: json['relation_id'],
      postCount: json['post_count'],
      dmCount: json['dm_count'],
      shareCount: json['share_count'],
      chatCount: json['chat_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'service': service,
      'indexed': indexed,
      'updated': updated,
      'public_id': publicId,
      'relation_id': relationId,
      'post_count': postCount,
      'dm_count': dmCount,
      'share_count': shareCount,
      'chat_count': chatCount,
    };
  }

  String get profileUrl => 'https://img.coomer.st/icons/$service/$id';
  
  String get bannerUrl => 'https://img.coomer.st/banners/$service/$id';

  String get serviceDisplayName {
    switch (service.toLowerCase()) {
      case 'onlyfans':
        return 'OnlyFans';
      case 'fansly':
        return 'Fansly';
      case 'candfans':
        return 'CandFans';
      default:
        return service;
    }
  }
}
