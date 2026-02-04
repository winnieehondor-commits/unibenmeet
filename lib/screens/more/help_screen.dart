import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_constants.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  Future<void> _launchWhatsApp() async {
    const url = 'https://wa.me/2349077526598';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _launchEmail() async {
    const email = 'mailto:davidohiwerei8@gmail.com?subject=Campus Connect Support';
    if (await canLaunchUrl(Uri.parse(email))) {
      await launchUrl(Uri.parse(email));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help & Support', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Support Section
            _buildSupportCard(),
            const SizedBox(height: 30),
            
            // Contact Options
            Text(
              'Contact Us',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            
            _buildContactOption(
              Icons.message,
              'WhatsApp Support',
              '+234 907 752 6598',
              'Chat with us directly',
              Colors.green,
              _launchWhatsApp,
            ),
            const SizedBox(height: 15),
            
            _buildContactOption(
              Icons.email,
              'Email Support',
              'davidohiwerei8@gmail.com',
              'Send us an email',
              AppColors.primaryPurple,
              _launchEmail,
            ),
            const SizedBox(height: 30),
            
            // Navigation Guide
            _buildNavigationGuide(),
            const SizedBox(height: 30),
            
            // Common Issues
            _buildCommonIssues(),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryPurple, AppColors.primaryPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.support_agent,
            size: 50,
            color: AppColors.white,
          ),
          const SizedBox(height: 15),
          Text(
            'Need Help?',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'We\'re here to help you with any issues or questions about Campus Connect.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'Average Response Time: 2-4 hours',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.white.withOpacity(0.8),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption(
    IconData icon,
    String title,
    String subtitle,
    String description,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.grey,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationGuide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Navigation Guide',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        _buildGuideItem(
          'Home',
          'Browse accommodations, marketplace items, and voting events',
          Icons.home,
        ),
        _buildGuideItem(
          'Marketplace',
          'Buy and sell items with fellow students',
          Icons.shopping_cart,
        ),
        _buildGuideItem(
          'Voting',
          'Create or participate in campus voting events',
          Icons.how_to_vote,
        ),
        _buildGuideItem(
          'Profile',
          'Manage your account and view your activity',
          Icons.person,
        ),
        _buildGuideItem(
          'More',
          'Access settings, help, and additional features',
          Icons.menu,
        ),
      ],
    );
  }

  Widget _buildGuideItem(String title, String description, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.primaryPurple,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommonIssues() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Common Issues',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0,
          color: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.borderColor),
          ),
          child: const ExpansionTile(
            title: Text('Can\'t upload images?'),
            children: [
              ListTile(
                title: Text('• Check file size (max 5MB)\n• Use JPG or PNG format\n• Check internet connection'),
              ),
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0,
          color: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.borderColor),
          ),
          child: const ExpansionTile(
            title: Text('Login issues?'),
            children: [
              ListTile(
                title: Text('• Reset your password\n• Check email verification\n• Clear app cache'),
              ),
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0,
          color: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.borderColor),
          ),
          child: const ExpansionTile(
            title: Text('Not receiving notifications?'),
            children: [
              ListTile(
                title: Text('• Check app notification settings\n• Ensure app isn\'t force stopped\n• Update app to latest version'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}