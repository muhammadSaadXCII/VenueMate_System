import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Theme Color
  final Color primaryOrange = const Color(0xFFF47C20);

  // Dummy Data Source
  List<NotificationItem> notifications = [
    NotificationItem(
      id: '1',
      title: 'Booking Confirmed!',
      body: 'Your wedding hall booking for 25th Nov has been successfully confirmed.',
      time: '2 mins ago',
      type: NotificationType.booking,
      isUnread: true,
      category: 'Today',
    ),
    NotificationItem(
      id: '2',
      title: '30% Discount Available',
      body: 'Get 30% off on all catering services if you book before Friday!',
      time: '1 hour ago',
      type: NotificationType.promo,
      isUnread: true,
      category: 'Today',
    ),
    NotificationItem(
      id: '3',
      title: 'Payment Received',
      body: 'We have received your advance payment of \$500.',
      time: 'Yesterday, 10:00 AM',
      type: NotificationType.payment,
      isUnread: false,
      category: 'Yesterday',
    ),
    NotificationItem(
      id: '4',
      title: 'New Message from Manager',
      body: 'Please check the updated menu for the event.',
      time: 'Yesterday, 04:30 PM',
      type: NotificationType.message,
      isUnread: false,
      category: 'Yesterday',
    ),
    NotificationItem(
      id: '5',
      title: 'Security Alert',
      body: 'Your password was changed successfully.',
      time: '20 Nov, 2023',
      type: NotificationType.security,
      isUnread: false,
      category: 'Earlier',
    ),
  ];

  void _markAllAsRead() {
    setState(() {
      for (var n in notifications) {
        n.isUnread = false;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("All notifications marked as read"),
        backgroundColor: Colors.grey[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _deleteNotification(String id) {
    setState(() {
      notifications.removeWhere((item) => item.id == id);
    });
  }

  void _handleTap(NotificationItem item) {
    setState(() {
      item.isUnread = false;
    });
    // Add navigation logic here if needed
  }

  @override
  Widget build(BuildContext context) {
    // Grouping logic for the UI
    Map<String, List<NotificationItem>> groupedNotifications = {};
    for (var item in notifications) {
      if (!groupedNotifications.containsKey(item.category)) {
        groupedNotifications[item.category] = [];
      }
      groupedNotifications[item.category]!.add(item);
    }

    return Scaffold(
      backgroundColor: Colors.white, // Clean white background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: Text(
              "Mark all read",
              style: TextStyle(
                color: primaryOrange,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: groupedNotifications.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        entry.key, // "Today", "Yesterday", etc.
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    ...entry.value.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Dismissible(
                          key: Key(item.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (direction) => _deleteNotification(item.id),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.delete_outline,
                                color: Colors.red, size: 28),
                          ),
                          child: _buildNotificationCard(item),
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryOrange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_off_outlined,
                size: 50, color: primaryOrange),
          ),
          const SizedBox(height: 20),
          const Text(
            "No Notifications Yet",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            "We will let you know when something\nimportant arrives.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleTap(item),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: item.isUnread ? const Color(0xFFFFF8F2) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isUnread ? primaryOrange.withOpacity(0.3) : Colors.grey[200]!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Icon Container
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.isUnread ? primaryOrange : Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIconForType(item.type),
                  color: item.isUnread ? Colors.white : Colors.grey[600],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // 2. Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: item.isUnread ? FontWeight.bold : FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.isUnread)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: primaryOrange,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
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

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.booking:
        return Icons.calendar_today_rounded;
      case NotificationType.payment:
        return Icons.account_balance_wallet_rounded;
      case NotificationType.security:
        return Icons.lock_outline_rounded;
      case NotificationType.promo:
        return Icons.local_offer_rounded;
      case NotificationType.message:
        return Icons.chat_bubble_outline_rounded;
    }
  }
}

// --- Models ---

enum NotificationType { booking, payment, security, promo, message }

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String time;
  final NotificationType type;
  final String category; // 'Today', 'Yesterday'
  bool isUnread;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    required this.category,
    this.isUnread = false,
  });
}