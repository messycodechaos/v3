import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class RecordService {
  static final RecordService _instance = RecordService._internal();
  factory RecordService() => _instance;
  RecordService._internal();
  final AudioRecorder _recorder = AudioRecorder();

  Future<void> startLocalRecord() async {
    try {
      if (await _recorder.hasPermission()) {
        String path = "";
        if (!kIsWeb) {
          final dir = await getExternalStorageDirectory();
          path = '${dir!.path}/SOS_Audio_${DateFormat('HHmmss').format(DateTime.now())}.m4a';
        }
        await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      }
    } catch (e) {}
  }
  Future<void> stopLocalRecord() async => await _recorder.stop();
}