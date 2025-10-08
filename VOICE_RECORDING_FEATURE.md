# 🎙️ Voice Recording Feature for Autism Support

## ✅ What's Been Added

### 1. New Dependencies (pubspec.yaml)
```yaml
# Text-to-Speech & Audio Recording
flutter_tts: ^4.2.0
record: ^5.1.2              # NEW - For recording audio
just_audio: ^0.9.40         # NEW - For playing audio
permission_handler: ^11.3.1  # NEW - For microphone permissions
```

### 2. Updated Item Model
Added `customAudioPath` field to store parent's voice recording:
- Parents can record their voice saying each item
- Audio stored locally with item
- When child taps item: plays parent's voice instead of TTS

## 🎯 Why This is Important for Autism

**Research shows:**
- Children with autism respond better to familiar voices (parents, family)
- Hearing mom/dad's voice creates comfort and trust
- Personalized audio improves learning and communication
- Reduces anxiety compared to robotic TTS

## 📝 Next Steps to Complete Feature

### Step 1: Install Dependencies
```bash
flutter pub get
```

### Step 2: Regenerate Hive Adapters
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Step 3: Create Audio Service
Create `lib/services/audio_service.dart`:

```dart
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  // Request microphone permission
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  // Start recording
  Future<void> startRecording(String itemId) async {
    if (!await requestPermission()) {
      throw Exception('Microphone permission denied');
    }

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/audio_${itemId}_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    _isRecording = true;
  }

  // Stop recording and return file path
  Future<String?> stopRecording() async {
    final path = await _recorder.stop();
    _isRecording = false;
    return path;
  }

  // Play recorded audio
  Future<void> playAudio(String path) async {
    await _player.setFilePath(path);
    await _player.play();
  }

  // Stop playing
  Future<void> stopPlaying() async {
    await _player.stop();
  }

  // Delete audio file
  Future<void> deleteAudio(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting audio: $e');
    }
  }

  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}
```

### Step 4: Update AppProvider
Add to `lib/providers/app_provider.dart`:

```dart
final AudioService _audioService;

// In constructor
AppProvider({
  // ... existing params
  required AudioService audioService,
}) : // ... existing assignments
     _audioService = audioService;

// Add methods
Future<void> startRecording(String itemId) async {
  await _audioService.startRecording(itemId);
  notifyListeners();
}

Future<String?> stopRecording() async {
  final path = await _audioService.stopRecording();
  notifyListeners();
  return path;
}

Future<void> playAudio(Item item) async {
  if (item.customAudioPath != null) {
    await _audioService.playAudio(item.customAudioPath!);
  } else {
    await _ttsService.speak(item.speechText);
  }
}

bool get isRecording => _audioService.isRecording;
```

### Step 5: Update main.dart
```dart
ChangeNotifierProvider(
  create: (_) => AppProvider(
    storageService: StorageService(),
    ttsService: TtsService(),
    imageService: ImageService(),
    firebaseService: FirebaseService(),
    audioService: AudioService(),  // ADD THIS
  ),
),
```

### Step 6: Add Recording UI to Add/Edit Item Screen

In `lib/screens/add_edit_item_screen.dart`, add:

```dart
// Add state variable
String? _audioPath;

// Add recording button
ElevatedButton.icon(
  onPressed: appProvider.isRecording
      ? () async {
          final path = await appProvider.stopRecording();
          setState(() => _audioPath = path);
        }
      : () async {
          await appProvider.startRecording(widget.item?.id ?? 'temp');
        },
  icon: Icon(appProvider.isRecording ? Icons.stop : Icons.mic),
  label: Text(appProvider.isRecording ? 'إيقاف التسجيل' : 'تسجيل صوت'),
  style: ElevatedButton.styleFrom(
    backgroundColor: appProvider.isRecording ? Colors.red : Colors.blue,
  ),
)

// When saving item:
final item = Item(
  // ... other fields
  customAudioPath: _audioPath ?? widget.item?.customAudioPath,
);
```

### Step 7: Update Category Screen Playback

In `lib/screens/category_screen.dart`, change:

```dart
// OLD:
onTap: () => appProvider.speak(item.speechText),

// NEW:
onTap: () => appProvider.playAudio(item),
```

## 🎨 UI Flow

1. **Parent adds/edits item**
2. **Tap "تسجيل صوت" button** (Record Voice)
3. **Speak the item name** (e.g., "عايز مياه يا حبيبي")
4. **Tap "إيقاف التسجيل"** (Stop Recording)
5. **Save item** - voice is saved with item
6. **Child taps item** → **Hears parent's voice!** ❤️

## 📱 Android Permissions

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

## 🍎 iOS Permissions

Add to `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>نحتاج الميكروفون لتسجيل صوتك لمساعدة طفلك</string>
```

## ✨ Benefits

✅ **Personalized Communication**: Child hears mom/dad's voice
✅ **Better Response**: Autism children respond better to familiar voices
✅ **Emotional Connection**: Voice brings comfort and trust
✅ **Flexible**: Can still use TTS if no recording
✅ **Easy to Use**: Simple record/stop interface

## 🔄 Firebase Sync

Audio files will be:
1. Stored locally first
2. Uploaded to Firebase Storage (like images)
3. Downloaded on other devices
4. Played from local cache

## 📊 File Storage

- Format: M4A (AAC-LC codec)
- Bitrate: 128kbps
- Sample Rate: 44.1kHz
- Location: App Documents directory
- Naming: `audio_{itemId}_{timestamp}.m4a`

---

**This feature will make the app much more effective for children with autism!** 🎉
