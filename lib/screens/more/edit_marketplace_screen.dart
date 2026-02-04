import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_constants.dart';
import '../../models/product_model.dart';
import '../../services/storage_service.dart';
import 'dart:io';

class EditMarketplaceScreen extends StatefulWidget {
  final ProductModel product;
  final String docId;

  const EditMarketplaceScreen({
    Key? key,
    required this.product,
    required this.docId,
  }) : super(key: key);

  @override
  State<EditMarketplaceScreen> createState() => _EditMarketplaceScreenState();
}

class _EditMarketplaceScreenState extends State<EditMarketplaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  String _selectedCategory = '';
  String _selectedCondition = '';
  bool _isAvailable = true;
  bool _isLoading = false;
  List<String> _imageUrls = [];
  List<XFile> _newImages = [];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    final product = widget.product;
    _titleController.text = product.title;
    _priceController.text = product.price.toStringAsFixed(0);
    _descriptionController.text = product.description;
    _locationController.text = product.location;
    _selectedCategory = product.category;
    _selectedCondition = product.condition;
    _isAvailable = product.isSold;
    _imageUrls = List.from(product.imageUrls);
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _newImages.addAll(images);
      });
    }
  }

  void _removeImage(int index, bool isNew) {
    setState(() {
      if (isNew) {
        _newImages.removeAt(index);
      } else {
        _imageUrls.removeAt(index);
      }
    });
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Upload new images
      if (_newImages.isNotEmpty) {
        final newUrls = await _storageService.uploadImages(
          _newImages.map((xfile) => File(xfile.path)).toList(),  // Convert XFile to File
          'marketplace',
        );
        _imageUrls.addAll(newUrls);
      }

      final updatedData = {
        'title': _titleController.text.trim(),
        'price': double.parse(_priceController.text),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'category': _selectedCategory,
        'condition': _selectedCondition,
        'imageUrls': _imageUrls,
        'isAvailable': _isAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection(AppConstants.productsCollection)
          .doc(widget.docId)
          .update(updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product updated successfully!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: Text('Edit Product', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Images Section (same as accommodation)
              _buildImagesSection(),
              const SizedBox(height: 20),
              
              // Form Section
              _buildFormSection(),
              const SizedBox(height: 30),
              
              // Update Button
              SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: AppColors.white)
                      : Text(
                          'Update Product',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagesSection() {
    // Same as EditAccommodationScreen._buildImagesSection()
    // Copy the exact same code from above
    final allImages = [
      ..._imageUrls.map((url) => {'url': url, 'isNew': false}),
      ..._newImages.map((file) => {'file': file, 'isNew': true}),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Images', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        if (allImages.isEmpty)
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library, size: 40, color: AppColors.grey),
                const SizedBox(height: 8),
                Text('No images', style: GoogleFonts.poppins(color: AppColors.grey)),
              ],
            ),
          )
        else
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: allImages.length + 1,
              itemBuilder: (context, index) {
                if (index == allImages.length) {
                  return GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderColor),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, color: AppColors.primaryPurple),
                          const SizedBox(height: 8),
                          Text('Add More', style: GoogleFonts.poppins(fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                }

                final item = allImages[index];
                final isNew = item['isNew'] as bool;

                return Stack(
                  children: [
                    Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: isNew
                          ? DecorationImage(
                              image: FileImage(File((item['file'] as XFile).path)),  // Add File() wrapper
                              fit: BoxFit.cover,
                            )
                          : DecorationImage(
                              image: NetworkImage(item['url'] as String),
                              fit: BoxFit.cover,
                            ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 16,
                      child: GestureDetector(
                        onTap: () => _removeImage(index, isNew),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.errorRed.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Add Images'),
        ),
      ],
    );
  }

  Widget _buildFormSection() {
    const categories = ['Electronics', 'Furniture', 'Books', 'Clothing', 'Others'];
    const conditions = ['New', 'Used - Like New', 'Used - Good', 'Used - Fair'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          _buildTextField(_titleController, 'Title', 'e.g., MacBook Pro 2020'),
          const SizedBox(height: 16),

          // Price
          _buildTextField(_priceController, 'Price (\$)', 'e.g., 1200'),
          const SizedBox(height: 16),

          // Location
          _buildTextField(_locationController, 'Location', 'e.g., Main Campus, Block B'),
          const SizedBox(height: 16),

          // Category
          Text('Category', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: categories.map((category) {
              final isSelected = _selectedCategory == category;
              return ChoiceChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) => setState(() => _selectedCategory = category),
                selectedColor: AppColors.primaryPurple,
                labelStyle: GoogleFonts.poppins(
                  color: isSelected ? AppColors.white : AppColors.black,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Condition
          Text('Condition', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: conditions.map((condition) {
              final isSelected = _selectedCondition == condition;
              return ChoiceChip(
                label: Text(condition),
                selected: isSelected,
                onSelected: (selected) => setState(() => _selectedCondition = condition),
                selectedColor: AppColors.primaryPurple,
                labelStyle: GoogleFonts.poppins(
                  color: isSelected ? AppColors.white : AppColors.black,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Description
          Text('Description', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Describe your product...',
              filled: true,
              fillColor: AppColors.lightGrey,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Availability
          SwitchListTile(
            title: const Text('Available for sale'),
            value: _isAvailable,
            onChanged: (v) => setState(() => _isAvailable = v),
            activeColor: AppColors.primaryPurple,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: (v) => v!.isEmpty ? 'Required' : null,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.lightGrey,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}