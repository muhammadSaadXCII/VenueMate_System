import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:venuemate_system/Models/notification_model.dart';
import 'package:venuemate_system/Services/notification_service.dart';

const double _kNotifWebBreak = 900;

// ══════════════════════════════════════════════════════════════════════════════
//  USER NOTIFICATIONS SCREEN
//  Live stream from Firestore via NotificationService.
//  Works for all roles: Customer, Hall Admin, System Admin.
// ══════════════════════════════════════════════════════════════════════════════

class UserNotificationsScreen extends StatefulWidget {
  const UserNotificationsScreen({super.key});
  @override
  State<UserNotificationsScreen> createState() =>
      _UserNotificationsScreenState();
}

class _UserNotificationsScreenState extends State<UserNotificationsScreen> {
  String? _uid;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> _markAllRead() async {
    if (_uid == null) return;
    await NotificationService.markAllAsRead(uid: _uid!);
  }

  Future<void> _delete(String notificationId) async {
    await NotificationService.deleteNotification(
      notificationId: notificationId,
    );
  }

  Future<void> _markRead(String notificationId) async {
    await NotificationService.markAsRead(notificationId: notificationId);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= _kNotifWebBreak;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading:
            Navigator.canPop(context)
                ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                )
                : null,
        title: const Text(
          'Notifications',
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
              'Mark all read',
              style: TextStyle(
                color: Color(0xFFF47C20),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body:
          _uid == null
              ? _buildEmptyState(isWide)
              : StreamBuilder<List<NotificationModel>>(
                stream: NotificationService.streamNotifications(uid: _uid!),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFF47C20),
                      ),
                    );
                  }
                  final notifications = snap.data ?? [];
                  if (notifications.isEmpty) return _buildEmptyState(isWide);

                  return isWide
                      ? _buildWebLayout(notifications)
                      : _buildMobileLayout(notifications);
                },
              ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  WEB — two column: notification list left + summary panel right
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildWebLayout(List<NotificationModel> notifications) {
    final unreadCount = notifications.where((n) => n.isUnread).length;
    final groups = _groupByDate(notifications);

    // Category counts for the summary panel
    final categoryCounts = <String, int>{};
    for (final n in notifications) {
      categoryCounts[n.type.category] =
          (categoryCounts[n.type.category] ?? 0) + 1;
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left: notification list ─────────────────────────────────
              Expanded(
                flex: 7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'All Notifications',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            if (unreadCount > 0) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF47C20),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$unreadCount new',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          '${notifications.length} total',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // List
                    Expanded(
                      child: ListView.builder(
                        itemCount: groups.length,
                        itemBuilder:
                            (context, index) => _buildItem(
                              context,
                              groups,
                              index,
                              isWide: true,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // ── Right: summary panel ────────────────────────────────────
              SizedBox(
                width: 280,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Overview card
                      _webCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.notifications_outlined,
                                    color: Color(0xFFF47C20),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Overview',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _statRow(
                              'Total',
                              '${notifications.length}',
                              Colors.black87,
                            ),
                            const SizedBox(height: 10),
                            _statRow(
                              'Unread',
                              '$unreadCount',
                              unreadCount > 0
                                  ? const Color(0xFFF47C20)
                                  : Colors.grey,
                            ),
                            const SizedBox(height: 10),
                            _statRow(
                              'Read',
                              '${notifications.length - unreadCount}',
                              Colors.green.shade700,
                            ),
                            if (unreadCount > 0) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: TextButton(
                                  onPressed: _markAllRead,
                                  style: TextButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFF3E0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'Mark all as read',
                                    style: TextStyle(
                                      color: Color(0xFFF47C20),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Categories card
                      _webCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.category_outlined,
                                    color: Color(0xFFF47C20),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'By Category',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ...categoryCounts.entries.map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: _iconBg(e.key),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _iconFor(e.key),
                                        color: _iconColor(e.key),
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _categoryLabel(e.key),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${e.value}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tips card
                      _webCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.lightbulb_outline,
                                    color: Color(0xFFF47C20),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Tips',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...[
                              'Swipe a notification left to delete it.',
                              'Tap a notification to mark it as read.',
                              'Notifications are updated in real time.',
                            ].map(
                              (tip) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 6),
                                      width: 5,
                                      height: 5,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF47C20),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        tip,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  MOBILE — single column (unchanged behaviour)
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout(List<NotificationModel> notifications) {
    final groups = _groupByDate(notifications);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          itemCount: groups.length,
          itemBuilder:
              (context, index) =>
                  _buildItem(context, groups, index, isWide: false),
        ),
      ),
    );
  }

  // ── Shared item builder (group header OR notification card) ─────────────────
  Widget _buildItem(
    BuildContext context,
    List<dynamic> groups,
    int index, {
    required bool isWide,
  }) {
    final item = groups[index];

    // Date group header
    if (item is String) {
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 10),
        child: Row(
          children: [
            Text(
              item,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[500],
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1)),
          ],
        ),
      );
    }

    // Notification card
    final n = item as NotificationModel;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: ValueKey(n.notificationId),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.22,
          children: [
            SlidableAction(
              onPressed: (_) => _delete(n.notificationId),
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              icon: Icons.delete_outline,
              borderRadius: BorderRadius.circular(16),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () {
            if (n.isUnread) _markRead(n.notificationId);
          },
          child: NotificationCard(
            title: n.title,
            description: n.body,
            time: n.timeAgo,
            isUnread: n.isUnread,
            category: n.type.category,
            isDesktop: isWide,
            onDelete: () => _delete(n.notificationId),
          ),
        ),
      ),
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────────
  Widget _buildEmptyState(bool isWide) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isWide ? 120 : 90,
            height: isWide ? 120 : 90,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: isWide ? 56 : 44,
              color: Colors.grey[300],
            ),
          ),
          SizedBox(height: isWide ? 24 : 16),
          Text(
            "You're all caught up!",
            style: TextStyle(
              fontSize: isWide ? 22 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No notifications yet. Check back later.',
            style: TextStyle(
              fontSize: isWide ? 15 : 13,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  // ── Grouping helpers ────────────────────────────────────────────────────────
  List<dynamic> _groupByDate(List<NotificationModel> notifications) {
    final result = <dynamic>[];
    String? currentLabel;
    for (final n in notifications) {
      if (n.groupLabel != currentLabel) {
        currentLabel = n.groupLabel;
        result.add(currentLabel);
      }
      result.add(n);
    }
    return result;
  }

  // ── Web panel helpers ───────────────────────────────────────────────────────
  Widget _webCard({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      border: Border.all(color: Colors.grey.shade100),
    ),
    child: child,
  );

  Widget _statRow(String label, String value, Color valueColor) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      Text(
        value,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: valueColor,
        ),
      ),
    ],
  );

  String _categoryLabel(String cat) {
    switch (cat) {
      case 'booking':
        return 'Bookings';
      case 'payment':
        return 'Payments';
      case 'registration':
        return 'Registrations';
      case 'message':
        return 'Messages';
      case 'complaint':
        return 'Complaints';
      default:
        return 'General';
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  NOTIFICATION CARD
// ══════════════════════════════════════════════════════════════════════════════

class NotificationCard extends StatelessWidget {
  final String title;
  final String description;
  final String time;
  final bool isUnread;
  final String category;
  final bool isDesktop;
  final VoidCallback? onDelete;

  const NotificationCard({
    super.key,
    required this.title,
    required this.description,
    required this.time,
    required this.isUnread,
    required this.category,
    required this.isDesktop,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 18 : 16),
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
                  color: const Color(0xFFF47C20).withOpacity(0.3),
                  width: 1,
                )
                : Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon bubble
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: isUnread ? _iconBg(category) : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              _iconFor(category),
              color: isUnread ? _iconColor(category) : Colors.grey,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Text content
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
                          fontSize: 15,
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
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color:
                                isUnread
                                    ? const Color(0xFFF47C20)
                                    : Colors.grey,
                          ),
                        ),
                        // On desktop: always show × delete button (no hover needed)
                        if (isDesktop && onDelete != null) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: onDelete,
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.grey[400],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: isUnread ? Colors.grey[700] : Colors.grey[500],
                    height: 1.4,
                  ),
                ),

                // Category chip — visible on desktop for quick scanning
                if (isDesktop) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _iconBg(category),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _categoryLabel(category),
                      style: TextStyle(
                        fontSize: 11,
                        color: _iconColor(category),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Unread dot
          if (isUnread)
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 4),
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: Color(0xFFF47C20),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Icon / colour helpers keyed on NotificationType.category ──────────────
  IconData _iconFor(String cat) {
    switch (cat) {
      case 'booking':
        return Icons.calendar_today_outlined;
      case 'payment':
        return Icons.account_balance_wallet_outlined;
      case 'registration':
        return Icons.store_outlined;
      case 'message':
        return Icons.chat_bubble_outline;
      case 'complaint':
        return Icons.report_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _iconColor(String cat) {
    switch (cat) {
      case 'booking':
        return const Color(0xFF059669);
      case 'payment':
        return const Color(0xFFF47C20);
      case 'registration':
        return const Color(0xFF7C3AED);
      case 'message':
        return const Color(0xFF2563EB);
      case 'complaint':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFFF47C20);
    }
  }

  Color _iconBg(String cat) {
    switch (cat) {
      case 'booking':
        return const Color(0xFFD1FAE5);
      case 'payment':
        return const Color(0xFFFFF7ED);
      case 'registration':
        return const Color(0xFFEDE9FE);
      case 'message':
        return const Color(0xFFDBEAFE);
      case 'complaint':
        return const Color(0xFFFFE4E4);
      default:
        return const Color(0xFFFFF7ED);
    }
  }

  String _categoryLabel(String cat) {
    switch (cat) {
      case 'booking':
        return 'Booking';
      case 'payment':
        return 'Payment';
      case 'registration':
        return 'Registration';
      case 'message':
        return 'Message';
      case 'complaint':
        return 'Complaint';
      default:
        return 'General';
    }
  }
}

