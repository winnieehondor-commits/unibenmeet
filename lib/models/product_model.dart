import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String sellerId;
  final String sellerName;
  final String sellerImageUrl;
  final String title;
  final String description;
  final double price;
  final String category;
  final List<String> imageUrls;
  final List<String> videoUrls;
  final String condition; // new, like-new, good, fair
  final String phoneNumber;
  final String whatsappNumber;
  final String location;
  final DateTime createdAt;
  final bool isSold;
  final int views;
  final List<String> likes;

  ProductModel({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    this.sellerImageUrl = '',
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrls,
    this.videoUrls = const [],
    this.condition = 'good',
    required this.phoneNumber,
    required this.whatsappNumber,
    required this.location,
    required this.createdAt,
    this.isSold = false,
    this.views = 0,
    this.likes = const [],
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
      'imageUrls': imageUrls,
      'videoUrls': videoUrls,
      'condition': condition,
      'phoneNumber': phoneNumber,
      'whatsappNumber': whatsappNumber,
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
      'isSold': isSold,
      'views': views,
      'likes': likes,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] ?? '',
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      sellerImageUrl: map['sellerImageUrl'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      videoUrls: List<String>.from(map['videoUrls'] ?? []),
      condition: map['condition'] ?? 'good',
      phoneNumber: map['phoneNumber'] ?? '',
      whatsappNumber: map['whatsappNumber'] ?? '',
      location: map['location'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isSold: map['isSold'] ?? false,
      views: map['views'] ?? 0,
      likes: List<String>.from(map['likes'] ?? []),
    );
  }
}