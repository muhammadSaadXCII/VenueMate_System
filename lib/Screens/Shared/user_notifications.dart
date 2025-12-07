import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class UserNotificationsScreen extends StatefulWidget {
  const UserNotificationsScreen({super.key});

  @override
  State<UserNotificationsScreen> createState() =>
      _UserNotificationsScreenState();
}

class _UserNotificationsScreenState extends State<UserNotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      "id": 1,
      "title": "Booking Confirmed!",
      "description":
          "Your booking for 'Birthday Bash' at Al Rehman Hall has been confirmed by the owner.",
      "time": "25m ago",
      "type": "success",
      "isUnread": true,
    },
    {
      "id": 2,
      "title": "Payment Received",
      "description": "We have received your advance payment of Rs. 7,000.",
      "time": "2h ago",
      "type": "info",
      "isUnread": true,
    },
    {
      "id": 3,
      "title": "Daily Reminder",
      "description":
          "Don't forget to update your menu preferences for next week's event.",
      "time": "5h ago",
      "type": "alert",
      "isUnread": false,
    },
    {
      "id": 4,
      "title": "New Feature Alert",
      "description":
          "You can now add custom services to your package directly from the dashboard.",
      "time": "1d ago",
      "type": "promo",
      "isUnread": false,
    },
  ];

  void _deleteNotification(int index) {
    setState(() {
      _notifications.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Notification dismissed"),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _markAllRead() {
    setState(() {
      for (var n in _notifications) {
        n['isUnread'] = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text(
              "Mark all read",
              style: TextStyle(
                color: Color(0xFFF58529),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: isDesktop ? 40 : 16),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child:
              _notifications.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 0 : 20,
                      vertical: 20,
                    ),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),

                        child:
                            isDesktop
                                ? NotificationCard(
                                  title: notif['title'],
                                  description: notif['description'],
                                  time: notif['time'],
                                  isUnread: notif['isUnread'],
                                  type: notif['type'],

                                  onDelete: () => _deleteNotification(index),
                                  isDesktop: true,
                                )
                                : Slidable(
                                  key: ValueKey(notif['id']),
                                  endActionPane: ActionPane(
                                    motion: const ScrollMotion(),
                                    extentRatio: 0.25,
                                    children: [
                                      SlidableAction(
                                        onPressed:
                                            (context) =>
                                                _deleteNotification(index),
                                        backgroundColor: Colors.red.shade50,
                                        foregroundColor: Colors.red,
                                        icon: Icons.delete_outline,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ],
                                  ),
                                  child: NotificationCard(
                                    title: notif['title'],
                                    description: notif['description'],
                                    time: notif['time'],
                                    isUnread: notif['isUnread'],
                                    type: notif['type'],
                                    isDesktop: false,
                                  ),
                                ),
                      );
                    },
                  ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.notifications_off_outlined,
          size: 80,
          color: Colors.grey[300],
        ),
        const SizedBox(height: 16),
        Text(
          "No notifications yet",
          style: TextStyle(fontSize: 18, color: Colors.grey[500]),
        ),
      ],
    );
  }
}

class NotificationCard extends StatelessWidget {
  final String title;
  final String description;
  final String time;
  final bool isUnread;
  final String type;
  final bool isDesktop;
  final VoidCallback? onDelete;

  const NotificationCard({
    super.key,
    required this.title,
    required this.description,
    required this.time,
    required this.isUnread,
    required this.type,
    required this.isDesktop,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isUnread ? Colors.white : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isUnread ? 0.06 : 0.02),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border:
            isUnread
                ? Border.all(
                  color: const Color(0xFFF58529).withOpacity(0.3),
                  width: 1,
                )
                : Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: isUnread ? const Color(0xFFFFF3E0) : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIcon(type),
              color: isUnread ? const Color(0xFFF58529) : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 20),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isUnread ? FontWeight.bold : FontWeight.w600,
                          color: isUnread ? Colors.black87 : Colors.black54,
                        ),
                      ),
                    ),

                    Row(
                      children: [
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                isUnread
                                    ? const Color(0xFFF58529)
                                    : Colors.grey,
                          ),
                        ),

                        if (isDesktop && onDelete != null) ...[
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: onDelete,
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: isUnread ? Colors.grey[800] : Colors.grey[500],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          if (isUnread)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 5),
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'success':
        return Icons.check_circle_outline;
      case 'alert':
        return Icons.notifications_active_outlined;
      case 'info':
        return Icons.info_outline;
      case 'promo':
        return Icons.local_offer_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}
