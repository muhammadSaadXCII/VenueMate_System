import 'dart:async';
import 'package:flutter/material.dart';
import 'package:venuemate_system/Models/user_model.dart';
import 'package:venuemate_system/Services/user_service.dart';
import 'package:venuemate_system/Utils/app_navigation.dart';
import 'manage_user_details.dart';

const double _kWebBreak = 900;

// ── Debouncer Utility ────────────────────────────────────────────────────────
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

class ManageAllUsersScreen extends StatefulWidget {
  const ManageAllUsersScreen({super.key});
  @override
  State<ManageAllUsersScreen> createState() => _ManageAllUsersScreenState();
}

class _ManageAllUsersScreenState extends State<ManageAllUsersScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 400); // 400ms search delay

  late Stream<List<UserModel>> _usersStream;
  UserModel? _selectedUser;

  final List<String> _filters = [
    'All',
    'Active',
    'Disabled',
    'Customer',
    'Hall Admin',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize stream once to prevent re-subscriptions on every rebuild
    _usersStream = UserService.streamAllUsers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<UserModel> _applyFilters(List<UserModel> all) {
    var list = all;
    switch (_selectedFilter) {
      case 'Active':
        list = list.where((u) => !u.isDisabled).toList();
        break;
      case 'Disabled':
        list = list.where((u) => u.isDisabled).toList();
        break;
      case 'Customer':
        list = list.where((u) => u.isCustomer).toList();
        break;
      case 'Hall Admin':
        list = list.where((u) => u.isVenueOwner).toList();
        break;
      default:
        list = list.where((u) => !u.isSystemAdmin).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list =
          list
              .where(
                (u) =>
                    u.name.toLowerCase().contains(q) ||
                    u.email.toLowerCase().contains(q) ||
                    u.phone.contains(q),
              )
              .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= _kWebBreak;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar:
          isWide
              ? null
              : AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                scrolledUnderElevation: 0,
                centerTitle: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text(
                  'Manage All Users',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      body: StreamBuilder<List<UserModel>>(
        stream: _usersStream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFF47C20)),
            );
          }
          final users = _applyFilters(snap.data ?? []);
          return isWide ? _buildWebLayout(users) : _buildMobileLayout(users);
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  MOBILE layout
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout(List<UserModel> users) => Column(
    children: [
      _searchAndFilters(false),
      Expanded(
        child:
            users.isEmpty
                ? _emptyState()
                : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  itemCount: users.length,
                  itemBuilder:
                      (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _UserCard(
                          user: users[i],
                          isSelected: false,
                          onTap:
                              () => AppNavigation.push(
                                context,
                                ManageUserDetailsScreen(user: users[i]),
                              ),
                        ),
                      ),
                ),
      ),
    ],
  );

  // ══════════════════════════════════════════════════════════════════════════
  //  WEB layout — Left List + Right Detail
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildWebLayout(List<UserModel> users) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 420,
        child: Column(
          children: [
            _searchAndFilters(true),
            Expanded(
              child:
                  users.isEmpty
                      ? _emptyState()
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        itemCount: users.length,
                        itemBuilder:
                            (_, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _UserCard(
                                user: users[i],
                                isSelected: _selectedUser?.uid == users[i].uid,
                                onTap:
                                    () => setState(
                                      () => _selectedUser = users[i],
                                    ),
                              ),
                            ),
                      ),
            ),
          ],
        ),
      ),
      Container(width: 1, color: Colors.grey.shade200),
      Expanded(
        child:
            _selectedUser == null
                ? _buildNoSelection()
                : ManageUserDetailsScreen(
                  // ValueKey resets detail screen state when a different user is clicked
                  key: ValueKey(_selectedUser!.uid),
                  user: _selectedUser!,
                  inlineMode: true,
                  onUserUpdated: (u) {
                    // Only trigger parent update if status changed to avoid redundant rebuilds
                    if (_selectedUser?.isDisabled != u.isDisabled) {
                      setState(() => _selectedUser = u);
                    }
                  },
                ),
      ),
    ],
  );

  Widget _buildNoSelection() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text(
          'Select a user to view details',
          style: TextStyle(color: Colors.grey[400], fontSize: 16),
        ),
      ],
    ),
  );

  Widget _searchAndFilters(bool isWide) => Container(
    color: isWide ? null : Colors.white,
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
    child: Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) {
              // Use Debouncer to prevent rebuild on every character
              _debouncer.run(() {
                setState(() => _searchQuery = v.trim());
              });
            },
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search by name, email or phone...',
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
              prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
              suffixIcon:
                  _searchQuery.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                      : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                _filters
                    .map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _filterChip(f),
                      ),
                    )
                    .toList(),
          ),
        ),
      ],
    ),
  );

  Widget _filterChip(String label) {
    final isActive = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF47C20) : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text(
          _searchQuery.isNotEmpty || _selectedFilter != 'All'
              ? 'No users match your search.'
              : 'No users found.',
          style: TextStyle(color: Colors.grey[500]),
        ),
      ],
    ),
  );
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;
  final bool isSelected;
  const _UserCard({
    required this.user,
    required this.onTap,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = !user.isDisabled;
    final roleLabel = user.isVenueOwner ? 'Hall Admin' : 'Customer';
    final roleColor =
        user.isVenueOwner ? Colors.purple : const Color(0xFFF47C20);
    final borderClr = isActive ? const Color(0xFFF47C20) : Colors.red.shade300;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF4EC) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFF47C20) : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderClr, width: 2),
              ),
              child: ClipOval(
                child:
                    user.profileImageUrl.isNotEmpty
                        ? Image.network(
                          user.profileImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => _avatarFallback(user.name),
                        )
                        : _avatarFallback(user.name),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          roleLabel,
                          style: TextStyle(
                            color: roleColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isActive ? Icons.check_circle : Icons.block,
              size: 18,
              color: isActive ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback(String name) {
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
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