// Top-level helpers shared between screen and card (avoids duplication)
IconData _iconFor(String cat) {
  switch (cat) {
    case 'booking':
      return Icons.calendar_today_outlined;
    case 'payment':
      return Icons.account_balance_wallet_outlined;
    case 'registration':
      return Icons.store_outlined;
    case 'message':
      return Icons.chat_bubble_outline;
    case 'complaint':
      return Icons.report_outlined;
    default:
      return Icons.notifications_outlined;
  }
}

Color _iconColor(String cat) {
  switch (cat) {
    case 'booking':
      return const Color(0xFF059669);
    case 'payment':
      return const Color(0xFFF47C20);
    case 'registration':
      return const Color(0xFF7C3AED);
    case 'message':
      return const Color(0xFF2563EB);
    case 'complaint':
      return const Color(0xFFDC2626);
    default:
      return const Color(0xFFF47C20);
  }
}

Color _iconBg(String cat) {
  switch (cat) {
    case 'booking':
      return const Color(0xFFD1FAE5);
    case 'payment':
      return const Color(0xFFFFF7ED);
    case 'registration':
      return const Color(0xFFEDE9FE);
    case 'message':
      return const Color(0xFFDBEAFE);
    case 'complaint':
      return const Color(0xFFFFE4E4);
    default:
      return const Color(0xFFFFF7ED);
  }
}
