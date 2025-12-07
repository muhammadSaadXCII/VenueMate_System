import 'package:flutter/material.dart';
import 'package:venuemate_system/Utils/app_navigation.dart';
import 'package:venuemate_system/Screens/SystemAdmin/review_registrations.dart';

class PendingRegistrationsScreen extends StatelessWidget {
  const PendingRegistrationsScreen({super.key});

  final int pendingCount = 4;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1100;
    final isTablet = screenWidth >= 600 && screenWidth < 1100;

    final horizontalPadding = isDesktop
        ? screenWidth * 0.15
        : isTablet
            ? 40.0
            : 20.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: !isDesktop,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: isDesktop ? 24 : 20,
              color: Colors.black,
            ),
            children: [
              TextSpan(
                text: "$pendingCount ",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF58529),
                ),
              ),
              const TextSpan(
                text: "Pending Requests",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 24,
            ),
            child: GridView.builder(
              itemCount: pendingCount,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 2 : 1,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                mainAxisExtent: 170,
              ),
              itemBuilder: (context, index) {
                return RegistrationCard(
                  hallName: index.isEven
                      ? "Al Rehman Banquet Hall"
                      : "Akbar Marquee & Marriage Hall",
                  submittedBy: "Rehman Hussain",
                  date: "31 Oct, 2025",
                  // Yahan apna asset path dein
                  imagePath: "assets/images/cardimage 2.png", 
                  isDesktop: isDesktop,
                  onTap: () {
                    AppNavigation.push(context, const ReviewRegistrationScreen());
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class RegistrationCard extends StatelessWidget {
  final String hallName;
  final String submittedBy;
  final String date;
  final String imagePath; // Renamed from imageUrl
  final bool isDesktop;
  final VoidCallback onTap;

  const RegistrationCard({
    super.key,
    required this.hallName,
    required this.submittedBy,
    required this.date,
    required this.imagePath, // Renamed
    required this.isDesktop,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              // CHANGED: Image.network -> Image.asset
              child: Image.asset(
                imagePath,
                width: 120,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 120,
                    height: double.infinity,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, color: Colors.grey),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hallName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          submittedBy,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        date,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),

                  const Spacer(),

                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF58529).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFF58529).withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Review",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF58529),
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: Color(0xFFF58529),
                          ),
                        ],
                      ),
                    ),
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