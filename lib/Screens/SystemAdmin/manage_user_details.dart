import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:venuemate_system/Models/user_model.dart';
import 'package:venuemate_system/Services/user_service.dart';

class ManageUserDetailsScreen extends StatefulWidget {
  final UserModel user;
  final bool inlineMode;
  final ValueChanged<UserModel>? onUserUpdated;

  const ManageUserDetailsScreen({
    super.key,
    required this.user,
    this.inlineMode = false,
    this.onUserUpdated,
  });

  @override
  State<ManageUserDetailsScreen> createState() =>
      _ManageUserDetailsScreenState();
}

class _ManageUserDetailsScreenState extends State<ManageUserDetailsScreen> {
  bool _isUpdating = false;

  late Stream<UserModel?> _userStream;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _userStream = _streamUser(widget.user.uid);
  }

  @override
  void didUpdateWidget(ManageUserDetailsScreen old) {
    super.didUpdateWidget(old);
    if (old.user.uid != widget.user.uid) {
      setState(() {
        _user = widget.user;
        _userStream = _streamUser(widget.user.uid);
      });
    }
  }

  Stream<UserModel?> _streamUser(String uid) => FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? UserModel.fromDoc(doc) : null);

  Future<Map<String, int>> _fetchBookingStats(String uid) async {
    try {
      final snap =
          await FirebaseFirestore.instance
              .collection('bookings')
              .where('customerId', isEqualTo: uid)
              .get();
      int completed = 0, upcoming = 0, cancelled = 0;
      for (final d in snap.docs) {
        final s = d.data()['status'] as String? ?? '';
        if (s == 'completed') completed++;
        if (s == 'confirmed') upcoming++;
        if (s == 'cancelled') cancelled++;
      }
      return {
        'total': snap.docs.length,
        'completed': completed,
        'upcoming': upcoming,
        'cancelled': cancelled,
      };
    } catch (_) {
      return {'total': 0, 'completed': 0, 'upcoming': 0, 'cancelled': 0};
    }
  }

  Future<void> _toggleStatus() async {
    final user = _user ?? widget.user;
    final willDisable = !user.isDisabled;
    final action = willDisable ? 'Disable' : 'Enable';

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Column(
              children: [
                Icon(
                  willDisable ? Icons.block : Icons.check_circle_outline,
                  color: willDisable ? Colors.red : Colors.green,
                  size: 52,
                ),
                const SizedBox(height: 12),
                Text(
                  '$action Account?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            content: Text(
              willDisable
                  ? 'This user will be blocked from logging in and will not be able to use VenueMate.'
                  : 'This user will regain access to VenueMate.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], height: 1.5),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            willDisable
                                ? const Color(0xFFD92D20)
                                : const Color(0xFFF47C20),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        action,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
    );

    if (confirmed != true) return;
    setState(() => _isUpdating = true);

    final error =
        willDisable
            ? await UserService.disableUser(user.uid)
            : await UserService.enableUser(user.uid);

    if (!mounted) return;
    setState(() => _isUpdating = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ??
              (willDisable
                  ? 'User account disabled.'
                  : 'User account enabled.'),
        ),
        backgroundColor:
            error != null
                ? Colors.red
                : (willDisable ? Colors.orange : Colors.green),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: _userStream,
      builder: (context, snap) {
        if (snap.hasData && snap.data != null) {
          final updatedUser = snap.data!;

          // Only trigger if a meaningful property changed (to prevent infinite loops)
          if (_user?.isDisabled != updatedUser.isDisabled ||
              _user?.role != updatedUser.role) {
            _user = updatedUser;

            // Schedule the callback to run AFTER the build is finished
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                widget.onUserUpdated?.call(updatedUser);
              }
            });
          }
        }
        final user = _user ?? widget.user;
        final isActive = !user.isDisabled;
        final roleLabel = user.isVenueOwner ? 'Hall Admin' : 'Customer';
        final statusColor =
            isActive ? const Color(0xFFF47C20) : Colors.redAccent;

        Widget bodyContent = SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            widget.inlineMode ? 20 : 100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile card
              _card(
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: statusColor, width: 3),
                        ),
                        child: ClipOval(
                          child:
                              user.profileImageUrl.isNotEmpty
                                  ? Image.network(
                                    user.profileImageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => _initials(user.name),
                                  )
                                  : _initials(user.name),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      user.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Role: $roleLabel',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        isActive ? '● Active' : '● Disabled',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Contact info
              _sectionHeader('Contact Information'),
              _contactTile(
                Icons.phone_in_talk_outlined,
                'Phone Number',
                user.phone.isNotEmpty ? user.phone : '—',
              ),
              const SizedBox(height: 10),
              _contactTile(Icons.email_outlined, 'Email Address', user.email),
              const SizedBox(height: 20),

              // Account info
              _sectionHeader('Account Information'),
              _card(
                child: Column(
                  children: [
                    _infoRow('User ID', user.uid, selectable: true),
                    _divider(),
                    _infoRow(
                      'Auth Provider',
                      user.authProvider == 'google'
                          ? '🔵 Google Sign-In'
                          : '📧 Email & Password',
                    ),
                    _divider(),
                    _infoRow(
                      'Email Verified',
                      user.isEmailVerified ? '✓ Verified' : '✗ Not verified',
                    ),
                    _divider(),
                    _infoRow('Member Since', _formatDate(user.createdAt)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Booking stats (customers only)
              if (user.isCustomer) ...[
                _sectionHeader('Booking Performance'),
                FutureBuilder<Map<String, int>>(
                  future: _fetchBookingStats(user.uid),
                  builder: (context, bSnap) {
                    final b =
                        bSnap.data ??
                        {
                          'total': 0,
                          'completed': 0,
                          'upcoming': 0,
                          'cancelled': 0,
                        };
                    return _card(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Bookings',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${b['total']}',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 32),
                          Row(
                            children: [
                              _miniStat(
                                Icons.check_circle_outline,
                                '${b['completed']}',
                                'Completed',
                                Colors.green,
                              ),
                              _miniStat(
                                Icons.calendar_today,
                                '${b['upcoming']}',
                                'Upcoming',
                                const Color(0xFFF47C20),
                              ),
                              _miniStat(
                                Icons.cancel_outlined,
                                '${b['cancelled']}',
                                'Cancelled',
                                Colors.redAccent,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );

        Widget actionBtn =
            _isUpdating
                ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFF47C20)),
                )
                : SizedBox(
                  height: 54,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _toggleStatus,
                    icon: Icon(
                      isActive ? Icons.block : Icons.check_circle_outline,
                    ),
                    label: Text(
                      isActive ? 'Deactivate Account' : 'Activate Account',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isActive
                              ? const Color(0xFFD92D20)
                              : const Color(0xFFF47C20),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                );

        // ── Inline mode (web right pane) — no Scaffold ──────────────────
        if (widget.inlineMode) {
          return Column(
            children: [
              Expanded(child: bodyContent),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: actionBtn,
              ),
            ],
          );
        }

        // ── Full-screen mode (mobile) ─────────────────────────────────────
        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
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
              'Manage User',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Stack(
            children: [
              bodyContent,
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: actionBtn,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12, left: 4),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    ),
  );

  Widget _contactTile(IconData icon, String label, String value) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.black87, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    ),
  );

  Widget _infoRow(String label, String value, {bool selectable = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
      Flexible(
        child:
            selectable
                ? SelectableText(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                )
                : Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.end,
                ),
      ),
    ],
  );

  Widget _divider() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Divider(height: 1, color: Colors.grey[200]),
  );

  Widget _miniStat(IconData icon, String count, String label, Color color) =>
      Expanded(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              count,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      );

  Widget _initials(String name) {
    final i =
        name.trim().isNotEmpty
            ? name
                .trim()
                .split(' ')
                .map((w) => w[0].toUpperCase())
                .take(2)
                .join()
            : '?';
    return Container(
      color: Colors.orange.shade50,
      child: Center(
        child: Text(
          i,
          style: const TextStyle(
            color: Color(0xFFF47C20),
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]}, ${d.year}';
  }
}
