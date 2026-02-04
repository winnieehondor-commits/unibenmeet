import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel {
  final String id;
  final String sellerId;
  final String sellerName;
  final String sellerImageUrl;
  final String title;
  final String description;
  final double price;
  final String category;
  final String phoneNumber;
  final String whatsappNumber;
  final String location;
  final List<String> imageUrls;
  final DateTime createdAt;
  final int views;
  final List<String> savedBy;

  ServiceModel({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    this.sellerImageUrl = '',
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.phoneNumber,
    required this.whatsappNumber,
    required this.location,
    this.imageUrls = const [],
    required this.createdAt,
    this.views = 0,
    this.savedBy = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerImageUrl': sellerImageUrl,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'phoneNumber': phoneNumber,
      'whatsappNumber': whatsappNumber,
      'location': location,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'views': views,
      'savedBy': savedBy,
    };
  }

  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'] ?? '',
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      sellerImageUrl: map['sellerImageUrl'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      whatsappNumber: map['whatsappNumber'] ?? '',
      location: map['location'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      views: map['views'] ?? 0,
      savedBy: List<String>.from(map['savedBy'] ?? []),
    );
  }
}