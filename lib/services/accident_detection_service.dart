import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../providers/activity_provider.dart';

class AccidentDetectionService {
  final String? userId;
  final BuildContext context;
  Position? _currentPosition;
  double _currentSpeed = 0.0;
  bool _isTriggered = false;
  DateTime? _lastTrigger;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<Position>? _positionStream;
  final ValueNotifier<AccidentAlertState> alertState = ValueNotifier(
    AccidentAlertState.idle,
  );
  late ValueNotifier<int> alertCountdown;
  Timer? _alertTimer;
  Timer? _countdownTimer;

  final List<double> _accelerationHistory = [];
  final List<double> _rotationHistory = [];
  final List<double> _speedHistory = [];
  static const int historySize = 20;

  static const String twilioAccountSid = 'AC099fd96efdd99c714e3cf83553282397';
  static const String twilioAuthToken = '85a1e25a3322215d529ad05a7679d66d';
  static const String twilioWhatsAppNumber = 'whatsapp:+14155238886';

  AccidentDetectionService({required this.userId, required this.context}) {
    _initializeCountdown();
    _initializeLocationTracking();
  }

  Future<void> _initializeCountdown() async {
    final prefs = await SharedPreferences.getInstance();
    final countdownTime = prefs.getInt('countdown_time') ?? 10;
    alertCountdown = ValueNotifier(countdownTime);
  }

