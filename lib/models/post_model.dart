import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String userId;
  final String username;
  final String? userAvatar;
  final String content;
  final List<String> mediaUrls;
  final List<String> mediaTypes; // 'image' or 'video'
  final String backgroundColor;
  final bool isAnonymous;
  final DateTime createdAt;
  final List<String> likes;
  final int commentsCount;
  final int shareCount;
  final bool isVideoReel;
  final String? videoThumbnail;

  PostModel({
    required this.id,
    required this.userId,
    required this.username,
    this.userAvatar,
    required this.content,
    this.mediaUrls = const [],
    this.mediaTypes = const [],
    this.backgroundColor = '#FFFFFF',
    this.isAnonymous = false,
    required this.createdAt,
    this.likes = const [],
    this.commentsCount = 0,
    this.shareCount = 0,
    this.isVideoReel = false,
    this.videoThumbnail,
  });

  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      username: map['username'] ?? 'Anonymous',
      userAvatar: map['userAvatar'],
      content: map['content'] ?? '',
      mediaUrls: List<String>.from(map['mediaUrls'] ?? []),
      mediaTypes: List<String>.from(map['mediaTypes'] ?? []),
      backgroundColor: map['backgroundColor'] ?? '#FFFFFF',
      isAnonymous: map['isAnonymous'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: List<String>.from(map['likes'] ?? []),
      commentsCount: map['commentsCount']?.toInt() ?? 0,
      shareCount: map['shareCount']?.toInt() ?? 0,
      isVideoReel: map['isVideoReel'] ?? false,
      videoThumbnail: map['videoThumbnail'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userAvatar': userAvatar,
      'content': content,
      'mediaUrls': mediaUrls,
      'mediaTypes': mediaTypes,
      'backgroundColor': backgroundColor,
      'isAnonymous': isAnonymous,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
      'commentsCount': commentsCount,
      'shareCount': shareCount,
      'isVideoReel': isVideoReel,
      'videoThumbnail': videoThumbnail,
    };
  }

  bool get hasMedia => mediaUrls.isNotEmpty;
  bool get hasImages => mediaTypes.contains('image');
  bool get hasVideos => mediaTypes.contains('video');
  int get likeCount => likes.length;
  bool isLikedBy(String userId) => likes.contains(userId);
}