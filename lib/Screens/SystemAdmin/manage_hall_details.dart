import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ManageHallDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> hall;
  const ManageHallDetailsScreen({super.key, required this.hall});

  @override
  State<ManageHallDetailsScreen> createState() =>
      _ManageHallDetailsScreenState();
}

class _ManageHallDetailsScreenState extends State<ManageHallDetailsScreen> {
  int _currentImageIndex = 0;

  final List<String> _hallImages = [
    "https://images.unsplash.com/photo-1519167758481-83f550bb49b3?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80",
    "https://images.unsplash.com/photo-1519741497674-611481863552?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80",
    "https://images.unsplash.com/photo-1519167758481-83f550bb49b3?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80",
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isDesktop = screenWidth >= 1000;
        final isTablet = screenWidth >= 600 && screenWidth < 1000;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: isDesktop
                  ? _buildDesktopLayout(context)
                  : _buildMobileLayout(context, isTablet),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context, bool isTablet) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            _buildSliverAppBar(isDesktop: false),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderSection(isDesktop: false),
                    const SizedBox(height: 24),
                    _buildStatsRow(isDesktop: false),
                    const SizedBox(height: 32),
                    _SectionTitle(title: "Owner Details"),
                    _buildOwnerCard(isDesktop: false),
                    const SizedBox(height: 32),
                    _SectionTitle(title: "Description"),
                    _buildDescriptionCard(),
                    const SizedBox(height: 32),
                    _SectionTitle(title: "Payout Information"),
                    _buildPayoutCard(isDesktop: false),
                  ],
                ),
              ),
            ),
          ],
        ),

        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: _buildActionButtons(isDesktop: false),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: CustomScrollView(
            slivers: [
              _buildSliverAppBar(isDesktop: true),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderSection(isDesktop: true),
                      const SizedBox(height: 40),
                      _SectionTitle(title: "Description"),
                      _buildDescriptionCard(),
                      const SizedBox(height: 40),
                      _SectionTitle(title: "Payout Information"),
                      _buildPayoutCard(isDesktop: true),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          flex: 4,
          child: Container(
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(left: BorderSide(color: Colors.grey.shade200)),
            ),
            padding: const EdgeInsets.all(40),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _SectionTitle(title: "Hall Statistics"),
                  _buildStatsRow(isDesktop: true),
                  const SizedBox(height: 40),
                  _SectionTitle(title: "Owner Details"),
                  _buildOwnerCard(isDesktop: true),
                  const SizedBox(height: 40),
                  const Divider(),
                  const SizedBox(height: 20),
                  _buildActionButtons(isDesktop: true),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar({required bool isDesktop}) {
    return SliverAppBar(
      expandedHeight: isDesktop ? 400 : 300,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            CarouselSlider(
              options: CarouselOptions(
                height: double.infinity,
                viewportFraction: 1.0,
                autoPlay: true,
                onPageChanged: (index, reason) {
                  setState(() => _currentImageIndex = index);
                },
              ),
              items: _hallImages
                  .map((img) => Image.network(img, fit: BoxFit.cover))
                  .toList(),
            ),

            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                ),
              ),
            ),

            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${_currentImageIndex + 1} / ${_hallImages.length}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection({required bool isDesktop}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                widget.hall['name'] ?? "Grand Palace Hall",
                style: TextStyle(
                  fontSize: isDesktop ? 32 : 24,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: const Color(0xFF2D3436),
                ),
              ),
            ),
            if (!isDesktop) ...[const SizedBox(width: 10), _buildStatusBadge()],
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.location_on, color: Colors.grey[600], size: 20),
            const SizedBox(width: 8),
            Text(
              "Model Colony, Street 12A, Karachi",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (isDesktop) ...[const Spacer(), _buildStatusBadge()],
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    bool isApproved = widget.hall['status'] == "Approved";

    isApproved = true;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isApproved ? const Color(0xFFE6F7ED) : const Color(0xFFFFF0F1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isApproved ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: isApproved
                ? const Color(0xFF00B85E)
                : const Color(0xFFD92D20),
          ),
          const SizedBox(width: 6),
          Text(
            isApproved ? "Approved" : "Disabled",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isApproved
                  ? const Color(0xFF00B85E)
                  : const Color(0xFFD92D20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow({required bool isDesktop}) {
    if (isDesktop) {
      return Column(
        children: [
          _buildStatItem(Icons.people_outline, "Capacity", "300 - 800 Guests"),
          const SizedBox(height: 16),
          _buildStatItem(Icons.star_outline, "Rating", "4.8 (120 Reviews)"),
          const SizedBox(height: 16),
          _buildStatItem(
            Icons.calendar_today_outlined,
            "Bookings",
            "25 this month",
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _buildMobileStatCard(Icons.people, "800", "Capacity")),
        const SizedBox(width: 12),
        Expanded(child: _buildMobileStatCard(Icons.star, "4.8", "Rating")),
        const SizedBox(width: 12),
        Expanded(child: _buildMobileStatCard(Icons.event, "25", "Bookings")),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Icon(icon, color: Colors.orange, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStatCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.orange, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildOwnerCard({required bool isDesktop}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.orange.shade50,
            child: const Text(
              "RH",
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Rehman Hussain",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  "rehman@example.com",
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.phone),
            style: IconButton.styleFrom(
              backgroundColor: Colors.green.shade50,
              foregroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Text(
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
        style: TextStyle(height: 1.6, color: Colors.black87),
      ),
    );
  }

  Widget _buildPayoutCard({required bool isDesktop}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blueGrey.shade100),
            ),
            child: Icon(
              Icons.account_balance,
              color: Colors.blueGrey[700],
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Meezan Bank Ltd",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                "PK35 MEZN **** **** 1234",
                style: TextStyle(
                  fontSize:13 ,
                  fontFamily: 'monospace',
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons({required bool isDesktop}) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.block),
        label: const Text("Disable Hall"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2D3436),
        ),
      ),
    );
  }
}
