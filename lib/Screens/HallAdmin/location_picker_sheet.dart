import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:venuemate_system/Widgets/common_button.dart';

class LocationPickerSheet extends StatefulWidget {
  const LocationPickerSheet({super.key});

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  // ── Map controller ─────────────────────────────────────────────────────────
  GoogleMapController? _mapController;

  // ── State ──────────────────────────────────────────────────────────────────
  // Default camera position — Karachi (Pakistan) as a sensible start
  static const LatLng _defaultPosition = LatLng(24.8607, 67.0104);

  LatLng _pickedLatLng = _defaultPosition;
  String _address = 'Move the map to pick a location';
  bool _isFetchingAddress = false; // shown while reverse-geocoding
  bool _isLocating = false; // shown while getting GPS
  bool _hasConfirmedOnce =
      false; // enables Confirm button after first camera move

  // ── Map camera idle callback → reverse geocode ─────────────────────────────
  Future<void> _onCameraIdle() async {
    // Don't reverse-geocode the very first idle before the user moves anything
    setState(() {
      _isFetchingAddress = true;
      _hasConfirmedOnce = true;
    });

    try {
      final placemarks = await placemarkFromCoordinates(
        _pickedLatLng.latitude,
        _pickedLatLng.longitude,
      );

      String address =
          '${_pickedLatLng.latitude.toStringAsFixed(5)}, '
          '${_pickedLatLng.longitude.toStringAsFixed(5)}';

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[
          if (p.street != null && p.street!.isNotEmpty) p.street!,
          if (p.subLocality != null && p.subLocality!.isNotEmpty)
            p.subLocality!,
          if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
          if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty)
            p.administrativeArea!,
          if (p.country != null && p.country!.isNotEmpty) p.country!,
        ];
        if (parts.isNotEmpty) address = parts.join(', ');
      }

      if (mounted) {
        setState(() {
          _address = address;
          _isFetchingAddress = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _address =
              '${_pickedLatLng.latitude.toStringAsFixed(5)}, '
              '${_pickedLatLng.longitude.toStringAsFixed(5)}';
          _isFetchingAddress = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _goToMyLocation();
  }

  // ── Camera move callback — track centre LatLng ────────────────────────────
  void _onCameraMove(CameraPosition position) {
    _pickedLatLng = position.target;
  }

  // ── "Locate me" — jump map to device GPS ──────────────────────────────────
  Future<void> _goToMyLocation() async {
    setState(() => _isLocating = true);

    try {
      // 1. Location services enabled?
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Please enable GPS in your device settings.');
        setState(() => _isLocating = false);
        return;
      }

      // 2. Permission
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _showSnack('Location permission is required.');
        setState(() => _isLocating = false);
        return;
      }

      // 3. Get position
      final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final LatLng myPos = LatLng(pos.latitude, pos.longitude);

      // 4. Animate camera to GPS position (triggers onCameraMove + onCameraIdle)
      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: myPos, zoom: 16)),
      );

      if (mounted) setState(() => _isLocating = false);
    } catch (e) {
      _showSnack('Could not get your location.');
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Confirm ────────────────────────────────────────────────────────────────
  void _confirm() {
    Navigator.pop(context, {
      'address': _address,
      'lat': _pickedLatLng.latitude,
      'lng': _pickedLatLng.longitude,
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // PopScope prevents the sheet from being dismissed by a back gesture.
    // The user must tap the X button or Confirm — not swipe down.
    return PopScope(
      canPop: true, // still allow back button — just not accidental drag
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            // ── Sheet handle + header ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
              child: Column(
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Location',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.black54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Instruction strip ─────────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4EC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFF47C20).withOpacity(0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Color(0xFFF47C20)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Drag the map to position the pin on your hall location.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFF47C20),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Map area ──────────────────────────────────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: _defaultPosition,
                      zoom: 14,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                      // Trigger initial reverse geocode
                      _onCameraIdle();
                    },
                    onCameraMove: _onCameraMove,
                    onCameraIdle: _onCameraIdle,

                    // Map settings
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false, // We use our own button
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    compassEnabled: true,
                    rotateGesturesEnabled: true,
                    scrollGesturesEnabled: true,
                    tiltGesturesEnabled: false,
                    zoomGesturesEnabled: true,

                    // No markers — the fixed pin IS the marker
                    markers: const {},
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pin shadow
                        Container(
                          width: 12,
                          height: 4,
                          margin: const EdgeInsets.only(top: 44),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: Transform.translate(
                      // Shift pin up so its TIP (bottom point) is at centre
                      offset: const Offset(0, -26),
                      child: Image.asset(
                        'assets/images/locationPin.png',
                        width: 52,
                        height: 52,
                        errorBuilder:
                            (_, __, ___) => const Icon(
                              Icons.location_on,
                              size: 52,
                              color: Color(0xFFF47C20),
                            ),
                      ),
                    ),
                  ),

                  // ── Fetching address indicator (top centre) ───────────────────────
                  if (_isFetchingAddress)
                    Positioned(
                      top: 12,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Fetching address...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // ── Zoom controls (right side) ────────────────────────────────────
                  Positioned(
                    right: 12,
                    bottom: 90,
                    child: Column(
                      children: [
                        _mapButton(
                          Icons.add,
                          () => _mapController?.animateCamera(
                            CameraUpdate.zoomIn(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _mapButton(
                          Icons.remove,
                          () => _mapController?.animateCamera(
                            CameraUpdate.zoomOut(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── My Location button ────────────────────────────────────────────
                  Positioned(
                    right: 12,
                    bottom: 16,
                    child: GestureDetector(
                      onTap: _isLocating ? null : _goToMyLocation,
                      child: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child:
                            _isLocating
                                ? const Padding(
                                  padding: EdgeInsets.all(13),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Color(0xFFF47C20),
                                  ),
                                )
                                : const Icon(
                                  Icons.my_location,
                                  color: Color(0xFFF47C20),
                                  size: 24,
                                ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Bottom card — address + confirm ───────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Label
                  const Text(
                    'Selected Location',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Address row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF47C20).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Color(0xFFF47C20),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isFetchingAddress
                                  ? 'Fetching address...'
                                  : _address,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color:
                                    _isFetchingAddress
                                        ? Colors.grey
                                        : Colors.black87,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_pickedLatLng.latitude.toStringAsFixed(5)}, '
                              '${_pickedLatLng.longitude.toStringAsFixed(5)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Confirm button
                  CommonButton(
                    text: 'Confirm Location',
                    onTap:
                        (_hasConfirmedOnce && !_isFetchingAddress)
                            ? _confirm
                            : () => _showSnack(
                              'Move the map to select a location first.',
                            ),
                  ),

                  SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
                ],
              ),
            ),
          ],
        ),
      ), // closes outer GestureDetector
    ); // closes PopScope
  }

  // ── Small square map control button ───────────────────────────────────────
  Widget _mapButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.black87, size: 22),
      ),
    );
  }
}
