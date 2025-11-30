import 'package:flutter/material.dart';
import 'package:venuemate_system/Widgets/gradient_button.dart';

class RejectPaymentScreen extends StatefulWidget {
  const RejectPaymentScreen({super.key});

  @override
  State<RejectPaymentScreen> createState() => _RejectPaymentScreenState();
}

class _RejectPaymentScreenState extends State<RejectPaymentScreen> {
  String? _selectedReason = "Incorrect Amount";

  final TextEditingController _reasonController = TextEditingController();

  final List<String> _reasons = [
    "Incorrect Amount",
    "Blurry/Unreadable Image",
    "Invalid Receipt",
    "Another reason",
  ];

  @override
  Widget build(BuildContext context) {
    bool isOtherSelected = _selectedReason == "Another reason";

    return Scaffold(
      backgroundColor: Colors.white,
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
          "Reject Payment",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GradientButton(
          text: "Submit Reason",
          onTap: () {
            if (isOtherSelected) {}
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Please select a reason for rejection",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            ..._reasons.map((reason) => _buildRadioOption(reason)),

            const SizedBox(height: 20),

            Container(
              height: 150,
              decoration: BoxDecoration(
                color: isOtherSelected ? Colors.white : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isOtherSelected
                      ? Colors.grey.shade400
                      : Colors.transparent,
                ),
              ),
              child: TextField(
                controller: _reasonController,

                enabled: isOtherSelected,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: "Tell us a reason",
                  hintStyle: TextStyle(
                    color: isOtherSelected ? Colors.grey : Colors.grey[400],
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption(String label) {
    bool isSelected = _selectedReason == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedReason = label;
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFEA845)
                      : Colors.grey.shade400,
                  width: 2,
                ),
                color: isSelected
                    ? const Color(0xFFFEA845)
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.circle, size: 10, color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
