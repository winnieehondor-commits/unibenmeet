import 'package:cloud_firestore/cloud_firestore.dart';

class VotingModel {
  final String id;
  final String creatorId;
  final String creatorName;
  final String title;
  final String award;
  final String position;
  final List<Contestant> contestants;
  final DateTime createdAt;
  final DateTime? endDate;
  final bool isActive;
  final String shareableLink;

  VotingModel({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    required this.title,
    required this.award,
    required this.position,
    required this.contestants,
    required this.createdAt,
    this.endDate,
    this.isActive = true,
    required this.shareableLink,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'title': title,
      'award': award,
      'position': position,
      'contestants': contestants.map((c) => c.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isActive': isActive,
      'shareableLink': shareableLink,
    };
  }

  factory VotingModel.fromMap(Map<String, dynamic> map) {
    return VotingModel(
      id: map['id'] ?? '',
      creatorId: map['creatorId'] ?? '',
      creatorName: map['creatorName'] ?? '',
      title: map['title'] ?? '',
      award: map['award'] ?? '',
      position: map['position'] ?? '',
      contestants: (map['contestants'] as List)
          .map((c) => Contestant.fromMap(c))
          .toList(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      endDate: map['endDate'] != null
          ? (map['endDate'] as Timestamp).toDate()
          : null,
      isActive: map['isActive'] ?? true,
      shareableLink: map['shareableLink'] ?? '',
    );
  }
}

class Contestant {
  final String id;
  final String name;
  final String tag;
  final String? imageUrl;
  final int votes;
  final List<String> voters;

  Contestant({
    required this.id,
    required this.name,
    required this.tag,
    this.imageUrl,
    this.votes = 0,
    this.voters = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'tag': tag,
      'imageUrl': imageUrl,
      'votes': votes,
      'voters': voters,
    };
  }

  factory Contestant.fromMap(Map<String, dynamic> map) {
    return Contestant(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      tag: map['tag'] ?? '',
      imageUrl: map['imageUrl'],
      votes: map['votes'] ?? 0,
      voters: List<String>.from(map['voters'] ?? []),
    );
  }
}