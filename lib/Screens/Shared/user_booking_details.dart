import 'package:flutter/material.dart';

class UserBookingDetailsScreen extends StatelessWidget {
  const UserBookingDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    
    const Color primaryOrange = Color(0xFFF58529);
    const Color textDark = Color(0xFF1F2937);
    

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      Container(
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: const DecorationImage(
                            image: NetworkImage(
                              "https://images.unsplash.com/photo-1519167758481-83f550bb49b3?ixlib=rb-1.2.1&auto=format&fit=crop&w=100&q=60"
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Al Rehman Banquet Hall",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: primaryOrange,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    "Model Colony, Street 12A, Karachi",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
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
                ],
              ),
            ),

            const SizedBox(height: 20),

            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.event,
                    label: "Event Name",
                    value: "Birthday Celebration",
                  ),
                  const Divider(height: 24),
                  _DetailRow(
                    icon: Icons.calendar_today,
                    label: "Date",
                    value: "1 November, 2025",
                  ),
                  const Divider(height: 24),
                  _DetailRow(
                    icon: Icons.access_time,
                    label: "Time Slot",
                    value: "Evening",
                  ),
                  const Divider(height: 24),
                  _DetailRow(
                    icon: Icons.groups,
                    label: "Guests",
                    value: "200 - 250 People",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            
            const Text(
              "Booking Summary",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PriceRow(
                    label: "Hall Rent",
                    price: "Rs. 15,000",
                    isBold: true,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Add-ons",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _PriceRow(label: "Chicken Cheese Paratha", price: "Rs. 400"),
                  _PriceRow(label: "White Chicken Karahi", price: "Rs. 60"),
                  _PriceRow(label: "Premium Catering", price: "Rs. 5000"),
                  _PriceRow(label: "Event Photography", price: "Rs. 5000"),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(
                      thickness: 1,
                      color: Colors.black12,
                      indent: 10,
                      endIndent: 10,
                    ), 
                  ),

                  
                  _PriceRow(
                    label: "Grand Total",
                    price: "Rs. 28,000",
                    isTotal: true,
                  ),
                  const SizedBox(height: 8),
                  _PriceRow(
                    label: "Paid (25% Advance)",
                    price: "- Rs. 7,000",
                    color: Colors.green,
                  ),

                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0), 
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryOrange.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          "Remaining Payment",
                          style: TextStyle(
                            color: Color(0xFFE65100),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Rs. 21,000",
                          style: TextStyle(
                            color: Color(0xFFE65100),
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: Colors.grey[600]),
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
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
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
      padding: const EdgeInsets.only(bottom: 8.0),
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
