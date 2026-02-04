import 'package:cloud_firestore/cloud_firestore.dart';

class AccommodationModel {
  final String id;
  final String ownerId;
  final String ownerName;
  final String ownerImageUrl;
  final String title;
  final String description;
  final double price;
  final String location;
  final String address;
  final String phoneNumber;
  final String whatsappNumber;
  final List<String> features;
  final List<String> imageUrls;
  final List<String> videoUrls;
  final int bedrooms;
  final int bathrooms;
  final String type; // single-room, self-contain, bedroom-flat
  final bool hasTiles;
  final bool hasWater;
  final bool hasLight;
  final DateTime createdAt;
  final bool isAvailable;
  final int views;
  final List<String> savedBy;

  AccommodationModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    this.ownerImageUrl = '',
    required this.title,
    required this.description,
    required this.price,
    required this.location,
    required this.address,
    required this.phoneNumber,
    required this.whatsappNumber,
    this.features = const [],
    required this.imageUrls,
    this.videoUrls = const [],
    this.bedrooms = 1,
    this.bathrooms = 1,
    this.type = 'single-room',
    this.hasTiles = false,
    this.hasWater = false,
    this.hasLight = false,
    required this.createdAt,
    this.isAvailable = true,
    this.views = 0,
    this.savedBy = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerImageUrl': ownerImageUrl,
      'title': title,
      'description': description,
      'price': price,
      'location': location,
      'address': address,
      'phoneNumber': phoneNumber,
      'whatsappNumber': whatsappNumber,
      'features': features,
      'imageUrls': imageUrls,
      'videoUrls': videoUrls,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'type': type,
      'hasTiles': hasTiles,
      'hasWater': hasWater,
      'hasLight': hasLight,
      'createdAt': Timestamp.fromDate(createdAt),
      'isAvailable': isAvailable,
      'views': views,
      'savedBy': savedBy,
    };
  }

  factory AccommodationModel.fromMap(Map<String, dynamic> map) {
    return AccommodationModel(
      id: map['id'] ?? '',
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      ownerImageUrl: map['ownerImageUrl'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      location: map['location'] ?? '',
      address: map['address'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      whatsappNumber: map['whatsappNumber'] ?? '',
      features: List<String>.from(map['features'] ?? []),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      videoUrls: List<String>.from(map['videoUrls'] ?? []),
      bedrooms: map['bedrooms'] ?? 1,
      bathrooms: map['bathrooms'] ?? 1,
      type: map['type'] ?? 'single-room',
      hasTiles: map['hasTiles'] ?? false,
      hasWater: map['hasWater'] ?? false,
      hasLight: map['hasLight'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isAvailable: map['isAvailable'] ?? true,
      views: map['views'] ?? 0,
      savedBy: List<String>.from(map['savedBy'] ?? []),
    );
  }
}