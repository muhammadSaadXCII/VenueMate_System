import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ViewReceiptScreen(),
  ));
}

class ViewReceiptScreen extends StatelessWidget {
  const ViewReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light grey background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "View Receipt",
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // --- The Main Receipt Card ---
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          // color: Colors.white,
                          color: Color(0xFFFFFDF6),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // 1. Receipt Header (Light Orange Background)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Color.fromARGB(255, 202, 202, 202),// Light amber/cream
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20)),
                              ),
                              child: Column(
  crossAxisAlignment: CrossAxisAlignment.start, // Important
  children: [
    // -------- VenueMate Icon positioned at TOP-LEFT --------
    Padding(
      padding: const EdgeInsets.only(left: 2, top: 2),
      child: Image.asset(
        'assets/images/venuemate.png',
        height: 60,
        width: 60,
      ),
    ),

    

    // -------- Row with Success Icon (center-right) --------
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 1), // Keeps success icon in correct position

        // Success Icon
        Container(
          padding: const EdgeInsets.only(right: 2 ,top: 0),
          child: Image.asset(
            'assets/images/Sucess.png',
            height: 90,
            width: 90,
          ),
        ),

        const SizedBox(width: 20), // Spacer for balance
      ],
    ),

    // const SizedBox(height: 2),

    const Center(
      child: Text(
        "Booking Successful",
        style: TextStyle(
          color: Color(0xFFFF8F00),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ],
),

                            ),

                            // 2. Receipt Details
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Invoice ID & Status
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text("Invoice ID",
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12)),
                                          SizedBox(height: 4),
                                          Text("#VM-6865",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16)),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                              color: Colors.green.withOpacity(0.2)),
                                        ),
                                        child: const Text(
                                          "PAID (Advance)",
                                          style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Al Rehman Banquet Hall",
                                    style: TextStyle(
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w500),
                                  ),

                                  const SizedBox(height: 24),

                                  // Billed To Section
                                  const Text("Billed To",
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 13)),
                                  const SizedBox(height: 12),
                                  _buildInfoRow("Name", "Suleman Raheem",
                                      "Phone", "0315#######"),
                                  const SizedBox(height: 12),
                                  _buildInfoRow(
                                      "CNIC", "37901-6773641-1", null, null),
                                  const SizedBox(height: 12),
                                  _buildInfoRow("Event", "Birthday Celebration",
                                      "Guests", "200-250"),
                                  const SizedBox(height: 12),
                                  _buildInfoRow("Date",
                                      "1 November, 2025 (Evening)", null, null),

                                  const SizedBox(height: 24),
                                 const DashedDivider(height: 3,color: Color.fromARGB(255, 54, 54, 54), ),
                                  const SizedBox(height: 24),

                                  // Items Summary
                                  const Text("Items Summary",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15)),
                                  const SizedBox(height: 16),
                                  _buildSummaryRow("Hall Rent", "Rs. 15,000"),
                                  _buildSummaryRow("Menu (2 Items)", "Rs. 3,000"),
                                  _buildSummaryRow(
                                      "Services (2 Services)", "Rs. 10,000"),

                                  const SizedBox(height: 24),
                                  const DashedDivider(height: 3,color: Color.fromARGB(255, 54, 54, 54), ),
                                  const SizedBox(height: 24),

                                  // Totals
                                  _buildSummaryRow("Grand Total", "Rs. 28,000",
                                      isBold: true),
                                  _buildSummaryRow(
                                      "25% Advance Payment", "Rs. 7,000",
                                      isHighlight: true),

                                  const SizedBox(height: 24),
                                  const DashedDivider(height: 3,color: Color.fromARGB(255, 54, 54, 54), ),
                                  const SizedBox(height: 24),

                                  // Remaining
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text("Remaining Payment",
                                          style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600)),
                                      Text("Rs. 21,000",
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red[700])),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100), // Space for bottom button
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Floating Bottom Button
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            // gradient: const LinearGradient(
            //   colors: [Color(0xFFFFE082), Color(0xFFFFD54F)],
            // ),
            color: Color(0xFFF47C20),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () {
              // Handle download logic
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            icon: const Icon(Icons.download_rounded, color: Colors.white,size: 25,),
            label: const Text(
              "Download Receipt",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget for customer info rows
  Widget _buildInfoRow(
      String label1, String value1, String? label2, String? value2) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value1,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
        if (label2 != null && value2 != null)
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value2,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ),
      ],
    );
  }

  // Helper widget for summary money rows
  Widget _buildSummaryRow(String title, String amount,
      {bool isBold = false, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isHighlight ? Colors.green[700] : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Custom Widget for the Dashed Line ---
class DashedDivider extends StatelessWidget {
  final double height;
  final Color color;

  const DashedDivider({super.key, this.height = 1, this.color = Colors.grey});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        final dashHeight = height;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color.withOpacity(0.3)),
              ),
            );
          }),
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
        );
      },
    );
  }
}