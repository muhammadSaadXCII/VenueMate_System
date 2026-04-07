import 'package:flutter/material.dart';
import 'package:venuemate_system/Models/hall_model.dart';
import 'package:venuemate_system/Services/hall_service.dart';
import 'package:venuemate_system/Utils/app_navigation.dart';
import 'review_registrations.dart';

const double _kWebBreak = 800;

class PendingRegistrationsScreen extends StatelessWidget {
  const PendingRegistrationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= _kWebBreak;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar:
          isWide
              ? null
              : AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                title: _buildTitleStream(),
                centerTitle: true,
              ),
      body: Column(
        children: [
          if (isWide)
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildTitleStream(),
              ),
            ),
          Expanded(
            child: StreamBuilder<List<HallModel>>(
              stream: HallService.streamPendingHalls(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF47C20)),
                  );
                }
                final halls = snap.data ?? [];

                if (halls.isEmpty) {
                  return _buildEmptyState();
                }

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child:
                        isWide
                            ? GridView.builder(
                              padding: const EdgeInsets.all(32),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: screenWidth > 1500 ? 3 : 2,
                                    crossAxisSpacing: 24,
                                    mainAxisSpacing: 24,
                                    // LOWERED RATIO = TALLER CARDS to prevent overflow
                                    childAspectRatio:
                                        screenWidth > 1500 ? 1.7 : 1.9,
                                  ),
                              itemCount: halls.length,
                              itemBuilder:
                                  (context, i) => _RegistrationCard(
                                    hall: halls[i],
                                    onTap:
                                        () => AppNavigation.push(
                                          context,
                                          ReviewRegistrationScreen(
                                            hall: halls[i],
                                          ),
                                        ),
                                  ),
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: halls.length,
                              itemBuilder:
                                  (context, i) => Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _RegistrationCard(
                                      hall: halls[i],
                                      onTap:
                                          () => AppNavigation.push(
                                            context,
                                            ReviewRegistrationScreen(
                                              hall: halls[i],
                                            ),
                                          ),
                                    ),
                                  ),
                            ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleStream() {
    return StreamBuilder<List<HallModel>>(
      stream: HallService.streamPendingHalls(),
      builder: (context, snap) {
        final count = snap.data?.length ?? 0;
        return RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 22, color: Colors.black),
            children: [
              TextSpan(
                text: '$count ',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF47C20),
                ),
              ),
              TextSpan(
                text: 'Pending Request${count == 1 ? '' : 's'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green.shade400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'All caught up!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'No pending hall registrations.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _RegistrationCard extends StatelessWidget {
  final HallModel hall;
  final VoidCallback onTap;
  const _RegistrationCard({required this.hall, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final image = hall.imageUrls.isNotEmpty ? hall.imageUrls.first : '';
    final isWide = MediaQuery.of(context).size.width >= _kWebBreak;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child:
                  image.isNotEmpty
                      ? Image.network(
                        image,
                        width:
                            isWide
                                ? 110
                                : 90, // Slightly smaller image to save space
                        height: isWide ? 110 : 90,
                        fit: BoxFit.cover,
                      )
                      : _placeholder(isWide ? 110 : 90),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment:
                    MainAxisAlignment
                        .center, // Centering helps distribute space better
                children: [
                  Text(
                    hall.hallName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _infoRow(Icons.location_on_outlined, hall.address),
                  const SizedBox(height: 4),
                  _infoRow(Icons.phone_outlined, hall.contactPhone),
                  const SizedBox(height: 4),
                  _infoRow(
                    Icons.calendar_today_outlined,
                    _formatDate(hall.createdAt),
                  ),
                  const SizedBox(
                    height: 8,
                  ), // Replaced spaceBetween logic with fixed gap
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF47C20).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Review',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF47C20),
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: Color(0xFFF47C20),
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

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.grey[500]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text.isEmpty ? 'Not provided' : text,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _placeholder(double size) => Container(
    width: size,
    height: size,
    color: Colors.grey[100],
    child: const Icon(Icons.business, color: Colors.grey, size: 36),
  );

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]}, ${d.year}';
  }
}
