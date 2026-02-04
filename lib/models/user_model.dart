import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String username;
  final String? profileImageUrl;
  final String? bio;
  final DateTime createdAt;
  final List<String> savedItems;
  final List<String> followers;
  final List<String> following;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.profileImageUrl,
    this.bio,
    required this.createdAt,
    this.savedItems = const [],
    this.followers = const [],
    this.following = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'createdAt': Timestamp.fromDate(createdAt),
      'savedItems': savedItems,
      'followers': followers,
      'following': following,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      bio: map['bio'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      savedItems: List<String>.from(map['savedItems'] ?? []),
      followers: List<String>.from(map['followers'] ?? []),
      following: List<String>.from(map['following'] ?? []),
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    String? profileImageUrl,
    String? bio,
    DateTime? createdAt,
    List<String>? savedItems,
    List<String>? followers,
    List<String>? following,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      savedItems: savedItems ?? this.savedItems,
      followers: followers ?? this.followers,
      following: following ?? this.following,
    );
  }
}