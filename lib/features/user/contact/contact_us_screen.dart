import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
      child: SizedBox(
        width: width,
        height: 135,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Colored Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Icon(icon, color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.arrow_forward_ios,
                            color: color,
                            size: 10,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 1024;
    
    final horizontalPadding = isMobile ? 16.0 : (isTablet ? 24.0 : 32.0);
    final containerMaxWidth = isMobile ? double.infinity : (isTablet ? 600.0 : 700.0);
    final headerFontSize = isMobile ? 16.0 : (isTablet ? 18.0 : 22.0);
    final subtitleFontSize = isMobile ? 11.0 : (isTablet ? 12.0 : 13.0);
    final headerPadding = isMobile ? 16.0 : (isTablet ? 20.0 : 24.0);
    final iconSize = isMobile ? 20.0 : 24.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: horizontalPadding),
          child: Center(
            child: Column(
              children: [
                // Welcome Card
                Container(
                  constraints: BoxConstraints(maxWidth: containerMaxWidth),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Teal Header Section
                      Container(
                        padding: EdgeInsets.all(headerPadding),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.teal, Colors.teal.shade700],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Contact Us',
                                              style: TextStyle(
                                                fontSize: headerFontSize,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Get in touch - We\'re here to help',
                                              style: TextStyle(
                                                fontSize: subtitleFontSize,
                                                color: Colors.white.withOpacity(0.9),
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.25),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.contact_mail,
                                        color: Colors.white,
                                        size: iconSize,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.contact_mail,
                                      color: Colors.white,
                                      size: iconSize,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Contact Us',
                                          style: TextStyle(
                                            fontSize: headerFontSize,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Get in touch - We\'re here to help you',
                                          style: TextStyle(
                                            fontSize: subtitleFontSize,
                                            color: Colors.white.withOpacity(0.9),
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      // Contact Cards Section - New placement
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: headerPadding, vertical: headerPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Contact Cards - Responsive Grid
                            Wrap(
                              spacing: isMobile ? 0 : 12,
                              runSpacing: 12,
                              alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
                              children: [
                                _buildProContactCard(
                                  icon: Icons.email_outlined,
                                  title: 'Email',
                                  subtitle: 'itmoffice@daffodilvarsity.edu.bd',
                                  color: Colors.indigo,
                                  width: isMobile ? double.infinity : (isTablet ? 120.0 : 150.0),
                                  onTap: _launchEmail,
                                ),
                                _buildProContactCard(
                                  icon: Icons.phone_rounded,
                                  title: 'Phone',
                                  subtitle: '01847-140039',
                                  color: const Color.fromARGB(255, 147, 150, 0),
                                  width: isMobile ? double.infinity : (isTablet ? 120.0 : 150.0),
                                  onTap: _launchPhone,
                                ),
                                _buildProContactCard(
                                  icon: Icons.location_on_rounded,
                                  title: 'Address',
                                  subtitle: 'Daffodil Smart City (DSC), Birulia, Savar, Dhaka-1216',
                                  color: Colors.deepOrange,
                                  width: isMobile ? double.infinity : (isTablet ? 120.0 : 150.0),
                                  onTap: _launchMaps,
                                ),
                                _buildProContactCard(
                                  icon: Icons.public_rounded,
                                  title: 'Website',
                                  subtitle: 'itm.daffodilvarsity.edu.bd',
                                  color: Colors.blue,
                                  width: isMobile ? double.infinity : (isTablet ? 120.0 : 150.0),
                                  onTap: _launchWebsite,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Info Section
                      Padding(
                        padding: EdgeInsets.all(headerPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Connect with ITM through these channels',
                              style: TextStyle(
                                fontSize: subtitleFontSize,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 800.ms, delay: 300.ms).slideY(begin: 0.3, end: 0),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
