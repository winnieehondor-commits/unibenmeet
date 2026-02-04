import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_constants.dart';
import '../../models/accommodation_model.dart';
import '../../services/storage_service.dart';
import 'dart:io';

class EditAccommodationScreen extends StatefulWidget {
  final AccommodationModel accommodation;
  final String docId;

  const EditAccommodationScreen({
    Key? key,
    required this.accommodation,
    required this.docId,
  }) : super(key: key);

  @override
  State<EditAccommodationScreen> createState() => _EditAccommodationScreenState();
}

class _EditAccommodationScreenState extends State<EditAccommodationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  String _selectedType = '';
  int _bedrooms = 1;
  int _bathrooms = 1;
  bool _hasTiles = false;
  bool _hasWater = false;
  bool _hasLight = false;
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
    final acc = widget.accommodation;
    _titleController.text = acc.title;
    _priceController.text = acc.price.toStringAsFixed(0);
    _locationController.text = acc.location;
    _descriptionController.text = acc.description;
    _selectedType = acc.type;
    _bedrooms = acc.bedrooms;
    _bathrooms = acc.bathrooms;
    _hasTiles = acc.hasTiles;
    _hasWater = acc.hasWater;
    _hasLight = acc.hasLight;
    _isAvailable = acc.isAvailable;
    _imageUrls = List.from(acc.imageUrls);
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

  Future<void> _updateAccommodation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Upload new images
      
      if (_newImages.isNotEmpty) {
        final newUrls = await _storageService.uploadImages(
          _newImages.map((xfile) => File(xfile.path)).toList(),  // Convert XFile to File
          'accommodations',
        );
        _imageUrls.addAll(newUrls);
      }

      final updatedData = {
        'title': _titleController.text.trim(),
        'price': double.parse(_priceController.text),
        'location': _locationController.text.trim(),
        'type': _selectedType,
        'bedrooms': _bedrooms,
        'bathrooms': _bathrooms,
        'hasTiles': _hasTiles,
        'hasWater': _hasWater,
        'hasLight': _hasLight,
        'description': _descriptionController.text.trim(),
        'imageUrls': _imageUrls,
        'isAvailable': _isAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection(AppConstants.accommodationsCollection)
          .doc(widget.docId)
          .update(updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Accommodation updated successfully!'),
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
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: Text('Edit Accommodation', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Images Section
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
                  onPressed: _isLoading ? null : _updateAccommodation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: AppColors.white)
                      : Text(
                          'Update Accommodation',
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
    const types = ['Single-Room', 'Self-Contain', 'Bedroom-Flat'];

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
          _buildTextField(_titleController, 'Title', 'e.g., Cozy Apartment near Campus'),
          const SizedBox(height: 16),

          // Price
          _buildTextField(_priceController, 'Price (\$/month)', 'e.g., 500'),
          const SizedBox(height: 16),

          // Location
          _buildTextField(_locationController, 'Location', 'e.g., Ugbowo, Benin City'),
          const SizedBox(height: 16),

          // Type
          Text('Type', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: types.map((type) {
              final isSelected = _selectedType == type;
              return ChoiceChip(
                label: Text(type),
                selected: isSelected,
                onSelected: (selected) => setState(() => _selectedType = type),
                selectedColor: AppColors.primaryPurple,
                labelStyle: GoogleFonts.poppins(
                  color: isSelected ? AppColors.white : AppColors.black,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Bedrooms & Bathrooms
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bedrooms', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _bedrooms > 1 ? () => setState(() => _bedrooms--) : null,
                          icon: const Icon(Icons.remove),
                        ),
                        Text('$_bedrooms', style: GoogleFonts.poppins(fontSize: 16)),
                        IconButton(
                          onPressed: () => setState(() => _bedrooms++),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bathrooms', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _bathrooms > 1 ? () => setState(() => _bathrooms--) : null,
                          icon: const Icon(Icons.remove),
                        ),
                        Text('$_bathrooms', style: GoogleFonts.poppins(fontSize: 16)),
                        IconButton(
                          onPressed: () => setState(() => _bathrooms++),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Utilities
          Text('Utilities', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
          CheckboxListTile(
            title: const Text('Tiled'),
            value: _hasTiles,
            onChanged: (v) => setState(() => _hasTiles = v!),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.primaryPurple,
          ),
          CheckboxListTile(
            title: const Text('Water'),
            value: _hasWater,
            onChanged: (v) => setState(() => _hasWater = v!),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.primaryPurple,
          ),
          CheckboxListTile(
            title: const Text('Light'),
            value: _hasLight,
            onChanged: (v) => setState(() => _hasLight = v!),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.primaryPurple,
          ),
          const SizedBox(height: 16),

          // Description
          Text('Description', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Describe your accommodation...',
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
            title: const Text('Available for rent'),
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