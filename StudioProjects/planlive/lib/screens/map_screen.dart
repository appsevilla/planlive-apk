import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required LatLng latLng});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> _markers = {};
  LatLng? _currentPosition;
  bool _loading = true;
  String? _error;
  String _selectedFilter = 'Todos';

  final List<String> _categories = ['Todos', 'Fiesta', 'Comida', 'Concierto'];

  @override
  void initState() {
    super.initState();
    _solicitarPermisosYUbicacion();
  }

  Future<void> _solicitarPermisosYUbicacion() async {
    final status = await Permission.location.request();

    if (status.isGranted) {
      _getUserLocation();
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
      setState(() {
        _currentPosition = const LatLng(40.4168, -3.7038); // fallback a Madrid
      });
      _loadPlanMarkers();
    } else {
      setState(() {
        _currentPosition = const LatLng(40.4168, -3.7038); // fallback a Madrid
      });
      _loadPlanMarkers();
    }
  }

  Future<void> _getUserLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(pos.latitude, pos.longitude);
      });
    } catch (e) {
      setState(() {
        _currentPosition = const LatLng(40.4168, -3.7038);
        _error = 'Error al obtener la ubicación: $e';
      });
    }

    _loadPlanMarkers();
  }

  Future<void> _loadPlanMarkers() async {
    try {
      setState(() {
        _loading = true;
        _markers.clear();
      });

      final snapshot =
      await FirebaseFirestore.instance.collection('plans').get();

      final loadedMarkers = snapshot.docs.map((doc) {
        final data = doc.data();
        final lat = data['latitude'];
        final lng = data['longitude'];
        final title = data['title'] ?? 'Sin título';
        final description = data['description'] ?? '';
        final tipo = data['tipo'] ?? 'Otro';

        if (lat is! num || lng is! num) return null;
        if (_selectedFilter != 'Todos' && tipo != _selectedFilter) return null;

        return Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(lat.toDouble(), lng.toDouble()),
          infoWindow: InfoWindow(
            title: title,
            snippet: description.length > 60
                ? '${description.substring(0, 60)}...'
                : description,
          ),
        );
      }).whereType<Marker>().toSet();

      if (mounted) {
        setState(() {
          _markers.addAll(loadedMarkers);
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error al cargar los planes: $e';
        _loading = false;
      });
    }
  }

  Future<void> _goToCurrentLocation() async {
    if (_currentPosition == null) return;
    final controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(_currentPosition!, 14));
  }

  @override
  Widget build(BuildContext context) {
    final CameraPosition initialCamera = CameraPosition(
      target: _currentPosition ?? const LatLng(40.4168, -3.7038),
      zoom: 12,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planes en el mapa'),
        leading: Navigator.canPop(context)
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        )
            : null,
        actions: [
          DropdownButton<String>(
            value: _selectedFilter,
            dropdownColor: Colors.white,
            underline: const SizedBox(),
            onChanged: (value) {
              setState(() {
                _selectedFilter = value!;
              });
              _loadPlanMarkers();
            },
            items: _categories
                .map((cat) => DropdownMenuItem(
              value: cat,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(cat),
              ),
            ))
                .toList(),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: initialCamera,
            markers: _markers,
            onMapCreated: (controller) => _controller.complete(controller),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Material(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToCurrentLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
