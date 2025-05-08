import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io' show Platform;
import '../providers/activity_provider.dart';
import '../providers/navigation_provider.dart';
import '../services/accident_detection_service.dart';
import 'map_screen.dart';
import 'notifications_screen.dart';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  String _currentLocation = "Fetching location...";
  String _currentDate = "";
  double _currentSpeed = 0.0;
  List<double> _speedHistory = [];
  StreamSubscription<Position>? _positionStream;
  String _userName = "User";
  String _firstName = "User";
  Position? _lastPosition;
  String? _emergencyContactNumber;
  String? _userId;
  String _countryCode = 'UNKNOWN';
  LatLng? _mapCenter;
  AccidentDetectionService? _accidentDetectionService;

  Future<void> _loadEmergencyContactFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = prefs.getStringList('emergencyContacts');
    if (contactsJson != null && contactsJson.isNotEmpty) {
      final Map<String, String> contact = Map<String, String>.from(
        jsonDecode(contactsJson.first),
      );
      setState(() {
        _emergencyContactNumber = contact['phone'];
      });
    }
  }

  final Map<String, Map<String, String>> _emergencyNumbers = {
    'EG': {
      'Ambulance': '123',
      'Police': '122',
      'Medical Consultations': '+20123456789',
      'Nearest Hospital': '01047500896',
    },
    'US': {
      'Ambulance': '911',
      'Police': '911',
      'Medical Consultations': '+18002352777',
      'Nearest Hospital': '+18005551234',
    },
    'SA': {
      'Ambulance': '997',
      'Police': '999',
      'Medical Consultations': '+96612345678',
      'Nearest Hospital': '+96698765432',
    },
    'UNKNOWN': {
      'Ambulance': 'Not available',
      'Police': 'Not available',
      'Medical Consultations': 'Not available',
      'Nearest Hospital': 'Not available',
    },
  };

  @override
  void initState() {
    super.initState();
    _initializeUserId();
    _setCurrentDate();
    _startTrackingSpeedAndDistance();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _accidentDetectionService?.stopAccidentDetection();
    super.dispose();
  }

  Future<void> _initializeUserId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _userId = user.uid;
        });
        await _loadUserInfo();
        await _getCurrentLocation();
        await _loadEmergencyContactFromCache();
        _accidentDetectionService = AccidentDetectionService(
          userId: _userId,
          context: context,
        );
        _accidentDetectionService?.startAccidentDetection();
      } else {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("User not logged in")));
          });
        }
      }
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Failed to initialize user ID',
      );
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to initialize user: $e")),
          );
        });
      }
    }
  }

  Future<void> _loadUserInfo() async {
    if (_userId == null) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final displayName = user.displayName ?? 'User';
        setState(() {
          _userName = displayName;
          _firstName = _userName.split(' ').first;
          if (_firstName.isNotEmpty) {
            _firstName =
                _firstName[0].toUpperCase() +
                _firstName.substring(1).toLowerCase();
          }
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', displayName);
      }
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Failed to load user info',
      );
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to load user info: $e")),
          );
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentLocation = "Location services disabled";
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentLocation = "Location permission denied";
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentLocation = "Location permission permanently denied";
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final prefs = await SharedPreferences.getInstance();
      String? cachedCountryCode = prefs.getString('country_code');

      if (cachedCountryCode == null) {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          String? countryCode = placemarks.first.isoCountryCode;
          setState(() {
            _countryCode = countryCode ?? 'UNKNOWN';
          });
          await prefs.setString('country_code', _countryCode);
        } catch (e) {
          String localeCountryCode = Platform.localeName.split('_').last;
          setState(() {
            _countryCode =
                _emergencyNumbers.containsKey(localeCountryCode)
                    ? localeCountryCode
                    : 'UNKNOWN';
          });
          await prefs.setString('countryCode', _countryCode);
        }
      } else {
        setState(() {
          _countryCode = cachedCountryCode;
        });
      }

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String locationName = "";
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          locationName = "${place.subLocality}, ${place.locality}";
        } else if (place.locality != null && place.locality!.isNotEmpty) {
          locationName = "${place.locality}, ${place.administrativeArea}";
        } else if (place.country != null && place.country!.isNotEmpty) {
          locationName = place.country!;
        } else {
          locationName =
              "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
        }

        setState(() {
          _currentLocation = locationName;
          _lastPosition = position;
          _mapCenter = LatLng(position.latitude, position.longitude);
          _accidentDetectionService?.updatePosition(position);
        });
      } else {
        setState(() {
          _currentLocation =
              "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
          _lastPosition = position;
          _mapCenter = LatLng(position.latitude, position.longitude);
          _accidentDetectionService?.updatePosition(position);
        });
      }
    } catch (e) {
      setState(() {
        _currentLocation = "Failed to fetch location: $e";
      });
    }
  }

  void _setCurrentDate() {
    final now = DateTime.now();
    setState(() {
      _currentDate = DateFormat('EEEE, d MMMM yyyy').format(now);
    });
  }

  void _startTrackingSpeedAndDistance() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    final activityProvider = Provider.of<ActivityProvider>(
      context,
      listen: false,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        double newSpeed = position.speed * 3.6;
        _speedHistory.add(newSpeed);
        if (_speedHistory.length > 5) _speedHistory.removeAt(0);
        double avgSpeed =
            _speedHistory.reduce((a, b) => a + b) / _speedHistory.length;

        if (_lastUpdate == null ||
            DateTime.now().difference(_lastUpdate!) >
                const Duration(milliseconds: 500)) {
          setState(() {
            _currentSpeed = avgSpeed;
            _mapCenter = LatLng(position.latitude, position.longitude);
          });
          _lastUpdate = DateTime.now();
        }

        _accidentDetectionService?.updatePosition(position); // تمرير الوضعية
        activityProvider.updateMaxSpeed(avgSpeed);

        if (_lastPosition != null) {
          double distanceInMeters = Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            position.latitude,
            position.longitude,
          );
          double distanceInKm = distanceInMeters / 1000;
          activityProvider.updateDistance(distanceInKm, avgSpeed);
        }

        _lastPosition = position;
      },
      onError: (error) {
        FirebaseCrashlytics.instance.recordError(
          error,
          StackTrace.current,
          reason: 'Location stream error',
        );
        setState(() {
          _currentSpeed = 0.0;
        });
        activityProvider.updateDistance(0.0, 0.0);
      },
    );
  }

  DateTime? _lastUpdate;

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber == 'Not available' || phoneNumber.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Service not available in this country"),
          ),
        );
      }
      return;
    }
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Could not launch phone dialer. Please check your device.",
              ),
            ),
          );
        }
      }
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Failed to make phone call',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to make phone call: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.favorite, color: Colors.blue),
                          const SizedBox(width: 5),
                          const Text(
                            "AARS",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.notifications,
                          color: Colors.blue,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap:
                        _currentLocation.contains("Fetching") ||
                                _lastPosition == null
                            ? null
                            : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => MapScreen(
                                        latitude: _lastPosition!.latitude,
                                        longitude: _lastPosition!.longitude,
                                      ),
                                ),
                              );
                            },
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.blue,
                          size: 16,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child:
                              _currentLocation.contains("Fetching")
                                  ? const Row(
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        "Fetching location...",
                                        style: TextStyle(color: Colors.blue),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  )
                                  : Text(
                                    _currentLocation,
                                    style: const TextStyle(color: Colors.blue),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.blue),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Search",
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 20),
                  RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: "Welcome, ",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: "$_firstName!",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _currentDate,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final ambulanceNumber =
                                _emergencyNumbers[_countryCode]?['Ambulance'] ??
                                'Not available';
                            if (ambulanceNumber != 'Not available') {
                              await _makePhoneCall(ambulanceNumber);
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Ambulance number not available in your country",
                                    ),
                                  ),
                                );
                              }
                            }
                            Provider.of<ActivityProvider>(
                              context,
                              listen: false,
                            ).addActivity(
                              "Requested help at ${DateFormat('hh:mm a').format(DateTime.now())}",
                              'help_request',
                            );
                            Provider.of<NavigationProvider>(
                              context,
                              listen: false,
                            ).setSelectedIndex(2);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE3F2FD),
                            foregroundColor: Colors.black,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.pan_tool, color: Colors.blue),
                              SizedBox(width: 10),
                              Text(
                                "Request Help",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE3F2FD),
                            foregroundColor: Colors.black,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.speed, color: Colors.blue),
                              const SizedBox(width: 10),
                              Text(
                                "${_currentSpeed.toStringAsFixed(1)} km/h",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                "Live",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Your Location",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child:
                        _mapCenter == null
                            ? const Center(child: CircularProgressIndicator())
                            : GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                if (_lastPosition != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => MapScreen(
                                            latitude: _lastPosition!.latitude,
                                            longitude: _lastPosition!.longitude,
                                          ),
                                    ),
                                  );
                                }
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: AbsorbPointer(
                                  child: GoogleMap(
                                    initialCameraPosition: CameraPosition(
                                      target: LatLng(
                                        _mapCenter!.latitude,
                                        _mapCenter!.longitude,
                                      ),
                                      zoom: 15.0,
                                    ),
                                    markers: {
                                      Marker(
                                        markerId: const MarkerId(
                                          'current_location',
                                        ),
                                        position: LatLng(
                                          _mapCenter!.latitude,
                                          _mapCenter!.longitude,
                                        ),
                                        icon:
                                            BitmapDescriptor.defaultMarkerWithHue(
                                              BitmapDescriptor.hueRed,
                                            ),
                                      ),
                                    },
                                    zoomGesturesEnabled: false,
                                    scrollGesturesEnabled: false,
                                    rotateGesturesEnabled: false,
                                    tiltGesturesEnabled: false,
                                  ),
                                ),
                              ),
                            ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Quick Services",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuickService(
                        _emergencyNumbers[_countryCode]!['Ambulance']!,
                        "Ambulance",
                        Icons.local_hospital,
                        () => _makePhoneCall(
                          _emergencyNumbers[_countryCode]!['Ambulance']!,
                        ),
                      ),
                      _buildQuickService(
                        _emergencyNumbers[_countryCode]!['Police']!,
                        "Police",
                        Icons.local_police,
                        () => _makePhoneCall(
                          _emergencyNumbers[_countryCode]!['Police']!,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuickService(
                        _emergencyContactNumber ?? 'No contact set',
                        "Emergency Contact",
                        Icons.contact_phone,
                        () {
                          if (_emergencyContactNumber != null &&
                              _emergencyContactNumber!.isNotEmpty) {
                            _makePhoneCall(_emergencyContactNumber!);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("No emergency contact set"),
                              ),
                            );
                          }
                        },
                      ),
                      _buildQuickService(
                        _emergencyNumbers[_countryCode]!['Nearest Hospital']!,
                        "Nearest Hospital",
                        Icons.local_hospital_outlined,
                        () => _makePhoneCall(
                          _emergencyNumbers[_countryCode]!['Nearest Hospital']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_accidentDetectionService != null)
              ValueListenableBuilder<AccidentAlertState>(
                valueListenable: _accidentDetectionService!.alertState,
                builder: (context, state, child) {
                  if (state == AccidentAlertState.detected) {
                    return AlertBanner(
                      accidentDetectionService: _accidentDetectionService!,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickService(
    String number,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(number, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.grey, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AlertBanner extends StatefulWidget {
  final AccidentDetectionService accidentDetectionService;

  const AlertBanner({super.key, required this.accidentDetectionService});

  @override
  State<AlertBanner> createState() => _AlertBannerState();
}

class _AlertBannerState extends State<AlertBanner> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: widget.accidentDetectionService.alertCountdown,
      builder: (context, countdown, child) {
        print('AlertBanner countdown: $countdown'); // Debug log
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "Accident detected! Sending alert in $countdown seconds...",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    widget.accidentDetectionService.cancelAlert();
                  },
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
