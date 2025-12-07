import 'package:flutter/material.dart';
import 'package:venuemate_system/Widgets/gradient_button.dart';
import 'package:venuemate_system/Screens/Shared/file_complaint.dart';
import 'package:venuemate_system/Screens/Shared/user_complaint_details.dart';

class UserComplaintCenterScreen extends StatefulWidget {
  const UserComplaintCenterScreen({super.key});

  @override
  State<UserComplaintCenterScreen> createState() =>
      _UserComplaintCenterScreenState();
}

class _UserComplaintCenterScreenState extends State<UserComplaintCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Map<String, dynamic>? _selectedTicket;

  final List<Map<String, dynamic>> _allTickets = [
    {
      "id": "#TKT-9921",
      "subject": "Payout not received for Oct",
      "category": "Payment",
      "date": "1 hour ago",
      "status": "Pending",
      "priority": "High",
    },
    {
      "id": "#TKT-8802",
      "subject": "Update Hall Location Error",
      "category": "Technical",
      "date": "2 days ago",
      "status": "Pending",
      "priority": "Medium",
    },
    {
      "id": "#TKT-7500",
      "subject": "Verification Documents Upload",
      "category": "Account",
      "date": "1 week ago",
      "status": "Resolved",
      "priority": "Low",
    },
    {
      "id": "#TKT-6200",
      "subject": "Change Registered Phone Number",
      "category": "Account",
      "date": "2 weeks ago",
      "status": "Resolved",
      "priority": "Low",
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTicketTap(Map<String, dynamic> ticket, bool isDesktop) {
    if (isDesktop) {
      setState(() {
        _selectedTicket = ticket;
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserComplaintDetailsScreen(ticketData: ticket),
        ),
      );
    }
  }

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
          "Complaints Center",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 700;

          if (isDesktop) {
            return _buildDesktopLayout();
          } else {
            return _buildMobileLayout(isDesktop);
          }
        },
      ),

      bottomNavigationBar: MediaQuery.of(context).size.width < 700
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: GradientButton(
                text: "File New Complaint",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FileComplaintScreen(),
                    ),
                  );
                },
              ),
            )
          : null,
    );
  }

  Widget _buildDesktopLayout() {
    final pendingTickets = _allTickets
        .where((t) => t['status'] != 'Resolved')
        .toList();
    final resolvedTickets = _allTickets
        .where((t) => t['status'] == 'Resolved')
        .toList();

    return Row(
      children: [
        Container(
          width: 400,
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: Colors.grey.shade300)),
            color: Colors.white,
          ),
          child: Column(
            children: [
              const SizedBox(height: 20),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF47C20), Color(0xFFFFD166)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(text: "Pending"),
                    Tab(text: "Resolved"),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTicketList(pendingTickets, isDesktop: true),
                    _buildTicketList(resolvedTickets, isDesktop: true),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20.0),
                child: GradientButton(
                  text: "File New Complaint",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FileComplaintScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _selectedTicket == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.touch_app_outlined,
                        size: 60,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Select a complaint to view details",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : UserComplaintDetailsScreen(ticketData: _selectedTicket!),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(bool isDesktop) {
    final pendingTickets = _allTickets
        .where((t) => t['status'] != 'Resolved')
        .toList();
    final resolvedTickets = _allTickets
        .where((t) => t['status'] == 'Resolved')
        .toList();

    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF47C20), Color(0xFFFFD166)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: "Pending"),
              Tab(text: "Resolved"),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTicketList(pendingTickets, isDesktop: isDesktop),
              _buildTicketList(resolvedTickets, isDesktop: isDesktop),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTicketList(
    List<Map<String, dynamic>> tickets, {
    required bool isDesktop,
  }) {
    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_turned_in_outlined,
              size: 60,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 10),
            Text("No tickets found", style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        final bool isSelected = isDesktop && _selectedTicket == ticket;

        return _TicketCard(
          data: ticket,
          isSelected: isSelected,
          onTap: () => _onTicketTap(ticket, isDesktop),
        );
      },
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isSelected;
  final VoidCallback onTap;

  const _TicketCard({
    required this.data,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    Color statusBg;

    switch (data['status']) {
      case 'Resolved':
        statusColor = Colors.green;
        statusBg = Colors.green.shade50;
        break;
      default:
        statusColor = const Color(0xFFF58529);
        statusBg = const Color(0xFFFFF3E0);
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    data['id'],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ),
                Text(
                  data['date'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              data['subject'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              "Category: ${data['category']}",
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: Colors.grey[200]),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        data['status'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: const [
                    Text(
                      "View",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
