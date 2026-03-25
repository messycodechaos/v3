import 'package:flutter/material.dart';

class EmergencyContact {
  String id, name, number, relation;
  EmergencyContact({required this.id, required this.name, required this.number, this.relation = "Trusted"});
}

class SOSLevel {
  String name; Color color;
  bool sendSMS, recordAudio, recordVideo, liveStream, notifyPolice;
  String customMessage, activationGesture;
  SOSLevel({required this.name, required this.color, this.sendSMS = true, this.recordAudio = false, this.recordVideo = false, this.liveStream = false, this.notifyPolice = false, required this.customMessage, required this.activationGesture});
}

class EvidenceRecord {
  String date, type, duration, level;
  EvidenceRecord({required this.date, required this.type, required this.duration, required this.level});
}