import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:venuemate_system/Widgets/common_button.dart';

class LocationPickerSheet extends StatefulWidget {
  /// Pass the previously confirmed position to restore it on re-open.
  /// Leave null on the very first open — the map will auto-jump to GPS.
  final LatLng? initialPosition;

  const LocationPickerSheet({super.key, this.initialPosition});

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  GoogleMapController? _mapController;

  static const LatLng _defaultPosition = LatLng(24.8607, 67.0104);

  late LatLng _pickedLatLng;
  LatLng? _lastFetchedLatLng; // guard — prevents fetching same coords twice
  String _address = 'Move the map to pick a location';
  bool _isFetchingAddress = false;
  bool _isLocating = false;
  bool _hasConfirmedOnce = false; // enables Confirm after first user move

  // Geoapify key — used only on web (mobile uses the geocoding package)
  final String _geoapifyApiKey = "732c01a16f5c4f2fb95d8e1d9ff70ed2";

  @override
  void initState() {
    super.initState();
    if (widget.initialPosition != null) {
      // Re-open: restore the previously confirmed position.
      // _hasConfirmedOnce = true so Confirm is immediately enabled.
      _pickedLatLng = widget.initialPosition!;
      _hasConfirmedOnce = true;
    } else {
      // First open: start at default, then auto-jump to user's GPS.
      _pickedLatLng = _defaultPosition;
      // _goToMyLocation() is called after the map is ready (in onMapCreated).
    }
  }

  // ── Camera move — track centre LatLng ─────────────────────────────────────
  void _onCameraMove(CameraPosition position) {
    _pickedLatLng = position.target;
  }

  // ── Camera idle — reverse geocode the current centre ──────────────────────
  Future<void> _onCameraIdle() async {
    // Skip if coords haven't changed since the last fetch
    if (_lastFetchedLatLng != null &&
        _lastFetchedLatLng!.latitude == _pickedLatLng.latitude &&
        _lastFetchedLatLng!.longitude == _pickedLatLng.longitude) {
      return;
    }

    setState(() {
      _isFetchingAddress = true;
      _hasConfirmedOnce = true;
    });

    _lastFetchedLatLng = _pickedLatLng;

    String finalAddress = '';

    try {
      if (kIsWeb) {
        // Web: native geocoding package doesn't work — use Geoapify REST API
        final url = Uri.parse(
          'https://api.geoapify.com/v1/geocode/reverse'
          '?lat=${_pickedLatLng.latitude}'
          '&lon=${_pickedLatLng.longitude}'
          '&apiKey=$_geoapifyApiKey',
        );
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['features'] != null && data['features'].isNotEmpty) {
            finalAddress = data['features'][0]['properties']['formatted'] ?? '';
          }
        }
      } else {
        // Mobile: use the geocoding package
        final placemarks = await placemarkFromCoordinates(
          _pickedLatLng.latitude,
          _pickedLatLng.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = <String>[
            if (p.street != null && p.street!.isNotEmpty) p.street!,
            if (p.subLocality != null && p.subLocality!.isNotEmpty)
              p.subLocality!,
            if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
            if (p.administrativeArea != null &&
                p.administrativeArea!.isNotEmpty)
              p.administrativeArea!,
            if (p.country != null && p.country!.isNotEmpty) p.country!,
          ];
          if (parts.isNotEmpty) finalAddress = parts.join(', ');
        }
      }

      if (mounted) {
        setState(() {
          _address =
              finalAddress.isNotEmpty
                  ? finalAddress
                  : '${_pickedLatLng.latitude.toStringAsFixed(5)}, '
                      '${_pickedLatLng.longitude.toStringAsFixed(5)}';
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

  // ── "Locate me" button — explicitly requested by user ─────────────────────
  Future<void> _goToMyLocation() async {
    setState(() => _isLocating = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Please enable GPS in your device settings.');
        setState(() => _isLocating = false);
        return;
      }

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

      final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // animateCamera triggers onCameraMove + onCameraIdle automatically
      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(pos.latitude, pos.longitude), zoom: 16),
        ),
      );

      if (mounted) setState(() => _isLocating = false);
    } catch (_) {
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

  void _confirm() {
    Navigator.pop(context, {
      'address': _address,
      'lat': _pickedLatLng.latitude,
      'lng': _pickedLatLng.longitude,
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            // ── Handle + header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
              child: Column(
                children: [
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

            // ── Instruction strip ─────────────────────────────────────────────
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

            // ── Map ───────────────────────────────────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _pickedLatLng,
                      zoom: widget.initialPosition != null ? 16 : 14,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                      if (widget.initialPosition != null) {
                        // Re-open: animate to the saved position, then geocode it.
                        controller.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(
                              target: widget.initialPosition!,
                              zoom: 16,
                            ),
                          ),
                        );
                        // onCameraIdle will fire after the animation and geocode.
                      } else {
                        // First open: jump to user's GPS location.
                        _goToMyLocation();
                      }
                    },
                    onCameraMove: _onCameraMove,
                    onCameraIdle: _onCameraIdle,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    compassEnabled: true,
                    rotateGesturesEnabled: true,
                    scrollGesturesEnabled: true,
                    tiltGesturesEnabled: false,
                    zoomGesturesEnabled: true,
                    markers: const {},
                  ),

                  // Pin shadow
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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

                  // Pin icon
                  Center(
                    child: Transform.translate(
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

                  // Fetching indicator
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

                  // Zoom controls
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

                  // Locate me button
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

            // ── Bottom card — address + confirm ───────────────────────────────
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
                              '${_pickedLatLng.latitude.toStringAsFixed(5)}, ${_pickedLatLng.longitude.toStringAsFixed(5)}',
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
      ),
    );
  }

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
