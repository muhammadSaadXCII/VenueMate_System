import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:venuemate_system/Models/hall_model.dart';
import 'package:venuemate_system/Services/hall_service.dart';
import 'package:venuemate_system/Utils/app_navigation.dart';
import 'VenueDetailScreen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  final TextEditingController _searchCtrl = TextEditingController();

  static const LatLng _defaultPos = LatLng(24.8607, 67.0104);

  LatLng _initialPos = _defaultPos;
  bool _locationReady = false;

  List<HallModel> _allHalls = [];
  List<HallModel> _filteredHalls = [];
  HallModel? _selectedHall;

  final Map<String, BitmapDescriptor> _markerIcons = {};

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
    _loadHalls();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── DRAWING THE PIN + HOVERING TEXT ──────────────────────────────────────
  Future<BitmapDescriptor> createCustomMarker(String title) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = Colors.orange;

    // 1. Setup Text Painter
    final textPainter = TextPainter(
      text: TextSpan(
        text: title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24, // Adjust for readability
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // 2. Dimensions
    const double pinRadius = 22.0;
    const double pinTipHeight = 18.0;
    const double labelPadding = 12.0;
    const double gapBetweenPinAndLabel = 10.0;

    double labelWidth = textPainter.width + (labelPadding * 2);
    double labelHeight = textPainter.height + labelPadding;

    // Calculate total canvas size
    // Width is the larger of the label or the pin head
    double canvasWidth =
        labelWidth > (pinRadius * 2) ? labelWidth : (pinRadius * 2);
    // Height is Label + Gap + Pin Circle + Pin Tip
    double canvasHeight =
        labelHeight + gapBetweenPinAndLabel + (pinRadius * 2) + pinTipHeight;

    // 3. Draw the Label (Hovering Box)
    final labelRect = RRect.fromLTRBR(
      (canvasWidth - labelWidth) / 2,
      0,
      (canvasWidth + labelWidth) / 2,
      labelHeight,
      const Radius.circular(8),
    );
    canvas.drawRRect(labelRect, paint);

    // Paint the text inside the label
    textPainter.paint(
      canvas,
      Offset((canvasWidth - textPainter.width) / 2, labelPadding / 2),
    );

    // 4. Draw the Actual Pin Icon (below the label)
    double pinCenterX = canvasWidth / 2;
    double pinCenterY = labelHeight + gapBetweenPinAndLabel + pinRadius;

    // Draw Pin Circle
    canvas.drawCircle(Offset(pinCenterX, pinCenterY), pinRadius, paint);
    // Draw white inner dot for a realistic pin look
    canvas.drawCircle(
      Offset(pinCenterX, pinCenterY),
      pinRadius / 2.5,
      Paint()..color = Colors.white,
    );

    // Draw Pin Tip (Triangle)
    final path = Path();
    path.moveTo(pinCenterX - pinRadius, pinCenterY + (pinRadius * 0.5));
    path.lineTo(pinCenterX, canvasHeight); // Bottom tip point
    path.lineTo(pinCenterX + pinRadius, pinCenterY + (pinRadius * 0.5));
    path.close();
    canvas.drawPath(path, paint);

    // 5. Output to Bitmap
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      canvasWidth.toInt(),
      canvasHeight.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _generateIconsForHalls(List<HallModel> halls) async {
    for (var h in halls) {
      if (!_markerIcons.containsKey(h.hallId)) {
        final icon = await createCustomMarker(h.hallName);
        if (mounted) {
          setState(() {
            _markerIcons[h.hallId] = icon;
          });
        }
      }
    }
  }

  Future<void> _fetchUserLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied)
        perm = await Geolocator.requestPermission();

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _initialPos = LatLng(pos.latitude, pos.longitude);
          _locationReady = true;
        });
        final ctrl = await _mapController.future;
        ctrl.animateCamera(CameraUpdate.newLatLngZoom(_initialPos, 13));
      }
    } catch (_) {
      if (mounted) setState(() => _locationReady = true);
    }
  }

  Future<void> _loadHalls() async {
    HallService.streamApprovedHalls().listen((halls) {
      if (!mounted) return;
      setState(() {
        _allHalls = halls;
        _filteredHalls = halls;
      });
      _generateIconsForHalls(halls);
    });
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filteredHalls =
          q.isEmpty
              ? _allHalls
              : _allHalls
                  .where((h) => h.hallName.toLowerCase().contains(q))
                  .toList();
      _selectedHall = null;
    });
    _generateIconsForHalls(_filteredHalls);
  }

  Set<Marker> _buildMarkers() {
    return _filteredHalls
        .where((h) => h.latitude != 0.0 || h.longitude != 0.0)
        .map(
          (h) => Marker(
            markerId: MarkerId(h.hallId),
            position: LatLng(h.latitude, h.longitude),
            icon:
                _markerIcons[h.hallId] ??
                BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange,
                ),
            anchor: const Offset(
              0.5,
              1.0,
            ), // Important: anchors tip of pin to location
            onTap: () async {
              setState(() => _selectedHall = h);
              final ctrl = await _mapController.future;
              ctrl.animateCamera(
                CameraUpdate.newLatLng(LatLng(h.latitude, h.longitude)),
              );
            },
          ),
        )
        .toSet();
  }

  Future<void> _viewDirections({required LatLng hallCords}) async {
    try {
      Position userCords = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final String url =
          'https://www.google.com/maps/dir/?api=1&origin=${userCords.latitude},${userCords.longitude}&destination=${hallCords.latitude},${hallCords.longitude}&travelmode=driving';
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri))
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialPos,
              zoom: 13,
            ),
            onMapCreated: (ctrl) => _mapController.complete(ctrl),
            markers: _buildMarkers(),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onTap: (_) => setState(() => _selectedHall = null),
          ),

          // Search Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Search halls...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Hall card popup
          if (_selectedHall != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: _HallCard(
                hall: _selectedHall!,
                onClose: () => setState(() => _selectedHall = null),
                onViewDirections:
                    () => _viewDirections(
                      hallCords: LatLng(
                        _selectedHall!.latitude,
                        _selectedHall!.longitude,
                      ),
                    ),
                onViewDetails:
                    () => AppNavigation.push(
                      context,
                      VenueDetailsScreen(hallId: _selectedHall!.hallId),
                    ),
              ),
            ),

          // My location FAB
          Positioned(
            right: 16,
            bottom: _selectedHall != null ? 200 : 32,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              shape: const CircleBorder(),
              onPressed: _fetchUserLocation,
              child: const Icon(Icons.my_location, color: Color(0xFFF47C20)),
            ),
          ),
        ],
      ),
    );
  }
}

