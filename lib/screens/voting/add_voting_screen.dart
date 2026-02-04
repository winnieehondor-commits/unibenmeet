import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../constants/app_constants.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';
import '../../models/voting_model.dart';

class AddVotingScreen extends StatefulWidget {
  const AddVotingScreen({Key? key}) : super(key: key);

  @override
  State<AddVotingScreen> createState() => _AddVotingScreenState();
}

class _AddVotingScreenState extends State<AddVotingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _awardController = TextEditingController();
  final _positionController = TextEditingController();
  
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();
  
  DateTime? _endDate;
  List<ContestantInput> _contestants = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _awardController.dispose();
    _positionController.dispose();
    for (var contestant in _contestants) {
      contestant.nameController.dispose();
      contestant.tagController.dispose();
    }
    super.dispose();
  }

  void _addContestant() {
    setState(() {
      _contestants.add(ContestantInput());
    });
  }

  void _removeContestant(int index) {
    setState(() {
      _contestants[index].nameController.dispose();
      _contestants[index].tagController.dispose();
      _contestants.removeAt(index);
    });
  }

  Future<void> _pickImageForContestant(int index) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _contestants[index].image = File(image.path);
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryPurple,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _submitVoting() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_contestants.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least 2 contestants')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('User not logged in');

      final userData = await _authService.getUserData(user.uid);
      if (userData == null) throw Exception('User data not found');

      // Upload contestant images
      List<Contestant> contestants = [];
      for (var contestantInput in _contestants) {
        String? imageUrl;
        if (contestantInput.image != null) {
          final urls = await _storageService.uploadImages(
            [contestantInput.image!],
            'voting_contestants',
          );
          imageUrl = urls.first;
        }

        contestants.add(Contestant(
          id: const Uuid().v4(),
          name: contestantInput.nameController.text.trim(),
          tag: contestantInput.tagController.text.trim(),
          imageUrl: imageUrl,
        ));
      }

      final id = const Uuid().v4();
      final shareableLink = 'campusconnect://voting/$id';

      // Create voting
      final voting = VotingModel(
        id: id,
        creatorId: user.uid,
        creatorName: userData.username,
        title: _titleController.text.trim(),
        award: _awardController.text.trim(),
        position: _positionController.text.trim(),
        contestants: contestants,
        createdAt: DateTime.now(),
        endDate: _endDate,
        shareableLink: shareableLink,
      );

      await FirebaseFirestore.instance
          .collection(AppConstants.votingCollection)
          .doc(id)
          .set(voting.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voting created successfully!'),
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
          'Create Voting',
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
            // Voting Info Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Voting Information',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Title
                  _buildTextField(
                    controller: _titleController,
                    label: 'Title',
                    hint: 'e.g., Best Dressed Student 2024',
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Award
                  _buildTextField(
                    controller: _awardController,
                    label: 'Award/Category',
                    hint: 'e.g., Best Dressed',
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Position
                  _buildTextField(
                    controller: _positionController,
                    label: 'Position',
                    hint: 'e.g., Student of the Year',
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // End Date
                  Text(
                    'End Date (Optional)',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectEndDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: AppColors.grey),
                          const SizedBox(width: 12),
                          Text(
                            _endDate != null
                                ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                : 'Select end date',
                            style: GoogleFonts.poppins(
                              color: _endDate != null ? AppColors.black : AppColors.grey,
                            ),
                          ),
                          const Spacer(),
                          if (_endDate != null)
                            GestureDetector(
                              onTap: () => setState(() => _endDate = null),
                              child: const Icon(Icons.close, color: AppColors.grey, size: 20),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Contestants Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Contestants',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addContestant,
                        icon: const Icon(Icons.add, color: AppColors.primaryPurple),
                        label: Text(
                          'Add',
                          style: GoogleFonts.poppins(color: AppColors.primaryPurple),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  if (_contestants.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.people_outline, size: 48, color: AppColors.grey.withOpacity(0.5)),
                            const SizedBox(height: 8),
                            Text(
                              'No contestants added yet',
                              style: GoogleFonts.poppins(color: AppColors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  ...List.generate(_contestants.length, (index) {
                    return _buildContestantCard(index);
                  }),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitVoting,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: AppColors.white)
                    : Text(
                        'Create Voting',
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

  Widget _buildContestantCard(int index) {
    final contestant = _contestants[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGrey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _pickImageForContestant(index),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    image: contestant.image != null
                        ? DecorationImage(
                            image: FileImage(contestant.image!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: contestant.image == null
                      ? const Icon(Icons.add_photo_alternate, color: AppColors.primaryPurple)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    TextFormField(
                      controller: contestant.nameController,
                      decoration: InputDecoration(
                        hintText: 'Contestant name',
                        hintStyle: GoogleFonts.poppins(fontSize: 14, color: AppColors.grey),
                        filled: true,
                        fillColor: AppColors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: contestant.tagController,
                      decoration: InputDecoration(
                        hintText: 'Tag/Department',
                        hintStyle: GoogleFonts.poppins(fontSize: 14, color: AppColors.grey),
                        filled: true,
                        fillColor: AppColors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.errorRed),
                onPressed: () => _removeContestant(index),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
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
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: AppColors.grey),
            filled: true,
            fillColor: AppColors.lightGrey,
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

class ContestantInput {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController tagController = TextEditingController();
  File? image;
}