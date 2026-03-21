import 'package:flutter/material.dart';

class EmergencyContact {
  String id;
  String name;
  String number;
  String relation;
  EmergencyContact({required this.id, required this.name, required this.number, this.relation = "Trusted"});
}

class SOSLevel {
  String name;
  Color color;
  bool sendSMS;
  bool recordAudio;
  bool recordVideo;
  bool liveStream;
  bool notifyPolice;
  String customMessage;
  String activationGesture;

  SOSLevel({
    required this.name,
    required this.color,
    this.sendSMS = true,
    this.recordAudio = false,
    this.recordVideo = false,
    this.liveStream = false,
    this.notifyPolice = false,
    required this.customMessage,
    required this.activationGesture,
  });
}

class EvidenceRecord {
  String date;
  String type; // Video or Audio
  String duration;
  String level;
  EvidenceRecord({required this.date, required this.type, required this.duration, required this.level});
}