import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:background_sms/background_sms.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'sos_model.dart';

class LocationSmsService {
  static final LocationSmsService _instance = LocationSmsService._internal();
  factory LocationSmsService() => _instance;
  LocationSmsService._internal();

  Timer? _loopTimer;

  Future<void> triggerAlerts({
    required List<EmergencyContact> contacts,
    required String roomCode,
    required String customMsg,
    required bool useSMS,
    required bool isAuto,
    required bool useWA
  }) async {
    Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    String mapLink = "https://www.google.com/maps/search/?api=1&query=${pos.latitude},${pos.longitude}";
    String fullMessage = "🚨 SOS ALERT 🚨\n$customMsg\n\n📍 Location: $mapLink\n🔑 Watch Code: $roomCode";

    for (var contact in contacts) {
      if (useSMS) {
        if (isAuto && !kIsWeb) {
          // Send silently by itself
          await BackgroundSms.sendMessage(phoneNumber: contact.number, message: fullMessage);
        } else {
          // Open SMS app for user
          final Uri smsUri = Uri(scheme: 'sms', path: contact.number, queryParameters: {'body': fullMessage});
          if (await canLaunchUrl(smsUri)) await launchUrl(smsUri);
        }
      }

      if (useWA) {
        String waUrl = "https://wa.me/${contact.number}?text=${Uri.encodeComponent(fullMessage)}";
        await launchUrl(Uri.parse(waUrl), mode: LaunchMode.externalApplication);
      }
    }
    if (isAuto) _startLoop(contacts);
  }

  void _startLoop(List<EmergencyContact> cs) {
    _loopTimer?.cancel();
    _loopTimer = Timer.periodic(const Duration(minutes: 5), (t) async {
      Position p = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      String msg = "📍 UPDATE: https://www.google.com/maps/search/?api=1&query=${p.latitude},${p.longitude}";
      if (!kIsWeb) for (var c in cs) { BackgroundSms.sendMessage(phoneNumber: c.number, message: msg); }
    });
  }
  void stop() => _loopTimer?.cancel();
}