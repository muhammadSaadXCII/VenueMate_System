import 'package:flutter/material.dart';

class UserBookingDetailsScreen extends StatelessWidget {
  const UserBookingDetailsScreen({super.key});

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
          "Booking Details",
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
            return _buildDesktopLayout(context);
          } else {
            return _buildMobileLayout(context);
          }
        },
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHallHeader(),
                      const SizedBox(height: 24),
                      _buildEventDetailsCard(),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 40),

              Expanded(
                flex: 4,
                child: SingleChildScrollView(child: _buildPaymentSummaryCard()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHallHeader(),
          const SizedBox(height: 20),
          _buildEventDetailsCard(),
          const SizedBox(height: 24),
          const Text(
            "Booking Summary",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildPaymentSummaryCard(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHallHeader() {
    const Color primaryOrange = Color(0xFFF47C20);
    const Color textDark = Color(0xFF1F2937);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: const DecorationImage(
                image: NetworkImage(
                  "https://images.unsplash.com/photo-1519167758481-83f550bb49b3?ixlib=rb-1.2.1&auto=format&fit=crop&w=100&q=60",
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Al Rehman Banquet Hall",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: primaryOrange,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "Model Colony, Street 12A, Karachi",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: const Column(
        children: [
          _DetailRow(
            icon: Icons.event,
            label: "Event Name",
            value: "Birthday Celebration",
          ),
          Divider(height: 32),
          _DetailRow(
            icon: Icons.calendar_today,
            label: "Date",
            value: "1 November, 2025",
          ),
          Divider(height: 32),
          _DetailRow(
            icon: Icons.access_time,
            label: "Time Slot",
            value: "Evening",
          ),
          Divider(height: 32),
          _DetailRow(
            icon: Icons.groups,
            label: "Guests",
            value: "200 - 250 People",
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard() {
    const Color primaryOrange = Color(0xFFF47C20);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Payment Details",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const _PriceRow(
            label: "Hall Rent",
            price: "Rs. 15,000",
            isBold: true,
          ),
          const SizedBox(height: 16),
          const Text(
            "Add-ons",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          const _PriceRow(label: "Chicken Cheese Paratha", price: "Rs. 400"),
          const _PriceRow(label: "White Chicken Karahi", price: "Rs. 60"),
          const _PriceRow(label: "Premium Catering", price: "Rs. 5000"),
          const _PriceRow(label: "Event Photography", price: "Rs. 5000"),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(thickness: 1, color: Colors.black12),
          ),

          const _PriceRow(
            label: "Grand Total",
            price: "Rs. 28,000",
            isTotal: true,
          ),
          const SizedBox(height: 8),
          const _PriceRow(
            label: "Paid (25% Advance)",
            price: "- Rs. 7,000",
            color: Colors.green,
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryOrange.withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Remaining Payment",
                  style: TextStyle(
                    color: Color(0xFFF47C20),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Rs. 21,000",
                  style: TextStyle(
                    color: Color(0xFFF47C20),
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: Colors.grey[700]),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String price;
  final bool isBold;
  final bool isTotal;
  final Color? color;

  const _PriceRow({
    required this.label,
    required this.price,
    this.isBold = false,
    this.isTotal = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.black : Colors.grey[700],
              fontSize: isTotal ? 16 : 14,
              fontWeight: isBold || isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            price,
            style: TextStyle(
              color: color ?? (isTotal ? Colors.black : Colors.black87),
              fontSize: isTotal ? 18 : 14,
              fontWeight: isBold || isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
