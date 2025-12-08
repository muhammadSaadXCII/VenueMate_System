import 'package:flutter/material.dart';
import 'package:venuemate_system/Utils/app_navigation.dart';
import 'package:venuemate_system/Widgets/common_button.dart';
import 'package:venuemate_system/Screens/Shared/user_booking_details.dart';
import 'package:venuemate_system/Screens/HallAdmin/view_receipt_sheet.dart';
import 'package:venuemate_system/Screens/HallAdmin/manage_refund_sheet.dart';

class HallAdminBookingsScreen extends StatefulWidget {
  const HallAdminBookingsScreen({super.key});

  @override
  State<HallAdminBookingsScreen> createState() =>
      _HallAdminBookingsScreenState();
}

class _HallAdminBookingsScreenState extends State<HallAdminBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          "Bookings",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: Color(0xFFF47C20),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade700,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              padding: EdgeInsets.zero,
              tabs: const [
                Tab(text: "Upcoming"),
                Tab(text: "Pending"),
                Tab(text: "Completed"),
                Tab(text: "Cancelled"),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBookingList(
                  status: "Paid",
                  primaryButtonLabel: "Message",
                  showTwoButtons: true,
                  secondaryButtonLabel: "View Details",
                  onPrimaryTap: () {},
                  onSecondaryTap: () => _navigateToDetails(context),
                ),

                _buildBookingList(
                  status: "Pending",
                  primaryButtonLabel: "",
                  showTwoButtons: false,
                  secondaryButtonLabel: "View Receipt",
                  onPrimaryTap: () {},
                  onSecondaryTap: () => _showReceiptSheet(context),
                ),

                _buildBookingList(
                  status: "Completed",
                  primaryButtonLabel: "",
                  showTwoButtons: false,
                  secondaryButtonLabel: "View Details",
                  isCompleted: true,
                  onPrimaryTap: () {},
                  onSecondaryTap: () => _navigateToDetails(context),
                ),

                _buildBookingList(
                  status: "Cancelled",
                  primaryButtonLabel: "Manage Refund",
                  showTwoButtons: true,
                  secondaryButtonLabel: "View Details",
                  isCancelled: true,
                  onPrimaryTap: () => _showRefundSheet(context),
                  onSecondaryTap: () => _navigateToDetails(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetails(BuildContext context) {
    AppNavigation.push(context, UserBookingDetailsScreen());
  }

  void _showReceiptSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ViewReceiptSheet(),
    );
  }

  void _showRefundSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ManageRefundSheet(),
    );
  }

  Widget _buildBookingList({
    required String status,
    required String primaryButtonLabel,
    required bool showTwoButtons,
    required String secondaryButtonLabel,
    required VoidCallback onPrimaryTap,
    required VoidCallback onSecondaryTap,
    bool isCompleted = false,
    bool isCancelled = false,
  }) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 3,
      itemBuilder: (context, index) {
        return _BookingCard(
          status: status,
          primaryButtonLabel: primaryButtonLabel,
          secondaryButtonLabel: secondaryButtonLabel,
          showTwoButtons: showTwoButtons,
          isCompleted: isCompleted,
          isCancelled: isCancelled,
          onPrimaryButtonTap: onPrimaryTap,
          onSecondaryButtonTap: onSecondaryTap,
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final String status;
  final String primaryButtonLabel;
  final String secondaryButtonLabel;
  final bool showTwoButtons;
  final bool isCompleted;
  final bool isCancelled;
  final VoidCallback onSecondaryButtonTap;
  final VoidCallback onPrimaryButtonTap;

  const _BookingCard({
    required this.status,
    required this.primaryButtonLabel,
    required this.secondaryButtonLabel,
    required this.showTwoButtons,
    this.isCompleted = false,
    this.isCancelled = false,
    required this.onSecondaryButtonTap,
    required this.onPrimaryButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    Color badgeBgColor;

    if (isCancelled) {
      badgeColor = const Color(0xFFD32F2F);
      badgeBgColor = const Color(0xFFFFCDD2);
    } else if (isCompleted) {
      badgeColor = const Color(0xFF388E3C);
      badgeBgColor = const Color(0xFFC8E6C9);
    } else if (status == "Pending") {
      badgeColor = const Color(0xFFFBC02D);
      badgeBgColor = const Color(0xFFFFF9C4);
    } else {
      badgeColor = const Color(0xFFFBC02D);
      badgeBgColor = const Color(0xFFFFF9C4);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  "https://images.unsplash.com/photo-1519167758481-83f550bb49b3?ixlib=rb-1.2.1&auto=format&fit=crop&w=200&q=80",
                  height: 80,
                  width: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(height: 80, width: 80, color: Colors.grey[300]),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Exclusive Birthday Celebration Bundle",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: Color(0xFFF47C20),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              "20 Nov, 2025",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBgColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                        children: [
                          TextSpan(
                            text: "Customer: ",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(text: "Muzamil Khan"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (showTwoButtons)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: onSecondaryButtonTap,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        secondaryButtonLabel,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CommonButton(
                    text: primaryButtonLabel,
                    onTap: onPrimaryButtonTap,
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: onSecondaryButtonTap,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Text(
                  secondaryButtonLabel,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
