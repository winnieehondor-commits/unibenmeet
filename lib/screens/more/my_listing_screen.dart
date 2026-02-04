import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants/app_constants.dart';
import '../../models/accommodation_model.dart';
import '../../models/product_model.dart';
import '../../services/auth_service.dart';
import 'edit_accommodation_screen.dart';
import 'edit_marketplace_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({Key? key}) : super(key: key);

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  final AuthService _authService = AuthService();
  int _selectedCategory = 0; // 0: All, 1: Accommodation, 2: Marketplace

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('My Listings', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.primaryPurple,
          foregroundColor: AppColors.white,
          bottom: TabBar(
            indicatorColor: AppColors.white,
            labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Accommodation'),
              Tab(text: 'Marketplace'),
            ],
          ),
        ),
        body: Builder(
          builder: (context) {
            final userId = _authService.currentUser?.uid;
            
            if (userId == null) {
              return const Center(child: Text('Please login to view listings'));
            }
            
            return TabBarView(
              children: [
                // All Listings
                _buildAllListings(userId),
                // Accommodation Listings
                _buildAccommodationListings(userId),
                // Marketplace Listings
                _buildMarketplaceListings(userId),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAllListings(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.accommodationsCollection)
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, accSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(AppConstants.productsCollection)
              .where('userId', isEqualTo: userId)
              .snapshots(),
          builder: (context, marketSnapshot) {
            if (accSnapshot.connectionState == ConnectionState.waiting ||
                marketSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final accDocs = accSnapshot.data?.docs ?? [];
            final marketDocs = marketSnapshot.data?.docs ?? [];
            final allDocs = [...accDocs, ...marketDocs]..sort((a, b) {
                final aTime = a['createdAt'] as Timestamp? ?? Timestamp.now();
                final bTime = b['createdAt'] as Timestamp? ?? Timestamp.now();
                return bTime.compareTo(aTime);
              });

            if (allDocs.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allDocs.length,
              itemBuilder: (context, index) {
                final doc = allDocs[index];
                final isAccommodation = doc.reference.path.contains('accommodations');
                return _buildListingCard(doc, isAccommodation);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAccommodationListings(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.accommodationsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(message: 'No accommodation listings');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            return _buildListingCard(doc, true);
          },
        );
      },
    );
  }

  Widget _buildMarketplaceListings(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.productsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(message: 'No marketplace listings');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            return _buildListingCard(doc, false);
          },
        );
      },
    );
  }

  Widget _buildListingCard(QueryDocumentSnapshot doc, bool isAccommodation) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] ?? 'Untitled';
    final price = data['price']?.toDouble() ?? 0.0;
    final createdAt = data['createdAt'] as Timestamp? ?? Timestamp.now();
    final imageUrls = List<String>.from(data['imageUrls'] ?? []);
    final isAvailable = data['isAvailable'] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image Section
          if (imageUrls.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: imageUrls[0],
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAccommodation 
                            ? AppColors.lightPurple.withOpacity(0.2)
                            : AppColors.successGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isAccommodation ? 'Accommodation' : 'Marketplace',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isAccommodation ? AppColors.primaryPurple : AppColors.successGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${price.toStringAsFixed(0)}${isAccommodation ? '/mo' : ''}',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAvailable 
                            ? AppColors.successGreen.withOpacity(0.1)
                            : AppColors.errorRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isAvailable 
                              ? AppColors.successGreen.withOpacity(0.3)
                              : AppColors.errorRed.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        isAvailable ? 'Available' : 'Sold/Rented',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isAvailable ? AppColors.successGreen : AppColors.errorRed,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: AppColors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Posted ${_formatDate(createdAt.toDate())}',
                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey),
                    ),
                    const Spacer(),
                    _buildActionButtons(doc, isAccommodation, data),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(QueryDocumentSnapshot doc, bool isAccommodation, Map<String, dynamic> data) {
    return Row(
      children: [
        // Edit Button
        IconButton(
          onPressed: () => _editListing(doc, isAccommodation, data),
          icon: Icon(Icons.edit, size: 20, color: AppColors.primaryPurple),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        // Delete Button
        IconButton(
          onPressed: () => _deleteListing(doc, isAccommodation),
          icon: Icon(Icons.delete, size: 20, color: AppColors.errorRed),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  void _editListing(QueryDocumentSnapshot doc, bool isAccommodation, Map<String, dynamic> data) {
    if (isAccommodation) {
      final accommodation = AccommodationModel.fromMap(data);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditAccommodationScreen(
            accommodation: accommodation,
            docId: doc.id,
          ),
        ),
      );
    } else {
      final marketplace = ProductModel.fromMap(data);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditMarketplaceScreen(
            product: marketplace,
            docId: doc.id,
          ),
        ),
      );
    }
  }

  void _deleteListing(QueryDocumentSnapshot doc, bool isAccommodation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Listing', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this listing?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await doc.reference.delete();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${isAccommodation ? 'Accommodation' : 'Product'} deleted successfully'),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: AppColors.errorRed,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
            child: Text('Delete', style: GoogleFonts.poppins(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({String message = 'No listings found'}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.list_alt, size: 80, color: AppColors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(message, style: GoogleFonts.poppins(fontSize: 16, color: AppColors.grey)),
          const SizedBox(height: 8),
          Text(
            'Your listings will appear here',
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}