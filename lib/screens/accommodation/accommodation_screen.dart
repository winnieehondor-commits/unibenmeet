import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants/app_constants.dart';
import '../../models/accommodation_model.dart';
import 'add_accommodation_screen.dart';
import 'accommodation_detail_screen.dart';

class AccommodationScreen extends StatefulWidget {
  const AccommodationScreen({Key? key}) : super(key: key);

  @override
  State<AccommodationScreen> createState() => _AccommodationScreenState();
}

class _AccommodationScreenState extends State<AccommodationScreen> {
  final _searchController = TextEditingController();
  String _selectedType = 'All';
  double _minPrice = 0;
  double _maxPrice = 10000000;
  bool _filterTiles = false;
  bool _filterWater = false;
  bool _filterLight = false;
  

  final List<String> _types = ['All', 'Single Room', 'Self Contain', 'Bedroom Flat'];

  @override
  void initState() {
    super.initState();
  }

  

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filters', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                Text('Type', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: _types.map((type) {
                    final isSelected = _selectedType == type;
                    return ChoiceChip(
                      label: Text(type),
                      selected: isSelected,
                      onSelected: (selected) {
                        setModalState(() => _selectedType = type);
                        setState(() => _selectedType = type);
                      },
                      selectedColor: AppColors.primaryPurple,
                      labelStyle: GoogleFonts.poppins(
                        color: isSelected ? AppColors.white : AppColors.black,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                
                Text('Price Range', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                RangeSlider(
                  values: RangeValues(_minPrice, _maxPrice),
                  min: 0,
                  max: 10000000,
                  divisions: 100,
                  activeColor: AppColors.primaryPurple,
                  labels: RangeLabels('\$${_minPrice.toInt()}', '\$${_maxPrice.toInt()}'),
                  onChanged: (values) {
                    setModalState(() {
                      _minPrice = values.start;
                      _maxPrice = values.end;
                    });
                    setState(() {
                      _minPrice = values.start;
                      _maxPrice = values.end;
                    });
                  },
                ),
                const SizedBox(height: 24),
                
                Text('Utilities', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                CheckboxListTile(
                  title: Text('Tiled', style: GoogleFonts.poppins()),
                  value: _filterTiles,
                  onChanged: (v) {
                    setModalState(() => _filterTiles = v!);
                    setState(() => _filterTiles = v!);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.primaryPurple,
                ),
                CheckboxListTile(
                  title: Text('Water', style: GoogleFonts.poppins()),
                  value: _filterWater,
                  onChanged: (v) {
                    setModalState(() => _filterWater = v!);
                    setState(() => _filterWater = v!);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.primaryPurple,
                ),
                CheckboxListTile(
                  title: Text('Light', style: GoogleFonts.poppins()),
                  value: _filterLight,
                  onChanged: (v) {
                    setModalState(() => _filterLight = v!);
                    setState(() => _filterLight = v!);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.primaryPurple,
                ),
                
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedType = 'All';
                            _minPrice = 0;
                            _maxPrice = 10000000;
                            _filterTiles = false;
                            _filterWater = false;
                            _filterLight = false;
                          });
                          setState(() {
                            _selectedType = 'All';
                            _minPrice = 0;
                            _maxPrice = 10000000;
                            _filterTiles = false;
                            _filterWater = false;
                            _filterLight = false;
                          });
                        },
                        child: Text('Reset', style: GoogleFonts.poppins()),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
                        child: Text('Apply', style: GoogleFonts.poppins(color: AppColors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: Text('Accommodation', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search location...',
                hintStyle: GoogleFonts.poppins(fontSize: 14, color: AppColors.grey),
                prefixIcon: const Icon(Icons.search, color: AppColors.grey),
                filled: true,
                fillColor: AppColors.lightGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance  // ← This line starts
                .collection(AppConstants.accommodationsCollection)  // ← Add this
                .where('isAvailable', isEqualTo: true)  // ← And this
                .orderBy('createdAt', descending: true)  // ← And this
                .snapshots(),  // ← Don't forget .snapshots()!
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryPurple),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home_work, size: 80, color: AppColors.grey.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text('No accommodations available', style: GoogleFonts.poppins(fontSize: 16)),
                      ],
                    ),
                  );
                }

                var accommodations = snapshot.data!.docs
                    .map((doc) => AccommodationModel.fromMap(doc.data() as Map<String, dynamic>))
                    .toList();

                // Apply filters
                accommodations = accommodations.where((acc) {
                  if (_selectedType != 'All' && 
                      acc.type.replaceAll('-', ' ').toLowerCase() != _selectedType.toLowerCase()) {
                    return false;
                  }
                  if (acc.price < _minPrice || acc.price > _maxPrice) return false;
                  if (_filterTiles && !acc.hasTiles) return false;
                  if (_filterWater && !acc.hasWater) return false;
                  if (_filterLight && !acc.hasLight) return false;
                  if (_searchController.text.isNotEmpty && 
                      !acc.location.toLowerCase().contains(_searchController.text.toLowerCase())) {
                    return false;
                  }
                  return true;
                }).toList();

                if (accommodations.isEmpty) {
                  return Center(
                    child: Text('No accommodations match your filters', style: GoogleFonts.poppins()),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: accommodations.length,
                  itemBuilder: (context, index) {
                    return _buildAccommodationCard(accommodations[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddAccommodationScreen()),
          );
        },
        backgroundColor: AppColors.primaryPurple,
        icon: const Icon(Icons.add, color: AppColors.white),
        label: Text('Post', style: GoogleFonts.poppins(color: AppColors.white)),
      ),
    );
  }

  Widget _buildAccommodationCard(AccommodationModel accommodation) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AccommodationDetailScreen(accommodation: accommodation),
          ),
        );
      },
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (accommodation.imageUrls.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: accommodation.imageUrls[0],
                  height: 200,
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
                          accommodation.title,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '\$${accommodation.price.toStringAsFixed(0)}/mo',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: AppColors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          accommodation.location,
                          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildFeatureBadge(Icons.bed, '${accommodation.bedrooms} Bed'),
                      const SizedBox(width: 8),
                      _buildFeatureBadge(Icons.bathroom, '${accommodation.bathrooms} Bath'),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.lightPurple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          accommodation.type.replaceAll('-', ' ').toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: AppColors.primaryPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (accommodation.hasTiles || accommodation.hasWater || accommodation.hasLight) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (accommodation.hasTiles) _buildUtilityBadge('Tiled'),
                        if (accommodation.hasWater) _buildUtilityBadge('Water'),
                        if (accommodation.hasLight) _buildUtilityBadge('Light'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.grey),
          const SizedBox(width: 4),
          Text(text, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.grey)),
        ],
      ),
    );
  }

  Widget _buildUtilityBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.successGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.successGreen.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          color: AppColors.successGreen,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}