  Future<void> _initializeLocationTracking() async {
    if (!await _checkPermissions()) return;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) async {
        _currentPosition = position;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('last_latitude', position.latitude);
        await prefs.setDouble('last_longitude', position.longitude);
        updatePosition(position);
      },
      onError: (error) {
        FirebaseCrashlytics.instance.recordError(
          error,
          StackTrace.current,
          reason: 'Location stream error',
        );
      },
    );
  }

  void updatePosition(Position position) {
    _currentPosition = position;
    _currentSpeed = position.speed * 3.6;
    _speedHistory.add(_currentSpeed);
    if (_speedHistory.length > historySize) _speedHistory.removeAt(0);

    final activityProvider = Provider.of<ActivityProvider>(
      context,
      listen: false,
    );
    activityProvider.updateMaxSpeed(_currentSpeed);
    final distanceInKm = position.speed * (1 / 3600);
    activityProvider.updateDistance(distanceInKm, _currentSpeed);
  }

  Future<bool> _checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location services are disabled")),
        );
      }
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permissions are denied")),
          );
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Location permissions are permanently denied"),
          ),
        );
      }
      return false;
    }
    return true;
  }

  void startAccidentDetection() async {
    if (userId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User ID is not available")),
        );
      }
      return;
    }

    if (!await _checkPermissions()) return;

    _accelerometerSubscription = accelerometerEvents.listen(
      (AccelerometerEvent event) async {
        double totalAcceleration = sqrt(
          event.x * event.x + event.y * event.y + event.z * event.z,
        );
        _accelerationHistory.add(totalAcceleration);
        if (_accelerationHistory.length > historySize)
          _accelerationHistory.removeAt(0);

        double dynamicThreshold = _calculateDynamicThreshold();
        if (_detectSuddenChange(_accelerationHistory) ||
            totalAcceleration > dynamicThreshold) {
          if (!_isTriggered &&
              (_lastTrigger == null ||
                  DateTime.now().difference(_lastTrigger!) >
                      const Duration(seconds: 5))) {
            _isTriggered = true;
            _lastTrigger = DateTime.now();
            _startAlertCountdown();
          }
        }
      },
      onError:
          (error) => FirebaseCrashlytics.instance.recordError(
            error,
            StackTrace.current,
            reason: 'Accelerometer stream error',
          ),
    );

    _gyroscopeSubscription = gyroscopeEvents.listen(
      (GyroscopeEvent event) async {
        double totalRotation = sqrt(
          event.x * event.x + event.y * event.y + event.z * event.z,
        );
        _rotationHistory.add(totalRotation);
        if (_rotationHistory.length > historySize) _rotationHistory.removeAt(0);

        double dynamicRotationThreshold = _calculateDynamicRotationThreshold();
        if (_detectSuddenChange(_rotationHistory) ||
            totalRotation > dynamicRotationThreshold) {
          if (!_isTriggered &&
              (_lastTrigger == null ||
                  DateTime.now().difference(_lastTrigger!) >
                      const Duration(seconds: 5))) {
            _isTriggered = true;
            _lastTrigger = DateTime.now();
            _startAlertCountdown();
          }
        }
      },
      onError:
          (error) => FirebaseCrashlytics.instance.recordError(
            error,
            StackTrace.current,
            reason: 'Gyroscope stream error',
          ),
    );

    _adjustSensorRate();
  }

  double _calculateDynamicThreshold() {
    if (_currentSpeed > 100) return 7.0;
    if (_currentSpeed > 50) return 9.8;
    return 12.0;
  }

  double _calculateDynamicRotationThreshold() {
    if (_currentSpeed > 100) return 5.0;
    if (_currentSpeed > 50) return 7.0;
    return 10.0;
  }

  bool _detectSuddenChange(List<double> history) {
    if (history.length < historySize) return false;
    double maxValue = history.reduce((a, b) => a > b ? a : b);
    double minValue = history.reduce((a, b) => a < b ? a : b);
    return (maxValue - minValue) > 15.0;
  }

  bool _detectSuddenStop() {
    if (_speedHistory.length < historySize) return false;
    double maxSpeed = _speedHistory.reduce((a, b) => a > b ? a : b);
    double minSpeed = _speedHistory.reduce((a, b) => a < b ? a : b);
    return maxSpeed > 50 && minSpeed < 5 && (maxSpeed - minSpeed) > 40;
  }

  void _adjustSensorRate() {
    if (_currentSpeed < 10) {
      _accelerometerSubscription?.pause();
      _gyroscopeSubscription?.pause();
      Future.delayed(const Duration(seconds: 1), () {
        if (_currentSpeed < 10 &&
            (_accelerometerSubscription?.isPaused ?? false)) {
          _accelerometerSubscription?.resume();
          _gyroscopeSubscription?.resume();
        }
      });
    } else {
      _accelerometerSubscription?.resume();
      _gyroscopeSubscription?.resume();
    }
  }

  void _startAlertCountdown() async {
    if (_detectSuddenStop()) {
      print('Sudden stop detected, triggering alert');
      _isTriggered = true;
    }
    final prefs = await SharedPreferences.getInstance();
    final countdownTime = prefs.getInt('countdown_time') ?? 10;
    alertState.value = AccidentAlertState.detected;
    alertCountdown.value = countdownTime;
    FlutterRingtonePlayer.playAlarm();

    // إرسال إشعار محلي
    await FlutterLocalNotificationsPlugin().show(
      0,
      '🚨 تنبيه حادث!',
      'تم اكتشاف حادث محتمل. يرجى التحقق أو إلغاء التنبيه خلال $countdownTime ثوانٍ.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'emergency_channel',
          'Emergency Notifications',
          channelDescription: 'Notifications for accidents and emergencies',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: 'accident',
    );

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (alertState.value != AccidentAlertState.detected) {
        timer.cancel();
        return;
      }
      alertCountdown.value--;
      if (alertCountdown.value <= 0) timer.cancel();
    });

    _alertTimer = Timer(Duration(seconds: countdownTime), () async {
      if (alertState.value == AccidentAlertState.detected) {
        print('Main timer ended, sending message');
        await _sendEmergencyMessage();
        alertState.value = AccidentAlertState.sent;
        FlutterRingtonePlayer.stop();
        _isTriggered = false;
      }
    });
  }

  Future<void> cancelAlert() async {
    if (_alertTimer != null &&
        alertState.value == AccidentAlertState.detected) {
      _alertTimer?.cancel();
      _countdownTimer?.cancel();
      FlutterRingtonePlayer.stop();
      alertState.value = AccidentAlertState.cancelled;
      _isTriggered = false;
      alertCountdown.value =
          (await SharedPreferences.getInstance()).getInt('countdown_time') ??
          10;
    }
  }

  Future<void> sendEmergencyMessage() async {
    print('sendEmergencyMessage called');
    await _sendEmergencyMessage();
  }

  Future<void> _sendEmergencyMessage() async {
    try {
      final activityProvider = Provider.of<ActivityProvider>(
        context,
        listen: false,
      );
      final prefs = await SharedPreferences.getInstance();
      final contactsJson = prefs.getStringList('emergencyContacts');
      print('Loaded emergency contacts: $contactsJson');

      if (contactsJson == null || contactsJson.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No emergency contacts found")),
          );
        }
        return;
      }

      double? latitude = _currentPosition?.latitude;
      double? longitude = _currentPosition?.longitude;
      if (latitude == null || longitude == null) {
        latitude = prefs.getDouble('last_latitude');
        longitude = prefs.getDouble('last_longitude');
      }

      String message = "Emergency Alert! I may have been in an accident.";
      if (latitude != null && longitude != null) {
        message +=
            " My location: https://www.google.com/maps/search/?api=1&query=$latitude,$longitude";
      } else {
        message += " Location unavailable.";
      }

      bool sentSuccessfully = false;
      String errorMessage = '';
      for (var contactJson in contactsJson) {
        final Map<String, String> contact = Map<String, String>.from(
          jsonDecode(contactJson),
        );
        final phoneNumber = contact['phone']?.replaceAll(
          RegExp(r'[^0-9+]'),
          '',
        );
        if (phoneNumber == null || phoneNumber.isEmpty) continue;

        if (!phoneNumber.startsWith('+')) {
          throw Exception(
            'Phone number $phoneNumber must include country code (e.g., +966 for Saudi Arabia)',
          );
        }
        final formattedPhoneNumber = phoneNumber;
        print('Sending message to: $formattedPhoneNumber');

        try {
          final response = await http
              .post(
                Uri.parse(
                  'https://api.twilio.com/2010-04-01/Accounts/$twilioAccountSid/Messages.json',
                ),
                headers: {
                  'Authorization':
                      'Basic ${base64Encode(utf8.encode('$twilioAccountSid:$twilioAuthToken'))}',
                  'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: {
                  'From': twilioWhatsAppNumber,
                  'To': 'whatsapp:$formattedPhoneNumber',
                  'Body': message,
                },
              )
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  throw TimeoutException('Request to Twilio timed out');
                },
              );

          print('Twilio response status: ${response.statusCode}');
          print('Twilio response body: ${response.body}');

          if (response.statusCode == 201) {
            sentSuccessfully = true;
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Message sent successfully to $formattedPhoneNumber",
                  ),
                ),
              );
            }
          } else {
            final responseBody = jsonDecode(response.body);
            final errorCode = responseBody['code'] as int?;
            if (errorCode == 63038) {
              errorMessage +=
                  'Failed to send to $formattedPhoneNumber: Account exceeded the 9 daily messages limit. Please upgrade your Twilio account or wait until the limit resets, or check https://www.twilio.com/docs/errors/63038 for more info.\n';
            } else {
              errorMessage +=
                  'Failed to send to $formattedPhoneNumber: ${responseBody['message'] ?? 'Unknown error'} (Error Code: $errorCode)\n';
            }
            FirebaseCrashlytics.instance.recordError(
              Exception('Failed to send WhatsApp message: ${response.body}'),
              StackTrace.current,
              reason: 'Twilio API error for $formattedPhoneNumber',
            );
          }
        } catch (e) {
          print('Error sending message to $formattedPhoneNumber: $e');
          errorMessage += 'Failed to send to $formattedPhoneNumber: $e\n';
          FirebaseCrashlytics.instance.recordError(
            e,
            StackTrace.current,
            reason: 'Failed to send WhatsApp message to $formattedPhoneNumber',
          );
        }
      }

      if (!sentSuccessfully) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                errorMessage.isEmpty
                    ? "Failed to send message to any contact"
                    : errorMessage,
              ),
            ),
          );
        }
      }

      try {
        await FirebaseFirestore.instance.collection('accidents').add({
          'userId': userId,
          'timestamp': FieldValue.serverTimestamp(),
          'location':
              latitude != null && longitude != null
                  ? GeoPoint(latitude, longitude)
                  : null,
          'message': message,
        });

        await activityProvider.addActivity("Accident detected", "accident");
      } catch (e) {
        FirebaseCrashlytics.instance.recordError(
          e,
          StackTrace.current,
          reason: 'Failed to log accident to Firestore',
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to log accident")),
          );
        }
      }
    } catch (e) {
      print('General error in _sendEmergencyMessage: $e');
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Failed to send emergency message',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send emergency message: $e")),
        );
      }
    }
  }

  Future<void> stopAccidentDetection() async {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _positionStream?.cancel();
    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
    _positionStream = null;
    _alertTimer?.cancel();
    _countdownTimer?.cancel();
    FlutterRingtonePlayer.stop();
    alertState.value = AccidentAlertState.idle;
    alertCountdown.value =
        (await SharedPreferences.getInstance()).getInt('countdown_time') ?? 10;
  }
}

enum AccidentAlertState { idle, detected, cancelled, sent }
