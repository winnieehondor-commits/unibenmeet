import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/app_constants.dart';
import '../../models/voting_model.dart';
import 'add_voting_screen.dart';
import 'voting_detail_screen.dart';

class VotingScreen extends StatefulWidget {
  const VotingScreen({Key? key}) : super(key: key);

  @override
  State<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: Text('Voting', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.white,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Ended'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search voting...',
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
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVotingList(isActive: true),
                _buildVotingList(isActive: false),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddVotingScreen()),
          );
        },
        backgroundColor: AppColors.primaryPurple,
        icon: const Icon(Icons.add, color: AppColors.white),
        label: Text('Create Voting', style: GoogleFonts.poppins(color: AppColors.white)),
      ),
    );
  }

  Widget _buildVotingList({required bool isActive}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.votingCollection)
          .where('isActive', isEqualTo: isActive)
          .orderBy('createdAt', descending: true)
          .snapshots(),
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
                Icon(Icons.how_to_vote, size: 80, color: AppColors.grey.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  isActive ? 'No active voting' : 'No ended voting',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
              ],
            ),
          );
        }

        var votings = snapshot.data!.docs
            .map((doc) => VotingModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

        // Apply search filter
        if (_searchController.text.isNotEmpty) {
          votings = votings.where((voting) {
            return voting.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                voting.award.toLowerCase().contains(_searchController.text.toLowerCase());
          }).toList();
        }

        if (votings.isEmpty) {
          return Center(
            child: Text('No voting found', style: GoogleFonts.poppins()),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: votings.length,
          itemBuilder: (context, index) {
            return _buildVotingCard(votings[index]);
          },
        );
      },
    );
  }

  Widget _buildVotingCard(VotingModel voting) {
    final totalVotes = voting.contestants.fold<int>(0, (sum, c) => sum + c.votes);
    final daysLeft = voting.endDate != null
        ? voting.endDate!.difference(DateTime.now()).inDays
        : null;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VotingDetailScreen(voting: voting),
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              voting.title,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              voting.award,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppColors.primaryPurple,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (voting.isActive && daysLeft != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: daysLeft > 3 
                                ? AppColors.successGreen.withOpacity(0.1)
                                : AppColors.errorRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            daysLeft > 0 ? '$daysLeft days left' : 'Ending soon',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: daysLeft > 3 ? AppColors.successGreen : AppColors.errorRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (!voting.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Ended',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Position: ${voting.position}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: AppColors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${voting.contestants.length} contestants',
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.how_to_vote, size: 16, color: AppColors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '$totalVotes total votes',
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'By ${voting.creatorName}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            if (voting.contestants.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightGrey.withOpacity(0.5),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Leading: ${voting.contestants.reduce((a, b) => a.votes > b.votes ? a : b).name}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryPurple,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: AppColors.primaryPurple,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}