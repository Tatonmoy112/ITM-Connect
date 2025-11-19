import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildProContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required double width,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border(
            right: BorderSide(
              color: color,
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(12),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: color,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============ URL LAUNCHER FUNCTIONS ============
  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'itmoffice@daffodilvarsity.edu.bd',
      queryParameters: {
        'subject': 'Inquiry from ITM Connect',
        'body': 'Hello, I would like to inquire about...',
      },
    );
    
    try {
      await launchUrl(emailUri);
    } catch (e) {
      _showSnackbar('Error launching email: $e');
    }
  }

  Future<void> _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '01847140039');
    
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showSnackbar('Phone call not available');
      }
    } catch (e) {
      _showSnackbar('Error launching phone: $e');
    }
  }

  Future<void> _launchWebsite() async {
    final Uri websiteUri = Uri.parse('https://itm.daffodilvarsity.edu.bd');
    
    try {
      await launchUrl(
        websiteUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      _showSnackbar('Error launching website: $e');
    }
  }

  Future<void> _launchMaps() async {
    final Uri mapsUri = Uri.parse(
      'geo:23.8103,90.3436?q=Daffodil+Smart+City,+Birulia,+Savar,+Dhaka',
    );
    
    try {
      if (await canLaunchUrl(mapsUri)) {
        await launchUrl(mapsUri);
      } else {
        _showSnackbar('Maps app not available');
      }
    } catch (e) {
      _showSnackbar('Error launching maps: $e');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.teal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    final cardWidth = isWide
        ? MediaQuery.of(context).size.width / 2 - 48
        : MediaQuery.of(context).size.width - 40;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Professional Contact Cards
              Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  _buildProContactCard(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    subtitle: 'itmoffice@daffodilvarsity.edu.bd',
                    color: Colors.indigo,
                    width: cardWidth,
                    onTap: _launchEmail,
                  ),
                  _buildProContactCard(
                    icon: Icons.phone_rounded,
                    title: 'Phone',
                    subtitle: '01847-140039',
                    color: Colors.teal,
                    width: cardWidth,
                    onTap: _launchPhone,
                  ),
                  _buildProContactCard(
                    icon: Icons.location_on_rounded,
                    title: 'Address',
                    subtitle: 'Daffodil Smart City (DSC), Birulia, Savar, Dhaka-1216',
                    color: Colors.deepOrange,
                    width: cardWidth,
                    onTap: _launchMaps,
                  ),
                  _buildProContactCard(
                    icon: Icons.public_rounded,
                    title: 'Website',
                    subtitle: 'itm.daffodilvarsity.edu.bd',
                    color: Colors.blue,
                    width: cardWidth,
                    onTap: _launchWebsite,
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