// Keep your _HallCard class exactly as it was.
class _HallCard extends StatelessWidget {
  final HallModel hall;
  final VoidCallback onClose;
  final VoidCallback onViewDirections;
  final VoidCallback onViewDetails;

  const _HallCard({
    required this.hall,
    required this.onClose,
    required this.onViewDirections,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final img = hall.imageUrls.isNotEmpty ? hall.imageUrls.first : '';

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                GestureDetector(
                  onTap: onViewDetails,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child:
                        img.isNotEmpty
                            ? CachedNetworkImage(
                              imageUrl: img,
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder:
                                  (_, __) => Container(
                                    height: 140,
                                    color: Colors.grey[200],
                                  ),
                              errorWidget:
                                  (_, __, ___) => const Icon(Icons.business),
                            )
                            : Container(
                              height: 140,
                              color: Colors.grey[200],
                              child: const Icon(Icons.business),
                            ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        Text(
                          hall.ratingCount == 0
                              ? 'New'
                              : hall.ratingAvg.toStringAsFixed(1),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onClose,
                    child: const CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 12,
                      child: Icon(Icons.close, size: 16),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hall.hallName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    hall.address,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: onViewDirections,
              icon: const Icon(Icons.directions, color: Color(0xFFF47C20)),
              label: const Text(
                'View Directions',
                style: TextStyle(color: Color(0xFFF47C20)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
