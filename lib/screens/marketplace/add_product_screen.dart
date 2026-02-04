import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../constants/app_constants.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';
import '../../models/product_model.dart';
import '../../models/service_model.dart';

class AddProductScreen extends StatefulWidget {
  final bool isService;
  const AddProductScreen({Key? key, this.isService = false}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _locationController = TextEditingController();

  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  String _selectedCategory = 'Electronics';
  String _selectedCondition = 'Good';
  List<File> _selectedImages = [];
  List<File> _selectedVideos = [];
  bool _isLoading = false;

  final List<String> _productCategories = [
    'Electronics',
    'Books',
    'Clothing',
    'Furniture',
    'Sports',
    'Other'
  ];

  final List<String> _serviceCategories = [
    'Tutoring',
    'Assignment Help',
    'Typing',
    'Graphic Design',
    'Programming',
    'Other'
  ];

  final List<String> _conditions = ['New', 'Like New', 'Good', 'Fair'];

  @override
  void initState() {
    super.initState();
    _selectedCategory =
        widget.isService ? _serviceCategories[0] : _productCategories[0];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((img) => File(img.path)));
      });
    }
  }

  Future<void> _pickVideos() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _selectedVideos.add(File(video.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeVideo(int index) {
    setState(() {
      _selectedVideos.removeAt(index);
    });
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty && !widget.isService) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('User not logged in');

      final userData = await _authService.getUserData(user.uid);
      if (userData == null) throw Exception('User data not found');

      // Upload images
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _storageService.uploadImages(
          _selectedImages,
          widget.isService ? 'services' : 'products',
        );
      }

      // Upload videos
      List<String> videoUrls = [];
      if (_selectedVideos.isNotEmpty) {
        videoUrls = await _storageService.uploadVideos(
          _selectedVideos,
          widget.isService ? 'services' : 'products',
        );
      }

      final id = const Uuid().v4();

      if (widget.isService) {
        // Create service
        final service = ServiceModel(
          id: id,
          sellerId: user.uid,
          sellerName: userData.username,
          sellerImageUrl: userData.profileImageUrl ?? '',
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text),
          category: _selectedCategory,
          phoneNumber: _phoneController.text.trim(),
          whatsappNumber: _whatsappController.text.trim(),
          location: _locationController.text.trim(),
          imageUrls: imageUrls,
          createdAt: DateTime.now(),
        );

        await FirebaseFirestore.instance
            .collection(AppConstants.servicesCollection)
            .doc(id)
            .set(service.toMap());
      } else {
        // Create product
        final product = ProductModel(
          id: id,
          sellerId: user.uid,
          sellerName: userData.username,
          sellerImageUrl: userData.profileImageUrl ?? '',
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text),
          category: _selectedCategory,
          imageUrls: imageUrls,
          videoUrls: videoUrls,
          condition: _selectedCondition.toLowerCase().replaceAll(' ', '-'),
          phoneNumber: _phoneController.text.trim(),
          whatsappNumber: _whatsappController.text.trim(),
          location: _locationController.text.trim(),
          createdAt: DateTime.now(),
        );

        await FirebaseFirestore.instance
            .collection(AppConstants.productsCollection)
            .doc(id)
            .set(product.toMap());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${widget.isService ? "Service" : "Product"} added successfully!'),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: Text(
          widget.isService ? 'Add Service' : 'Add Product',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Images Section
            _buildMediaSection(),
            const SizedBox(height: 24),

            // Title
            _buildTextField(
              controller: _titleController,
              label: 'Title',
              hint: widget.isService
                  ? 'e.g., Math Tutoring'
                  : 'e.g., iPhone 12 Pro',
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Category
            _buildDropdown(
              label: 'Category',
              value: _selectedCategory,
              items: widget.isService ? _serviceCategories : _productCategories,
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            const SizedBox(height: 16),

            // Condition (Products only)
            if (!widget.isService) ...[
              _buildDropdown(
                label: 'Condition',
                value: _selectedCondition,
                items: _conditions,
                onChanged: (v) => setState(() => _selectedCondition = v!),
              ),
              const SizedBox(height: 16),
            ],

            // Price
            _buildTextField(
              controller: _priceController,
              label: 'Price (\$)',
              hint: '0.00',
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v!.isEmpty) return 'Required';
                if (double.tryParse(v) == null) return 'Invalid price';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Describe your ${widget.isService ? "service" : "product"}',
              maxLines: 4,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Location
            _buildTextField(
              controller: _locationController,
              label: 'Location',
              hint: 'e.g., Campus Area, Hostel Name',
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Phone Number
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              hint: '08012345678',
              keyboardType: TextInputType.phone,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // WhatsApp Number
            _buildTextField(
              controller: _whatsappController,
              label: 'WhatsApp Number',
              hint: '08012345678',
              keyboardType: TextInputType.phone,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: AppColors.white)
                    : Text(
                        'Submit',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Media',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Images
          if (_selectedImages.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: FileImage(_selectedImages[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.errorRed,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          const SizedBox(height: 12),

          // Add buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.image),
                  label: Text(
                    'Add Images',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryPurple,
                    side: const BorderSide(color: AppColors.primaryPurple),
                  ),
                ),
              ),
              if (!widget.isService) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickVideos,
                    icon: const Icon(Icons.videocam),
                    label: Text(
                      'Add Video',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryPurple,
                      side: const BorderSide(color: AppColors.primaryPurple),
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Videos
          if (_selectedVideos.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...List.generate(_selectedVideos.length, (index) {
              return ListTile(
                leading:
                    const Icon(Icons.videocam, color: AppColors.primaryPurple),
                title: Text('Video ${index + 1}',
                    style: GoogleFonts.poppins(fontSize: 14)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.errorRed),
                  onPressed: () => _removeVideo(index),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: AppColors.grey),
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.borderColor),
            ),
          ),
        ),
      ],
    );
  }
}
