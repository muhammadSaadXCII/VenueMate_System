import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:venuemate_system/Services/auth_service.dart';
import 'package:venuemate_system/Services/hall_service.dart';
import 'package:venuemate_system/Services/storage_service.dart';
import 'package:venuemate_system/Models/hall_model.dart';
import 'package:venuemate_system/Widgets/common_button.dart';

const double _kManageHallWebBreak = 900;

class ManageHallScreen extends StatefulWidget {
  const ManageHallScreen({super.key});
  @override
  State<ManageHallScreen> createState() => _ManageHallScreenState();
}

class _ManageHallScreenState extends State<ManageHallScreen> {
  HallModel? _hall;
  bool _loading = true;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadHall();
  }

  Future<void> _loadHall() async {
    final uid = AuthService.currentUid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    final hall = await HallService.getHallByOwnerId(uid);
    if (mounted) {
      setState(() {
        _hall = hall;
        _loading = false;
      });
    }
  }

  Future<void> _addPhoto() async {
    if (_hall == null) return;
    final xf = await StorageService.pickImageXFile();
    if (xf == null) return;
    final error = await HallService.addHallPhotoXFile(
      hallId: _hall!.hallId,
      xFile: xf,
    );
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      _loadHall();
    }
  }

  Future<void> _removePhoto(String imageUrl) async {
    if (_hall == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Remove Photo'),
            content: const Text('Remove this photo from your hall?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
    if (confirm != true) return;
    final error = await HallService.removeHallPhoto(
      hallId: _hall!.hallId,
      imageUrl: imageUrl,
    );
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      _loadHall();
    }
  }

  void _editPublicDetails() {
    if (_hall == null) return;
    final isWide = MediaQuery.of(context).size.width >= _kManageHallWebBreak;
    if (isWide) {
      showDialog(
        context: context,
        builder: (_) => _EditDetailsDialog(hall: _hall!, onSaved: _loadHall),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _EditDetailsSheet(hall: _hall!, onSaved: _loadHall),
      );
    }
  }

  void _editPrivateDetails() {
    if (_hall == null) return;
    final isWide = MediaQuery.of(context).size.width >= _kManageHallWebBreak;
    if (isWide) {
      showDialog(
        context: context,
        builder: (_) => _EditBankDialog(hall: _hall!, onSaved: _loadHall),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _EditBankSheet(hall: _hall!, onSaved: _loadHall),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFF47C20)),
        ),
      );
    }
    if (_hall == null) {
      return const Scaffold(body: Center(child: Text('Hall not found.')));
    }
    final isWide = MediaQuery.of(context).size.width >= _kManageHallWebBreak;
    return isWide ? _buildWebLayout() : _buildMobileLayout();
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  WEB LAYOUT
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildWebLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _hall!.hallName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color:
                  _hall!.isApproved
                      ? Colors.green.shade50
                      : _hall!.isPending
                      ? Colors.amber.shade50
                      : Colors.red.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    _hall!.isApproved
                        ? Colors.green.shade300
                        : _hall!.isPending
                        ? Colors.amber.shade300
                        : Colors.red.shade300,
              ),
            ),
            child: Text(
              _hall!.isApproved
                  ? '✓ Approved'
                  : _hall!.isPending
                  ? '⏳ Pending'
                  : '✗ Rejected',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color:
                    _hall!.isApproved
                        ? Colors.green.shade700
                        : _hall!.isPending
                        ? Colors.amber.shade700
                        : Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left col — photos + documents
            SizedBox(
              width: 340,
              child: Column(
                children: [
                  // Photos card
                  _webCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Photos',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _addPhoto,
                              icon: const Icon(
                                Icons.add_photo_alternate,
                                size: 18,
                                color: Color(0xFFF47C20),
                              ),
                              label: const Text(
                                'Add',
                                style: TextStyle(
                                  color: Color(0xFFF47C20),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _hall!.imageUrls.isEmpty
                            ? Container(
                              height: 160,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.image,
                                  size: 48,
                                  color: Colors.grey[300],
                                ),
                              ),
                            )
                            : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 1.2,
                                  ),
                              itemCount: _hall!.imageUrls.length,
                              itemBuilder: (_, i) {
                                final url = _hall!.imageUrls[i];
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        url,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        errorBuilder:
                                            (_, __, ___) => Container(
                                              color: Colors.grey[200],
                                              child: const Icon(
                                                Icons.broken_image,
                                              ),
                                            ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => _removePhoto(url),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.85),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                        const SizedBox(height: 20),
                        _infoRow(Icons.place, "Location", _hall!.address),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Documents card
                  _webCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Documents',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _docRow('CNIC Front', _hall!.cnicFrontUrl),
                        const SizedBox(height: 10),
                        _docRow('CNIC Back', _hall!.cnicBackUrl),
                        const SizedBox(height: 10),
                        _docRow('NTN Document', _hall!.ntnDocUrl),
                        const SizedBox(height: 10),
                        _docRow('Business License', _hall!.businessLicenseUrl),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),

            // Right col — details
            Expanded(
              child: Column(
                children: [
                  // Public details
                  _webCard(
                    child: Column(
                      children: [
                        _sectionHeader(
                          'Public Details',
                          onEdit: _editPublicDetails,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  _infoRow(
                                    Icons.description,
                                    'Description',
                                    _hall!.description.isNotEmpty
                                        ? _hall!.description
                                        : 'No description added.',
                                  ),
                                  const SizedBox(height: 16),
                                  _infoRow(
                                    Icons.groups,
                                    'Guest Capacity',
                                    _hall!.capacityLabel,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                children: [
                                  _infoRow(
                                    Icons.payments,
                                    'Price Per Event',
                                    _hall!.priceLabel,
                                  ),
                                  const SizedBox(height: 16),
                                  _infoRow(
                                    Icons.phone,
                                    'Contact',
                                    _hall!.contactPhone.isNotEmpty
                                        ? _hall!.contactPhone
                                        : 'Not provided',
                                  ),
                                  const SizedBox(height: 16),
                                  _infoRow(
                                    Icons.star,
                                    'Rating',
                                    _hall!.ratingCount == 0
                                        ? 'No ratings yet'
                                        : '${_hall!.ratingAvg.toStringAsFixed(1)} ⭐ (${_hall!.ratingCount} reviews)',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Private details
                  _webCard(
                    child: Column(
                      children: [
                        _sectionHeader(
                          'Private / Payout Details',
                          onEdit: _editPrivateDetails,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _infoRow(
                                Icons.account_balance,
                                'Bank Name',
                                _hall!.bankName.isNotEmpty
                                    ? _hall!.bankName
                                    : 'Not provided',
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _infoRow(
                                Icons.numbers,
                                'Account Number',
                                _hall!.bankAccountNumber.isNotEmpty
                                    ? _hall!.bankAccountNumber
                                    : 'Not provided',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _webCard({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );

  // ════════════════════════════════════════════════════════════════════════════
  //  MOBILE LAYOUT (unchanged)
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(background: _buildCarousel()),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hall!.hallName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _hall!.address,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _statusBadge(),
                  if (_hall!.isRejected &&
                      _hall!.rejectionReason.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Rejection reason: ${_hall!.rejectionReason}',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  _sectionHeader('Public Details', onEdit: _editPublicDetails),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: _cardDec(),
                    child: Column(
                      children: [
                        _infoRow(
                          Icons.description,
                          'Description',
                          _hall!.description.isNotEmpty
                              ? _hall!.description
                              : 'No description added.',
                        ),
                        const SizedBox(height: 20),
                        _infoRow(
                          Icons.groups,
                          'Guest Capacity',
                          _hall!.capacityLabel,
                        ),
                        const SizedBox(height: 20),
                        _infoRow(
                          Icons.payments,
                          'Price Per Event',
                          _hall!.priceLabel,
                        ),
                        const SizedBox(height: 20),
                        _infoRow(
                          Icons.phone,
                          'Contact',
                          _hall!.contactPhone.isNotEmpty
                              ? _hall!.contactPhone
                              : 'Not provided',
                        ),
                        const SizedBox(height: 20),
                        _infoRow(
                          Icons.star,
                          'Rating',
                          _hall!.ratingCount == 0
                              ? 'No ratings yet'
                              : '${_hall!.ratingAvg.toStringAsFixed(1)} ⭐ (${_hall!.ratingCount} reviews)',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  _sectionHeader(
                    'Private / Payout Details',
                    onEdit: _editPrivateDetails,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: _cardDec(),
                    child: Column(
                      children: [
                        _infoRow(
                          Icons.account_balance,
                          'Bank Name',
                          _hall!.bankName.isNotEmpty
                              ? _hall!.bankName
                              : 'Not provided',
                        ),
                        const SizedBox(height: 20),
                        _infoRow(
                          Icons.numbers,
                          'Account Number',
                          _hall!.bankAccountNumber.isNotEmpty
                              ? _hall!.bankAccountNumber
                              : 'Not provided',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Uploaded Documents',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: _cardDec(),
                    child: Column(
                      children: [
                        _docRow('CNIC Front', _hall!.cnicFrontUrl),
                        const SizedBox(height: 12),
                        _docRow('CNIC Back', _hall!.cnicBackUrl),
                        const SizedBox(height: 12),
                        _docRow('NTN Document', _hall!.ntnDocUrl),
                        const SizedBox(height: 12),
                        _docRow('Business License', _hall!.businessLicenseUrl),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared helpers ──────────────────────────────────────────────────────────
  Widget _buildCarousel() {
    final images = _hall!.imageUrls;
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        images.isEmpty
            ? Container(
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.image, size: 80, color: Colors.grey),
              ),
            )
            : CarouselSlider(
              options: CarouselOptions(
                height: double.infinity,
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
                autoPlay: images.length > 1,
                autoPlayInterval: const Duration(seconds: 3),
                onPageChanged: (i, _) => setState(() => _currentImageIndex = i),
              ),
              items:
                  images
                      .map(
                        (url) => Stack(
                          children: [
                            Image.network(
                              url,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.broken_image),
                                  ),
                            ),
                            Positioned.fill(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onLongPress: () => _removePhoto(url),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
            ),
        Positioned(
          bottom: 16,
          right: 70,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.photo_library, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  images.isEmpty
                      ? '0 photos'
                      : '${_currentImageIndex + 1}/${images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 12,
          right: 16,
          child: GestureDetector(
            onTap: _addPhoto,
            child: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF47C20),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_photo_alternate,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color:
          _hall!.isApproved
              ? Colors.green.shade50
              : _hall!.isPending
              ? Colors.amber.shade50
              : Colors.red.shade50,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color:
            _hall!.isApproved
                ? Colors.green.shade300
                : _hall!.isPending
                ? Colors.amber.shade300
                : Colors.red.shade300,
      ),
    ),
    child: Text(
      _hall!.isApproved
          ? '✓ Approved'
          : _hall!.isPending
          ? '⏳ Pending Admin Review'
          : '✗ Rejected',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color:
            _hall!.isApproved
                ? Colors.green.shade700
                : _hall!.isPending
                ? Colors.amber.shade700
                : Colors.red.shade700,
      ),
    ),
  );

  Widget _sectionHeader(String title, {required VoidCallback onEdit}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(8),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Row(
            children: [
              Icon(Icons.edit, size: 16, color: Color(0xFFF47C20)),
              SizedBox(width: 4),
              Text(
                'Edit',
                style: TextStyle(
                  color: Color(0xFFF47C20),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  BoxDecoration _cardDec() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.06),
        spreadRadius: 2,
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  Widget _infoRow(IconData icon, String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: Colors.grey[700]),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _docRow(String label, String url) {
    final hasDoc = url.isNotEmpty;
    return Row(
      children: [
        Icon(
          hasDoc ? Icons.check_circle : Icons.cancel,
          size: 20,
          color: hasDoc ? Colors.green : Colors.red.shade300,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Text(
          hasDoc ? 'Uploaded' : 'Not uploaded',
          style: TextStyle(
            fontSize: 12,
            color: hasDoc ? Colors.green.shade700 : Colors.red.shade300,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  EDIT PUBLIC DETAILS — Dialog (web) + Sheet (mobile)
// ══════════════════════════════════════════════════════════════════════════════
class _EditDetailsDialog extends StatefulWidget {
  final HallModel hall;
  final VoidCallback onSaved;
  const _EditDetailsDialog({required this.hall, required this.onSaved});
  @override
  State<_EditDetailsDialog> createState() => _EditDetailsDialogState();
}

class _EditDetailsDialogState extends State<_EditDetailsDialog> {
  late final TextEditingController _nameCtrl,
      _descCtrl,
      _phoneCtrl,
      _priceCtrl,
      _minCtrl,
      _maxCtrl;
  bool _isSaving = false;
  @override
  void initState() {
    super.initState();
    final h = widget.hall;
    _nameCtrl = TextEditingController(text: h.hallName);
    _descCtrl = TextEditingController(text: h.description);
    _phoneCtrl = TextEditingController(text: h.contactPhone);
    _priceCtrl = TextEditingController(
      text: h.pricePerEvent.toStringAsFixed(0),
    );
    _minCtrl = TextEditingController(text: h.capacityMin.toString());
    _maxCtrl = TextEditingController(text: h.capacityMax.toString());
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _descCtrl,
      _phoneCtrl,
      _priceCtrl,
      _minCtrl,
      _maxCtrl,
    ]) {
      c.dispose();
    }

    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final error = await HallService.updateHallDetails(
      hallId: widget.hall.hallId,
      hallName: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      contactPhone: _phoneCtrl.text.trim(),
      pricePerEvent: double.tryParse(_priceCtrl.text.trim()),
      capacityMin: int.tryParse(_minCtrl.text.trim()),
      capacityMax: int.tryParse(_maxCtrl.text.trim()),
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      widget.onSaved();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Container(
      width: 560,
      padding: const EdgeInsets.all(28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Public Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _f('Hall Name', _nameCtrl, 'Enter hall name')),
                const SizedBox(width: 16),
                Expanded(
                  child: _f(
                    'Price Per Event (Rs.)',
                    _priceCtrl,
                    'Enter price',
                    type: TextInputType.number,
                  ),
                ),
              ],
            ),
            _f('Description', _descCtrl, 'Enter description', maxLines: 3),
            _f(
              'Contact Phone',
              _phoneCtrl,
              'Phone number',
              type: TextInputType.phone,
            ),
            const Text(
              'Guest Capacity',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _fRaw(_minCtrl, 'Min', TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(child: _fRaw(_maxCtrl, 'Max', TextInputType.number)),
              ],
            ),
            const SizedBox(height: 20),
            CommonButton(
              text: 'Save Changes',
              onTap: _isSaving ? () {} : _save,
            ),
          ],
        ),
      ),
    ),
  );
  Widget _f(
    String l,
    TextEditingController c,
    String h, {
    int maxLines = 1,
    TextInputType? type,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: c,
          maxLines: maxLines,
          keyboardType: type,
          decoration: _dec(h),
        ),
      ],
    ),
  );
  Widget _fRaw(TextEditingController c, String h, TextInputType t) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(controller: c, keyboardType: t, decoration: _dec(h)),
  );
  InputDecoration _dec(String h) => InputDecoration(
    hintText: h,
    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
    filled: true,
    fillColor: Colors.grey[50],
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}

// ── Mobile sheet (unchanged) ────────────────────────────────────────────────
class _EditDetailsSheet extends StatefulWidget {
  final HallModel hall;
  final VoidCallback onSaved;
  const _EditDetailsSheet({required this.hall, required this.onSaved});
  @override
  State<_EditDetailsSheet> createState() => _EditDetailsSheetState();
}

class _EditDetailsSheetState extends State<_EditDetailsSheet> {
  late final TextEditingController _nameCtrl,
      _descCtrl,
      _phoneCtrl,
      _priceCtrl,
      _minCtrl,
      _maxCtrl;
  bool _isSaving = false;
  @override
  void initState() {
    super.initState();
    final h = widget.hall;
    _nameCtrl = TextEditingController(text: h.hallName);
    _descCtrl = TextEditingController(text: h.description);
    _phoneCtrl = TextEditingController(text: h.contactPhone);
    _priceCtrl = TextEditingController(
      text: h.pricePerEvent.toStringAsFixed(0),
    );
    _minCtrl = TextEditingController(text: h.capacityMin.toString());
    _maxCtrl = TextEditingController(text: h.capacityMax.toString());
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _descCtrl,
      _phoneCtrl,
      _priceCtrl,
      _minCtrl,
      _maxCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final error = await HallService.updateHallDetails(
      hallId: widget.hall.hallId,
      hallName: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      contactPhone: _phoneCtrl.text.trim(),
      pricePerEvent: double.tryParse(_priceCtrl.text.trim()),
      capacityMin: int.tryParse(_minCtrl.text.trim()),
      capacityMax: int.tryParse(_maxCtrl.text.trim()),
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      widget.onSaved();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Edit Public Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _f('Hall Name', _nameCtrl, 'Enter hall name'),
            _f('Description', _descCtrl, 'Enter description', maxLines: 3),
            _f(
              'Contact Phone',
              _phoneCtrl,
              'Phone number',
              type: TextInputType.phone,
            ),
            _f(
              'Price Per Event (Rs.)',
              _priceCtrl,
              'Enter price',
              type: TextInputType.number,
            ),
            const Text(
              'Guest Capacity',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _fRaw(_minCtrl, 'Min', TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(child: _fRaw(_maxCtrl, 'Max', TextInputType.number)),
              ],
            ),
            const SizedBox(height: 24),
            CommonButton(
              text: 'Save Changes',
              onTap: _isSaving ? () {} : _save,
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
          ],
        ),
      ),
    ),
  );
  Widget _f(
    String l,
    TextEditingController c,
    String h, {
    int maxLines = 1,
    TextInputType? type,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: c,
          maxLines: maxLines,
          keyboardType: type,
          decoration: _dec(h),
        ),
      ],
    ),
  );
  Widget _fRaw(TextEditingController c, String h, TextInputType t) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(controller: c, keyboardType: t, decoration: _dec(h)),
  );
  InputDecoration _dec(String h) => InputDecoration(
    hintText: h,
    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
    filled: true,
    fillColor: Colors.grey[50],
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  EDIT BANK DETAILS — Dialog (web) + Sheet (mobile)
// ══════════════════════════════════════════════════════════════════════════════
class _EditBankDialog extends StatefulWidget {
  final HallModel hall;
  final VoidCallback onSaved;
  const _EditBankDialog({required this.hall, required this.onSaved});
  @override
  State<_EditBankDialog> createState() => _EditBankDialogState();
}

class _EditBankDialogState extends State<_EditBankDialog> {
  late final TextEditingController _bankCtrl, _accCtrl;
  bool _isSaving = false;
  @override
  void initState() {
    super.initState();
    _bankCtrl = TextEditingController(text: widget.hall.bankName);
    _accCtrl = TextEditingController(text: widget.hall.bankAccountNumber);
  }

  @override
  void dispose() {
    _bankCtrl.dispose();
    _accCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await FirebaseUpdateHelper.updateBankDetails(
      hallId: widget.hall.hallId,
      bankName: _bankCtrl.text.trim(),
      bankAccountNumber: _accCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    widget.onSaved();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Container(
      width: 480,
      padding: const EdgeInsets.all(28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Payout Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _f('Bank Name', _bankCtrl, 'Enter bank name'),
            _f(
              'Bank Account Number',
              _accCtrl,
              'Enter account number',
              type: TextInputType.number,
            ),
            const SizedBox(height: 8),
            CommonButton(
              text: 'Save Changes',
              onTap: _isSaving ? () {} : _save,
            ),
          ],
        ),
      ),
    ),
  );
  Widget _f(
    String l,
    TextEditingController c,
    String h, {
    TextInputType? type,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: c,
          keyboardType: type,
          decoration: InputDecoration(
            hintText: h,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFFF97316),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    ),
  );
}

class _EditBankSheet extends StatefulWidget {
  final HallModel hall;
  final VoidCallback onSaved;
  const _EditBankSheet({required this.hall, required this.onSaved});
  @override
  State<_EditBankSheet> createState() => _EditBankSheetState();
}

class _EditBankSheetState extends State<_EditBankSheet> {
  late final TextEditingController _bankCtrl, _accCtrl;
  bool _isSaving = false;
  @override
  void initState() {
    super.initState();
    _bankCtrl = TextEditingController(text: widget.hall.bankName);
    _accCtrl = TextEditingController(text: widget.hall.bankAccountNumber);
  }

  @override
  void dispose() {
    _bankCtrl.dispose();
    _accCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await FirebaseUpdateHelper.updateBankDetails(
      hallId: widget.hall.hallId,
      bankName: _bankCtrl.text.trim(),
      bankAccountNumber: _accCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    widget.onSaved();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Edit Payout Details',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _f('Bank Name', _bankCtrl, 'Enter bank name'),
          _f(
            'Bank Account Number',
            _accCtrl,
            'Enter account number',
            type: TextInputType.number,
          ),
          const SizedBox(height: 16),
          CommonButton(text: 'Save Changes', onTap: _isSaving ? () {} : _save),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
        ],
      ),
    ),
  );
  Widget _f(
    String l,
    TextEditingController c,
    String h, {
    TextInputType? type,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: c,
          keyboardType: type,
          decoration: InputDecoration(
            hintText: h,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFFF97316),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    ),
  );
}

class FirebaseUpdateHelper {
  static Future<void> updateBankDetails({
    required String hallId,
    required String bankName,
    required String bankAccountNumber,
  }) async {
    await FirebaseFirestore.instance.collection('halls').doc(hallId).update({
      'bankName': bankName,
      'bankAccountNumber': bankAccountNumber,
    });
  }
}
