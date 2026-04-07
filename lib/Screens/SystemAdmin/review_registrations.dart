import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:venuemate_system/Models/hall_model.dart';
import 'package:venuemate_system/Services/hall_service.dart';
import 'package:venuemate_system/Utils/app_navigation.dart';
import 'reject_registration.dart';

const double _kWebBreak = 840;

class ReviewRegistrationScreen extends StatefulWidget {
  final HallModel hall;
  const ReviewRegistrationScreen({super.key, required this.hall});

  @override
  State<ReviewRegistrationScreen> createState() =>
      _ReviewRegistrationScreenState();
}

class _ReviewRegistrationScreenState extends State<ReviewRegistrationScreen> {
  bool _isApproving = false;
  HallModel get h => widget.hall;

  // ── Approve ─────────────────────────────────────────────────────────────────
  Future<void> _approve() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Column(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green, size: 52),
                SizedBox(height: 12),
                Text(
                  'Approve Hall?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
            content: Text(
              'Approve "${h.hallName}"?\n\nThe hall will go live and the owner will be notified.',
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
                        backgroundColor: Colors.green,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Approve',
                        style: TextStyle(
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
    setState(() => _isApproving = true);
    final error = await HallService.approveHall(h.hallId);
    if (!mounted) return;
    setState(() => _isApproving = false);
    if (error != null) {
      _snack(error, isError: true);
    } else {
      _snack('Hall approved successfully! Owner has been notified.');
      Navigator.pop(context);
    }
  }

  void _snack(String msg, {bool isError = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isError ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= _kWebBreak;
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
        title: const Text(
          'Review Registration',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isWide ? _buildWebLayout() : _buildMobileLayout(),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  MOBILE layout — original stacked single column
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMobileLayout() => Column(
    children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (h.imageUrls.isNotEmpty) ...[
                _sectionTitle('Hall Photos'),
                _imageGallery(),
                const SizedBox(height: 24),
              ],
              _sectionTitle('Hall & Owner Info'),
              _infoCard(
                children: [
                  _labelRow('Hall Name', h.hallName, isLarge: true),
                  _divider(),
                  _labelRow('Contact Phone', h.contactPhone),
                  _divider(),
                  _labelRow('Location', h.address),
                ],
              ),
              const SizedBox(height: 20),
              _sectionTitle('Hall Details'),
              _detailsCard(),
              const SizedBox(height: 20),
              _sectionTitle('Banking Information'),
              _bankingCard(),
              const SizedBox(height: 20),
              _sectionTitle('Verification Documents'),
              _buildDocuments(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      _bottomBar(context),
    ],
  );

  // ══════════════════════════════════════════════════════════════════════════
  //  WEB layout — left column (photos + docs) | right column (info + actions)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildWebLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── LEFT: photos + documents ─────────────────────────────────────
            Expanded(
              flex: 5,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (h.imageUrls.isNotEmpty) ...[
                      _sectionTitle('Hall Photos'),
                      _imageGalleryWeb(),
                      const SizedBox(height: 28),
                    ],
                    _sectionTitle('Verification Documents'),
                    _buildDocuments(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Vertical divider
            Container(width: 1, color: Colors.grey.shade200),

            // ── RIGHT: info + sticky actions ────────────────────────────────
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle('Hall & Owner Info'),
                          _infoCard(
                            children: [
                              _labelRow('Hall Name', h.hallName, isLarge: true),
                              _divider(),
                              _labelRow('Contact Phone', h.contactPhone),
                              _divider(),
                              _labelRow('Location', h.address),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _sectionTitle('Hall Details'),
                          _detailsCard(),
                          const SizedBox(height: 20),
                          _sectionTitle('Banking Information'),
                          _bankingCard(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  // Sticky approve/reject at bottom of right panel
                  _bottomBar(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Photo gallery — mobile (horizontal scroll) ────────────────────────────
  Widget _imageGallery() => SizedBox(
    height: 160,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: h.imageUrls.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder:
          (context, i) => GestureDetector(
            onTap: () => _openImageViewer(context, h.imageUrls, i),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: h.imageUrls[i],
                width: 200,
                height: 160,
                fit: BoxFit.cover,
                placeholder:
                    (_, __) => Container(
                      width: 200,
                      height: 160,
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFF47C20),
                        ),
                      ),
                    ),
                errorWidget:
                    (_, __, ___) => Container(
                      width: 200,
                      height: 160,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
              ),
            ),
          ),
    ),
  );

  // ── Photo gallery — web (wrap grid) ──────────────────────────────────────
  Widget _imageGalleryWeb() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (int i = 0; i < h.imageUrls.length; i++)
          GestureDetector(
            onTap: () => _openImageViewer(context, h.imageUrls, i),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: h.imageUrls[i],
                width: 180,
                height: 130,
                fit: BoxFit.cover,
                placeholder:
                    (_, __) => Container(
                      width: 180,
                      height: 130,
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFF47C20),
                        ),
                      ),
                    ),
                errorWidget:
                    (_, __, ___) => Container(
                      width: 180,
                      height: 130,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Details card ──────────────────────────────────────────────────────────
  Widget _detailsCard() => _infoCard(
    children: [
      _detailRow(Icons.groups, 'Capacity', h.capacityLabel),
      const SizedBox(height: 12),
      _detailRow(Icons.payments, 'Price Per Event', h.priceLabel),
      if (h.description.isNotEmpty) ...[
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DESCRIPTION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500],
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                h.description,
                style: const TextStyle(height: 1.5, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    ],
  );

  // ── Banking card ──────────────────────────────────────────────────────────
  Widget _bankingCard() => _infoCard(
    children: [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance,
              color: Colors.teal.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _labelRow('Bank', h.bankName.isNotEmpty ? h.bankName : '—'),
                const SizedBox(height: 8),
                _labelRow(
                  'Account Number',
                  h.bankAccountNumber.isNotEmpty ? h.bankAccountNumber : '—',
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  );

  // ── Bottom approve/reject bar ─────────────────────────────────────────────
  Widget _bottomBar(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, -5),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed:
                  () => AppNavigation.push(
                    context,
                    RejectRegistrationScreen(hallId: h.hallId),
                  ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFD92D20)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                foregroundColor: const Color(0xFFD92D20),
              ),
              child: const Text(
                'Reject',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isApproving ? null : _approve,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF47C20),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  _isApproving
                      ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                      : const Text(
                        'Approve',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
            ),
          ),
        ),
      ],
    ),
  );

  // ── Documents ─────────────────────────────────────────────────────────────
  Widget _buildDocuments() {
    final docs = <Map<String, String>>[];
    if (h.cnicFrontUrl.isNotEmpty) {
      docs.add({
        'label': 'CNIC — Front Side',
        'url': h.cnicFrontUrl,
        'type': 'image',
      });
    }
    if (h.cnicBackUrl.isNotEmpty) {
      docs.add({
        'label': 'CNIC — Back Side',
        'url': h.cnicBackUrl,
        'type': 'image',
      });
    }
    if (h.ntnDocUrl.isNotEmpty) {
      docs.add({
        'label': 'NTN Document',
        'url': h.ntnDocUrl,
        'type': _docType(h.ntnDocUrl),
      });
    }
    if (h.businessLicenseUrl.isNotEmpty) {
      docs.add({
        'label': 'Business License',
        'url': h.businessLicenseUrl,
        'type': _docType(h.businessLicenseUrl),
      });
    }

    if (docs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.amber[700],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'No documents uploaded.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      children:
          docs
              .map(
                (doc) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DocumentTile(
                    label: doc['label']!,
                    url: doc['url']!,
                    type: doc['type']!,
                    onTap:
                        () =>
                            doc['type'] == 'pdf'
                                ? _openPdfViewer(
                                  context,
                                  doc['url']!,
                                  doc['label']!,
                                )
                                : _openImageViewer(context, [doc['url']!], 0),
                  ),
                ),
              )
              .toList(),
    );
  }

  String _docType(String url) {
    final lower = url.toLowerCase();
    return (lower.contains('.pdf') || lower.contains('pdf')) ? 'pdf' : 'image';
  }

  void _openImageViewer(BuildContext context, List<String> urls, int initial) =>
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _ImageViewerScreen(urls: urls, initialIndex: initial),
        ),
      );

  void _openPdfViewer(BuildContext context, String url, String title) =>
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _PdfViewerScreen(url: url, title: title),
        ),
      );

  // ── Widget helpers ─────────────────────────────────────────────────────────
  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12, left: 4),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    ),
  );

  Widget _infoCard({required List<Widget> children}) => Container(
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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );

  Widget _labelRow(String label, String value, {bool isLarge = false}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isLarge ? 18 : 15,
              fontWeight: isLarge ? FontWeight.bold : FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      );

  Widget _divider() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Divider(height: 1, color: Colors.grey[200]),
  );

  Widget _detailRow(IconData icon, String label, String value) => Row(
    children: [
      Icon(icon, size: 20, color: Colors.grey[400]),
      const SizedBox(width: 12),
      Text('$label: ', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

// ── Document tile ─────────────────────────────────────────────────────────
class _DocumentTile extends StatelessWidget {
  final String label, url, type;
  final VoidCallback onTap;
  const _DocumentTile({
    required this.label,
    required this.url,
    required this.type,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPdf = type == 'pdf';
    final iconClr = isPdf ? Colors.red : Colors.blue;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8),
          ],
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconClr.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPdf ? Icons.picture_as_pdf : Icons.image_outlined,
              color: iconClr,
              size: 24,
            ),
          ),
          title: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            isPdf ? 'Tap to view PDF' : 'Tap to view image',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF47C20).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.visibility_outlined,
                  color: Color(0xFFF47C20),
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  'View',
                  style: TextStyle(
                    color: Color(0xFFF47C20),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Full-screen image viewer ─────────────────────────────────────────────
class _ImageViewerScreen extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  const _ImageViewerScreen({required this.urls, required this.initialIndex});

  @override
  State<_ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<_ImageViewerScreen> {
  late PageController _pageCtrl;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        '${_currentIndex + 1} / ${widget.urls.length}',
        style: const TextStyle(color: Colors.white),
      ),
      centerTitle: true,
    ),
    body: PageView.builder(
      controller: _pageCtrl,
      itemCount: widget.urls.length,
      onPageChanged: (i) => setState(() => _currentIndex = i),
      itemBuilder:
          (context, i) => InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.urls[i],
                fit: BoxFit.contain,
                placeholder:
                    (_, __) => const CircularProgressIndicator(
                      color: Color(0xFFF47C20),
                    ),
                errorWidget:
                    (_, __, ___) => const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                          size: 64,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Image failed to load',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
              ),
            ),
          ),
    ),
  );
}

// ── PDF viewer ──────────────────────────────────────────────────────────────
class _PdfViewerScreen extends StatelessWidget {
  final String url, title;
  const _PdfViewerScreen({required this.url, required this.title});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
        overflow: TextOverflow.ellipsis,
      ),
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.picture_as_pdf,
                color: Colors.white,
                size: 72,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'PDF Document',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
            const SizedBox(height: 32),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _launch(context, url),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF47C20),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.open_in_new, color: Colors.white),
                  label: const Text(
                    'Open PDF',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Opens in your device\'s PDF viewer or browser',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _launch(BuildContext context, String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open PDF: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
