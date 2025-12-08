import 'package:flutter/material.dart';

class HallFeedbacksScreen extends StatefulWidget {
  const HallFeedbacksScreen({super.key});

  @override
  State<HallFeedbacksScreen> createState() => _HallFeedbacksScreenState();
}

class _HallFeedbacksScreenState extends State<HallFeedbacksScreen> {
  String _selectedFilter = "All";

  final List<String> _filters = [
    "All",
    "5 Stars",
    "4 Stars",
    "3 Stars",
    "2 Stars",
    "1 Star",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Feedbacks",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 700) {
            return _buildDesktopLayout();
          } else {
            return _buildMobileLayout();
          }
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 350,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRatingSummaryCard(),
                    const SizedBox(height: 32),
                    const Text(
                      "Filter Reviews",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _filters.map((filter) {
                        return _FilterChip(
                          label: filter,
                          isSelected: _selectedFilter == filter,
                          onTap: () => setState(() => _selectedFilter = filter),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 40),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Recent Reviews",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView(
                        children: const [
                          _ReviewCard(
                            name: "Ali Khan",
                            date: "2 days ago",
                            rating: 5,
                            comment:
                                "Amazing venue! The staff was very cooperative and the food was delicious.",
                          ),
                          SizedBox(height: 16),
                          _ReviewCard(
                            name: "Sara Ahmed",
                            date: "1 week ago",
                            rating: 4,
                            comment:
                                "Good hall, but the parking space was a bit tight for our guests.",
                          ),
                          SizedBox(height: 16),
                          _ReviewCard(
                            name: "Muzamil",
                            date: "2 weeks ago",
                            rating: 5,
                            comment:
                                "Best experience ever! The lighting and decor were spot on.",
                          ),
                          SizedBox(height: 16),
                          _ReviewCard(
                            name: "Hamza",
                            date: "3 weeks ago",
                            rating: 3,
                            comment:
                                "The AC was not working properly in the beginning.",
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRatingSummaryCard(),
          const SizedBox(height: 25),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((filter) {
                return _FilterChip(
                  label: filter,
                  isSelected: _selectedFilter == filter,
                  onTap: () => setState(() => _selectedFilter = filter),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            "Recent Reviews",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),

          const _ReviewCard(
            name: "Ali Khan",
            date: "2 days ago",
            rating: 5,
            comment:
                "Amazing venue! The staff was very cooperative and the food was delicious.",
          ),
          const SizedBox(height: 15),
          const _ReviewCard(
            name: "Sara Ahmed",
            date: "1 week ago",
            rating: 4,
            comment:
                "Good hall, but the parking space was a bit tight for our guests.",
          ),
          const SizedBox(height: 15),
          const _ReviewCard(
            name: "Muzamil",
            date: "2 weeks ago",
            rating: 5,
            comment:
                "Best experience ever! The lighting and decor were spot on.",
          ),
          const SizedBox(height: 15),
          const _ReviewCard(
            name: "Hamza",
            date: "3 weeks ago",
            rating: 3,
            comment: "The AC was not working properly in the beginning.",
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF47C20), Color(0xFFFFD166)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFF47C20).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "4.8",
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              Text(
                "OUT OF 5",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(5, (index) {
                    return const Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 24,
                    );
                  }),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Based on 124 reviews",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF47C20) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey.shade300),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(0xFFF47C20).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String name;
  final String date;
  final int rating;
  final String comment;

  const _ReviewCard({
    required this.name,
    required this.date,
    required this.rating,
    required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade200,
                child: Icon(Icons.person, color: Colors.grey.shade500),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      date,
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      rating.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
