import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../../constants/app_constants.dart';
import '../../models/voting_model.dart';
import '../../services/auth_service.dart';

class VotingDetailScreen extends StatefulWidget {
  final VotingModel voting;
  const VotingDetailScreen({Key? key, required this.voting}) : super(key: key);

  @override
  State<VotingDetailScreen> createState() => _VotingDetailScreenState();
}

class _VotingDetailScreenState extends State<VotingDetailScreen> {
  final AuthService _authService = AuthService();
  String? _userVotedFor;
  bool _isVoting = false;

  @override
  void initState() {
    super.initState();
    _checkUserVote();
  }

  Future<void> _checkUserVote() async {
    final user = _authService.currentUser;
    if (user != null) {
      for (var contestant in widget.voting.contestants) {
        if (contestant.voters.contains(user.uid)) {
          setState(() {
            _userVotedFor = contestant.id;
          });
          break;
        }
      }
    }
  }

  Future<void> _vote(String contestantId) async {
    if (!widget.voting.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This voting has ended')),
      );
      return;
    }

    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to vote')),
      );
      return;
    }

    if (_userVotedFor != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have already voted')),
      );
      return;
    }

    setState(() => _isVoting = true);

    try {
      final votingRef = FirebaseFirestore.instance
          .collection(AppConstants.votingCollection)
          .doc(widget.voting.id);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(votingRef);
        if (!snapshot.exists) {
          throw Exception('Voting not found');
        }

        final votingData = VotingModel.fromMap(snapshot.data()!);
        final updatedContestants = votingData.contestants.map((contestant) {
          if (contestant.id == contestantId) {
            return Contestant(
              id: contestant.id,
              name: contestant.name,
              tag: contestant.tag,
              imageUrl: contestant.imageUrl,
              votes: contestant.votes + 1,
              voters: [...contestant.voters, user.uid],
            );
          }
          return contestant;
        }).toList();

        final updatedVoting = VotingModel(
          id: votingData.id,
          creatorId: votingData.creatorId,
          creatorName: votingData.creatorName,
          title: votingData.title,
          award: votingData.award,
          position: votingData.position,
          contestants: updatedContestants,
          createdAt: votingData.createdAt,
          endDate: votingData.endDate,
          isActive: votingData.isActive,
          shareableLink: votingData.shareableLink,
        );

        transaction.update(votingRef, updatedVoting.toMap());
      });

      setState(() {
        _userVotedFor = contestantId;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vote submitted successfully!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
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
        setState(() => _isVoting = false);
      }
    }
  }

  void _shareVoting() {
    Share.share(
      'Vote for ${widget.voting.award} - ${widget.voting.title}\n\n'
      'Join the voting now!\n'
      '${widget.voting.shareableLink}',
      subject: widget.voting.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalVotes = widget.voting.contestants.fold<int>(0, (sum, c) => sum + c.votes);
    final daysLeft = widget.voting.endDate != null
        ? widget.voting.endDate!.difference(DateTime.now()).inDays
        : null;

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: Text('Voting Details', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareVoting,
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.votingCollection)
            .doc(widget.voting.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryPurple),
            );
          }

          final voting = VotingModel.fromMap(snapshot.data!.data() as Map<String, dynamic>);
          final updatedTotalVotes = voting.contestants.fold<int>(0, (sum, c) => sum + c.votes);

          return ListView(
            children: [
              // Header Section
              Container(
                color: AppColors.white,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      voting.title,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        voting.award,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.primaryPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Position: ${voting.position}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.people, size: 18, color: AppColors.grey),
                        const SizedBox(width: 8),
                        Text(
                          '${voting.contestants.length} Contestants',
                          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.grey),
                        ),
                        const SizedBox(width: 24),
                        Icon(Icons.how_to_vote, size: 18, color: AppColors.grey),
                        const SizedBox(width: 8),
                        Text(
                          '$updatedTotalVotes Total Votes',
                          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.grey),
                        ),
                      ],
                    ),
                    if (daysLeft != null && voting.isActive) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 18, color: AppColors.grey),
                          const SizedBox(width: 8),
                          Text(
                            daysLeft > 0 ? 'Ends in $daysLeft days' : 'Ending today',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: daysLeft > 3 ? AppColors.successGreen : AppColors.errorRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (!voting.isActive) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Voting Ended',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Created by ${voting.creatorName}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Contestants Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Contestants',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              ...voting.contestants.map((contestant) {
                final percentage = updatedTotalVotes > 0
                    ? (contestant.votes / updatedTotalVotes * 100).toStringAsFixed(1)
                    : '0.0';
                final hasVoted = _userVotedFor == contestant.id;

                return _buildContestantCard(
                  contestant: contestant,
                  percentage: percentage,
                  hasVoted: hasVoted,
                  totalVotes: updatedTotalVotes,
                );
              }).toList(),
              
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContestantCard({
    required Contestant contestant,
    required String percentage,
    required bool hasVoted,
    required int totalVotes,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: hasVoted
            ? Border.all(color: AppColors.primaryPurple, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isVoting || hasVoted || !widget.voting.isActive
              ? null
              : () => _vote(contestant.id),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Contestant Image
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: contestant.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: contestant.imageUrl!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 32,
                              color: AppColors.primaryPurple,
                            ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Contestant Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contestant.name,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            contestant.tag,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Vote Count
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${contestant.votes}',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                        Text(
                          'votes',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Vote Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: totalVotes > 0 ? contestant.votes / totalVotes : 0,
                    backgroundColor: AppColors.lightGrey,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      hasVoted ? AppColors.primaryPurple : AppColors.primaryPurple.withOpacity(0.5),
                    ),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Percentage
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (hasVoted)
                      Row(
                        children: [
                          Icon(Icons.check_circle, size: 16, color: AppColors.primaryPurple),
                          const SizedBox(width: 4),
                          Text(
                            'Your vote',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.primaryPurple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    else
                      const SizedBox(),
                    Text(
                      '$percentage%',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}