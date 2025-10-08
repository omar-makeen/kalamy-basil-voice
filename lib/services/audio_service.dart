import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Service for recording and playing audio files
/// Used for parent voice recordings that are more familiar to children with autism
class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  String? _currentRecordingPath;

  bool get isRecording => _isRecording;
  bool get isPlaying => _player.playing;

  /// Request microphone permission
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Start recording audio
  /// Returns the path where the audio will be saved
  Future<String?> startRecording() async {
    try {
      // Check permission
      if (!await requestPermission()) {
        print('❌ Microphone permission denied');
        return null;
      }

      // Check if already recording
      if (_isRecording) {
        print('⚠️ Already recording');
        return null;
      }

      // Get app directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${directory.path}/recordings/audio_$timestamp.m4a';

      // Create recordings directory if it doesn't exist
      final recordingsDir = Directory('${directory.path}/recordings');
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }

      // Start recording with high quality settings
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc, // AAC-LC codec (widely compatible)
          bitRate: 128000, // 128 kbps
          sampleRate: 44100, // 44.1 kHz (CD quality)
        ),
        path: path,
      );

      _isRecording = true;
      _currentRecordingPath = path;

      print('🎙️ Recording started: $path');
      return path;
    } catch (e) {
      print('❌ Error starting recording: $e');
      return null;
    }
  }

  /// Stop recording and return the file path
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) {
        print('⚠️ Not currently recording');
        return null;
      }

      final path = await _recorder.stop();
      _isRecording = false;

      print('✅ Recording stopped: $path');
      return path;
    } catch (e) {
      print('❌ Error stopping recording: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Cancel recording and delete the file
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder.stop();
        _isRecording = false;
      }

      // Delete the recording file if it exists
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
          print('🗑️ Recording deleted: $_currentRecordingPath');
        }
      }

      _currentRecordingPath = null;
    } catch (e) {
      print('❌ Error canceling recording: $e');
    }
  }

  /// Play audio from a file path
  Future<void> playAudio(String path) async {
    try {
      // Stop any currently playing audio
      await stopAudio();

      // Check if file exists (for local files)
      if (!path.startsWith('http') && !path.startsWith('https')) {
        final file = File(path);
        if (!await file.exists()) {
          print('❌ Audio file does not exist: $path');
          return;
        }
      }

      // Play the audio
      await _player.setFilePath(path);
      await _player.play();

      print('🔊 Playing audio: $path');
    } catch (e) {
      print('❌ Error playing audio: $e');
    }
  }

  /// Stop audio playback
  Future<void> stopAudio() async {
    try {
      if (_player.playing) {
        await _player.stop();
        print('⏹️ Audio stopped');
      }
    } catch (e) {
      print('❌ Error stopping audio: $e');
    }
  }

  /// Upload audio file to Firebase Storage
  /// Returns the download URL
  Future<String?> uploadAudio(String localPath, String itemId, String familyCode) async {
    try {
      final file = File(localPath);
      if (!await file.exists()) {
        print('❌ File does not exist: $localPath');
        return null;
      }

      // Create reference to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('families')
          .child(familyCode)
          .child('audio')
          .child('$itemId.m4a');

      // Upload file
      print('⬆️ Uploading audio to Firebase Storage...');
      await storageRef.putFile(file);

      // Get download URL
      final downloadUrl = await storageRef.getDownloadURL();
      print('✅ Audio uploaded: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading audio: $e');
      return null;
    }
  }

  /// Download audio file from Firebase Storage to local storage
  /// Returns the local file path
  Future<String?> downloadAudio(String downloadUrl, String itemId) async {
    try {
      // Get app directory
      final directory = await getApplicationDocumentsDirectory();
      final localPath = '${directory.path}/recordings/downloaded_$itemId.m4a';

      // Create recordings directory if it doesn't exist
      final recordingsDir = Directory('${directory.path}/recordings');
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }

      // Check if file already exists
      final file = File(localPath);
      if (await file.exists()) {
        print('✅ Audio already downloaded: $localPath');
        return localPath;
      }

      // Download file
      print('⬇️ Downloading audio from Firebase Storage...');
      final storageRef = FirebaseStorage.instance.refFromURL(downloadUrl);
      await storageRef.writeToFile(file);

      print('✅ Audio downloaded: $localPath');
      return localPath;
    } catch (e) {
      print('❌ Error downloading audio: $e');
      return null;
    }
  }

  /// Delete audio file from local storage
  Future<void> deleteLocalAudio(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        print('🗑️ Local audio deleted: $path');
      }
    } catch (e) {
      print('❌ Error deleting local audio: $e');
    }
  }

  /// Delete audio file from Firebase Storage
  Future<void> deleteFirebaseAudio(String itemId, String familyCode) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('families')
          .child(familyCode)
          .child('audio')
          .child('$itemId.m4a');

      await storageRef.delete();
      print('🗑️ Firebase audio deleted: $itemId');
    } catch (e) {
      print('❌ Error deleting Firebase audio: $e');
    }
  }

  /// Clean up resources
  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}
