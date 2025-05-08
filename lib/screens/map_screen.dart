import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../providers/activity_provider.dart';

class MapScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double? initialZoom;
  final Set<Marker>? additionalMarkers;
  final MapType? initialMapType;
  final bool showZoomControls;
  final bool showMyLocationButton;
  final bool showMapTypeButton;
  final String? markerTitle;
  final ValueChanged<LatLng>? onMapTap;
  final ValueChanged<Marker>? onMarkerTap;

  const MapScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    this.initialZoom = 15.0,
    this.additionalMarkers,
    this.initialMapType = MapType.normal,
    this.showZoomControls = true,
    this.showMyLocationButton = true,
    this.showMapTypeButton = true,
    this.markerTitle,
    this.onMapTap,
    this.onMarkerTap,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  late CameraPosition _initialCameraPosition;
  MapType _currentMapType = MapType.normal;
  bool _showZoomControls = true;
  bool _showMyLocationButton = true;
  double _currentZoom = 15.0;
  LatLng? _selectedLocation;
  final Set<Marker> _nearbyMarkers = {};
  final List<Map<String, dynamic>> _nearbyPlaces = [];

  @override
  void initState() {
    super.initState();
    _initialCameraPosition = CameraPosition(
      target: LatLng(widget.latitude, widget.longitude),
      zoom: widget.initialZoom ?? 15.0,
    );
    _currentZoom = widget.initialZoom ?? 15.0;
    _currentMapType = widget.initialMapType ?? MapType.normal;
    _showZoomControls = widget.showZoomControls;
    _showMyLocationButton = widget.showMyLocationButton;
  }

  Set<Marker> _getMarkers() {
    final markers = widget.additionalMarkers ?? <Marker>{};
    final provider = Provider.of<ActivityProvider>(context, listen: false);
    markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: LatLng(widget.latitude, widget.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: widget.markerTitle ?? 'Your Location',
          snippet:
              '${widget.latitude.toStringAsFixed(4)}, ${widget.longitude.toStringAsFixed(4)}',
        ),
        onTap:
            () => widget.onMarkerTap?.call(
              Marker(
                markerId: const MarkerId('current_location'),
                position: LatLng(widget.latitude, widget.longitude),
              ),
            ),
      ),
    );
    for (var activity in provider.recentActivities) {
      if (activity.type == 'accident' &&
          activity.latitude != null &&
          activity.longitude != null) {
        markers.add(
          Marker(
            markerId: MarkerId('accident_${activity.id}'),
            position: LatLng(activity.latitude!, activity.longitude!),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueYellow,
            ),
            infoWindow: const InfoWindow(title: 'Accident Location'),
          ),
        );
      }
    }
    markers.addAll(_nearbyMarkers);
    return markers;
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _goToCurrentLocation() async {
    await _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(widget.latitude, widget.longitude),
          zoom: _currentZoom,
        ),
      ),
    );
  }

  Future<void> _zoomIn() async {
    final newZoom = await _mapController.getZoomLevel();
    setState(() {
      _currentZoom = (newZoom + 1).clamp(0.0, 21.0);
    });
    await _mapController.animateCamera(CameraUpdate.zoomTo(_currentZoom));
  }

  Future<void> _zoomOut() async {
    final newZoom = await _mapController.getZoomLevel();
    setState(() {
      _currentZoom = (newZoom - 1).clamp(0.0, 21.0);
    });
    await _mapController.animateCamera(CameraUpdate.zoomTo(_currentZoom));
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType =
          _currentMapType == MapType.normal
              ? MapType.satellite
              : MapType.normal;
    });
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371;
    double dLat = (lat2 - lat1) * (pi / 180);
    double dLon = (lon2 - lon1) * (pi / 180);
    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) *
            cos(lat2 * (pi / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  Future<void> _openDirections(
    double destinationLat,
    double destinationLon,
  ) async {
    final String googleMapsUrl =
        'https://www.google.com/maps/dir/?api=1'
        '&origin=${widget.latitude},${widget.longitude}'
        '&destination=$destinationLat,$destinationLon'
        '&travelmode=driving';

    final Uri url = Uri.parse(googleMapsUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }

  Future<void> _fetchNearbyPlaces(String type) async {
    final String osmType = type == 'hospital' ? 'hospital' : 'police';
    final String query = '''
      [out:json];
      node(around:5000,${widget.latitude},${widget.longitude})["amenity"="$osmType"];
      out body;
    ''';

    const String overpassUrl = 'https://overpass-api.de/api/interpreter';

    try {
      final response = await http.post(Uri.parse(overpassUrl), body: query);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List<dynamic>;

        setState(() {
          _nearbyMarkers.clear();
          _nearbyPlaces.clear();
          for (var element in elements) {
            final lat = element['lat'] as double;
            final lon = element['lon'] as double;
            final name = element['tags']['name'] ?? 'Unnamed $type';
            final distance = _calculateDistance(
              widget.latitude,
              widget.longitude,
              lat,
              lon,
            );

            _nearbyPlaces.add({
              'name': name,
              'lat': lat,
              'lon': lon,
              'distance': distance,
            });

            _nearbyMarkers.add(
              Marker(
                markerId: MarkerId('${type}_${element['id']}'),
                position: LatLng(lat, lon),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  type == 'hospital'
                      ? BitmapDescriptor.hueBlue
                      : BitmapDescriptor.hueGreen,
                ),
                infoWindow: InfoWindow(
                  title: name,
                  snippet: type == 'hospital' ? 'Hospital' : 'Police Station',
                ),
              ),
            );
          }
          // ترتيب القائمة من الأقرب إلى الأبعد
          _nearbyPlaces.sort((a, b) => a['distance'].compareTo(b['distance']));
        });

        if (_nearbyPlaces.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No nearby $type found within 5km')),
          );
        } else {
          _showNearbyPlacesSheet(type);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch nearby places')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching places: $e')));
    }
  }

  void _showNearbyPlacesSheet(String type) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nearby ${type == 'hospital' ? 'Hospitals' : 'Police Stations'}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _nearbyPlaces.length,
                  itemBuilder: (context, index) {
                    final place = _nearbyPlaces[index];
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      color: Colors.white,
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                type == 'hospital'
                                    ? Colors.blue.withOpacity(0.1)
                                    : Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            type == 'hospital'
                                ? Icons.local_hospital
                                : Icons.local_police,
                            color:
                                type == 'hospital' ? Colors.blue : Colors.green,
                          ),
                        ),
                        title: Text(
                          place['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          'Distance: ${place['distance'].toStringAsFixed(2)} km',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.directions,
                            color: Colors.blueAccent,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _openDirections(place['lat'], place['lon']);
                          },
                        ),
                        onTap: () {
                          _mapController.animateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(
                                target: LatLng(place['lat'], place['lon']),
                                zoom: 15.0,
                              ),
                            ),
                          );
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // تغيير لون الخلفية إلى الأبيض
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: ShaderMask(
          shaderCallback:
              (bounds) => const LinearGradient(
                colors: [Colors.blue, Colors.lightBlueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
          child: const Text(
            'Map View',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // شريط خاص للمستشفيات ومراكز الشرطة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _fetchNearbyPlaces('hospital'),
                    icon: const Icon(Icons.local_hospital, color: Colors.white),
                    label: const Text('Hospitals'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _fetchNearbyPlaces('police'),
                    icon: const Icon(Icons.local_police, color: Colors.white),
                    label: const Text('Police Stations'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: _initialCameraPosition,
                  markers: _getMarkers(),
                  mapType: _currentMapType,
                  zoomControlsEnabled: false,
                  myLocationEnabled: _showMyLocationButton,
                  myLocationButtonEnabled: false,
                  onMapCreated: _onMapCreated,
                  onTap: (latLng) {
                    setState(() {
                      _selectedLocation = latLng;
                    });
                    widget.onMapTap?.call(latLng);
                  },
                  zoomGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  rotateGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  onCameraMove: (position) {
                    setState(() {
                      _currentZoom = position.zoom;
                    });
                  },
                ),
                if (_selectedLocation != null)
                  Positioned(
                    top: 60,
                    right: 20,
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Selected: ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_showMyLocationButton)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(25),
                              onTap: _goToCurrentLocation,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                child: const Icon(
                                  Icons.my_location,
                                  color: Colors.blueAccent,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(25),
                            onTap: _zoomIn,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              child: const Icon(
                                Icons.add,
                                color: Colors.blueAccent,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(25),
                            onTap: _zoomOut,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              child: const Icon(
                                Icons.remove,
                                color: Colors.blueAccent,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        if (widget.showMapTypeButton) ...[
                          const SizedBox(height: 8),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(25),
                              onTap: _toggleMapType,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                child: const Icon(
                                  Icons.layers,
                                  color: Colors.blueAccent,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
