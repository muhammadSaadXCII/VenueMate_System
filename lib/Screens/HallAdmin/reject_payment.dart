import 'package:flutter/material.dart';

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
        title: Text(
          "Reject Payment",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      bottomNavigationBar: _buildMobileBottomBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600),
            child: _buildFormContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    bool isOtherSelected = _selectedReason == "Another reason";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            "Reason for Rejection",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),

        ..._reasons.map((reason) => _buildRadioOption(reason)),

        const SizedBox(height: 24),

        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: isOtherSelected ? 150 : 0,
          curve: Curves.easeInOut,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Container(
              height: 140,
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF47C20), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF47C20).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _reasonController,
                enabled: isOtherSelected,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: "Please describe the specific reason...",
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRadioOption(String label) {
    bool isSelected = _selectedReason == label;

    return GestureDetector(
      onTap: () => setState(() => _selectedReason = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF8EC) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFF47C20) : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isSelected ? const Color(0xFFF47C20) : Colors.transparent,
                border: Border.all(
                  color:
                      isSelected
                          ? const Color(0xFFF47C20)
                          : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child:
                  isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.black87 : Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileBottomBar() {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: SizedBox(height: 52, child: _buildSubmitButton()),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: () {
        debugPrint("Selected: $_selectedReason");
        if (_selectedReason == "Another reason") {
          debugPrint("Note: ${_reasonController.text}");
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF47C20),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      child: const Text(
        "Submit Reason",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}
