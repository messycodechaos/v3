import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class VideoRecordService {
  static final VideoRecordService _instance = VideoRecordService._internal();
  factory VideoRecordService() => _instance;
  VideoRecordService._internal();
  MediaRecorder? _mediaRecorder;

  Future<void> startVideoRecording(MediaStream stream) async {
    if (kIsWeb) return;
    try {
      final dir = await getExternalStorageDirectory();
      final String path = '${dir!.path}/GuardianX_Video_${DateFormat('HHmmss').format(DateTime.now())}.mp4';
      _mediaRecorder = MediaRecorder();
      await _mediaRecorder!.start(path, videoTrack: stream.getVideoTracks().first);
    } catch (e) {}
  }
  Future<void> stopVideoRecording() async { await _mediaRecorder?.stop(); _mediaRecorder = null; }
}