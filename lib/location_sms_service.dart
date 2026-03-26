import 'dart:async';
import 'package:telephony/telephony.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'sos_model.dart';

class LocationSmsService {
  static final LocationSmsService _instance = LocationSmsService._internal();
  factory LocationSmsService() => _instance;
  LocationSmsService._internal();

  final Telephony telephony = Telephony.instance;
  Timer? _fiveMinTimer;

  Future<void> sendGlobalAlerts({
    required List<EmergencyContact> contacts,
    required String roomCode,
    required String customMsg,
  }) async {
    // 1. Get current GPS
    Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    String mapLink = "https://www.google.com/maps/search/?api=1&query=${pos.latitude},${pos.longitude}";

    String fullMessage = "🚨 SOS ALERT 🚨\n$customMsg\n\n📍 My Location: $mapLink\n🔑 Watch Live Code: $roomCode";

    // 2. Loop through every contact and send immediately
    for (var contact in contacts) {
      // --- AUTO BACKGROUND SMS (No app opens) ---
      try {
        await telephony.sendSms(
            to: contact.number,
            message: fullMessage,
            statusListener: (SendStatus status) {
              print("SMS to ${contact.name}: ${status.name}");
            }
        );
      } catch (e) {
        print("SMS Error for ${contact.name}: $e");
      }

      // --- WHATSAPP (Opens app with text ready) ---
      String waUrl = "https://wa.me/${contact.number}?text=${Uri.encodeComponent(fullMessage)}";
      await launchUrl(Uri.parse(waUrl), mode: LaunchMode.externalApplication);
    }

    // 3. Start the 5-minute location update loop
    _startLocationLoop(contacts, roomCode);
  }

  void _startLocationLoop(List<EmergencyContact> contacts, String roomCode) {
    _fiveMinTimer?.cancel();
    _fiveMinTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      String mapLink = "https://www.google.com/maps/search/?api=1&query=${pos.latitude},${pos.longitude}";
      String updateMsg = "📍 AUTO-UPDATE: I am still here: $mapLink. Code: $roomCode";

      for (var c in contacts) {
        telephony.sendSms(to: c.number, message: updateMsg);
      }
    });
  }

  void stopAlerts() => _fiveMinTimer?.cancel();
}