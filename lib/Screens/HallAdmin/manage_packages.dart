import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:venuemate_system/Utils/app_navigation.dart';
import 'package:venuemate_system/Services/auth_service.dart';
import 'package:venuemate_system/Services/hall_service.dart';
import 'package:venuemate_system/Services/package_service.dart';
import '../../Models/package_model.dart';
import 'create_package.dart';

const double _kPkgWebBreak = 900;

class ManagePackagesScreen extends StatefulWidget {
  const ManagePackagesScreen({super.key});
  @override
  State<ManagePackagesScreen> createState() => _ManagePackagesScreenState();
}

class _ManagePackagesScreenState extends State<ManagePackagesScreen> {
  String? _hallId;

  @override
  void initState() {
    super.initState();
    _loadHallId();
  }

  Future<void> _loadHallId() async {
    final uid = AuthService.currentUid;
    if (uid == null) return;
    final hall = await HallService.getHallByOwnerId(uid);
    if (mounted) setState(() => _hallId = hall?.hallId);
  }

  Future<void> _deletePackage(PackageModel pkg) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Delete Package'),
            content: Text('Delete "${pkg.name}"? This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
    if (confirm != true || _hallId == null) return;
    final error = await PackageService.deletePackage(
      hallId: _hallId!,
      packageId: pkg.packageId,
    );
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= _kPkgWebBreak;
    final screenWidth = MediaQuery.of(context).size.width;

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
          'Manage Packages',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body:
          _hallId == null
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFF47C20)),
              )
              : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1200,
                  ), // Slightly tighter max width
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 500,
                                  ),
                                  child: GestureDetector(
                                    onTap:
                                        () => AppNavigation.push(
                                          context,
                                          CreatePackageScreen(hallId: _hallId!),
                                        ),
                                    child: Container(
                                      width: double.infinity,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFE0C2),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_circle_outline,
                                            color: Color(0xFFF47C20),
                                            size: 22,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            'Add New Package',
                                            style: TextStyle(
                                              color: Color(0xFFF47C20),
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24), // Reduced from 30
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  'Event Packages',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      StreamBuilder<List<PackageModel>>(
                        stream: PackageService.streamPackages(_hallId!),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const SliverToBoxAdapter(
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.all(40),
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFF47C20),
                                  ),
                                ),
                              ),
                            );
                          }

                          final packages = snap.data ?? [];
                          if (packages.isEmpty) {
                            return SliverToBoxAdapter(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(60),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.card_giftcard_outlined,
                                        size: 64,
                                        color: Colors.grey[300],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No packages yet.',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          if (isWide) {
                            return SliverPadding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                12,
                                20,
                                40,
                              ), // Top padding reduced to 12
                              sliver: SliverGrid(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount:
                                      screenWidth > 1100
                                          ? 3
                                          : 2, // 3 columns on very wide screens
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  // Optimized aspect ratio: 2.2 makes the cards shorter horizontally
                                  childAspectRatio:
                                      screenWidth > 1100 ? 1.6 : 2.1,
                                ),
                                delegate: SliverChildBuilderDelegate((_, i) {
                                  final pkg = packages[i];
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Slidable(
                                      key: ValueKey(pkg.packageId),
                                      endActionPane: ActionPane(
                                        motion: const ScrollMotion(),
                                        children: [
                                          SlidableAction(
                                            onPressed:
                                                (_) => AppNavigation.push(
                                                  context,
                                                  CreatePackageScreen(
                                                    hallId: _hallId!,
                                                    existing: pkg,
                                                  ),
                                                ),
                                            backgroundColor:
                                                Colors.blue.shade50,
                                            foregroundColor: Colors.blue,
                                            icon: Icons.edit,
                                            label: 'Edit',
                                          ),
                                          SlidableAction(
                                            onPressed:
                                                (_) => _deletePackage(pkg),
                                            backgroundColor: Colors.red.shade50,
                                            foregroundColor: Colors.red,
                                            icon: Icons.delete,
                                            label: 'Delete',
                                          ),
                                        ],
                                      ),
                                      child: _PackageCard(
                                        pkg: pkg,
                                        onToggle:
                                            (val) =>
                                                PackageService.togglePackageStatus(
                                                  hallId: _hallId!,
                                                  packageId: pkg.packageId,
                                                  isActive: val,
                                                ),
                                      ),
                                    ),
                                  );
                                }, childCount: packages.length),
                              ),
                            );
                          }

                          return SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((_, i) {
                                final pkg = packages[i];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Slidable(
                                      key: ValueKey(pkg.packageId),
                                      endActionPane: ActionPane(
                                        motion: const ScrollMotion(),
                                        children: [
                                          SlidableAction(
                                            onPressed:
                                                (_) => AppNavigation.push(
                                                  context,
                                                  CreatePackageScreen(
                                                    hallId: _hallId!,
                                                    existing: pkg,
                                                  ),
                                                ),
                                            backgroundColor:
                                                Colors.blue.shade50,
                                            foregroundColor: Colors.blue,
                                            icon: Icons.edit,
                                            label: 'Edit',
                                          ),
                                          SlidableAction(
                                            onPressed:
                                                (_) => _deletePackage(pkg),
                                            backgroundColor: Colors.red.shade50,
                                            foregroundColor: Colors.red,
                                            icon: Icons.delete,
                                            label: 'Delete',
                                          ),
                                        ],
                                      ),
                                      child: _PackageCard(
                                        pkg: pkg,
                                        onToggle:
                                            (val) =>
                                                PackageService.togglePackageStatus(
                                                  hallId: _hallId!,
                                                  packageId: pkg.packageId,
                                                  isActive: val,
                                                ),
                                      ),
                                    ),
                                  ),
                                );
                              }, childCount: packages.length),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final PackageModel pkg;
  final ValueChanged<bool> onToggle;
  const _PackageCard({required this.pkg, required this.onToggle});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            MainAxisAlignment
                .center, // Centers content vertically to fill card space
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      pkg.isActive
                          ? Colors.green.shade50
                          : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  pkg.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: pkg.isActive ? Colors.green : Colors.grey,
                  ),
                ),
              ),
              SizedBox(
                height: 24,
                child: Transform.scale(
                  scale: 0.7,
                  child: Switch(
                    value: pkg.isActive,
                    onChanged: onToggle,
                    activeColor: const Color(0xFFF47C20),
                    inactiveThumbColor: Colors.grey.shade400,
                    inactiveTrackColor: Colors.grey.shade200,
                    trackOutlineColor: MaterialStateProperty.all(
                      Colors.transparent,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            pkg.name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              height: 1.2,
            ),
            maxLines: 1, // Reduced to 1 to save space
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            pkg.priceLabel,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFFF47C20),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _feature(Icons.groups_outlined, pkg.capacityLabel, 'Capacity'),
              _feature(Icons.restaurant_menu, pkg.menuCount, 'Menu'),
              _feature(
                Icons.room_service_outlined,
                pkg.serviceCount,
                'Services',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _feature(IconData icon, String value, String label) => Column(
    children: [
      Icon(icon, size: 20, color: Colors.grey.shade600),
      const SizedBox(height: 4),
      Text(
        value.split(' ').first,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade500,
        ),
      ),
    ],
  );
}
