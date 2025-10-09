# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Basil Voice (كلامي - عالم باسل)** is a Flutter communication app for children with autism and special needs. It helps children express their needs through an intuitive visual interface with voice feedback using parent-recorded audio or Arabic TTS.

**Key Feature:** Parents can record their own voice for each item, as children with autism respond significantly better to familiar voices than synthetic TTS.

## Development Commands

### Setup
```bash
# Install dependencies
flutter pub get

# Regenerate Hive type adapters (required after modifying models)
flutter pub run build_runner build --delete-conflicting-outputs
```

### Running the App
```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Run on Android device
flutter run -d AXUG024C24000796  # Physical Android device

# Run on emulator
flutter run -d emulator-5554
```

### Testing
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage
```

## Architecture

### State Management Pattern
**Provider + Service Layer Architecture**

The app uses a **centralized AppProvider** (`lib/providers/app_provider.dart`) that orchestrates all services:

```
User Action → AppProvider → Services → Storage/Firebase
                ↓
           notifyListeners()
                ↓
            UI Updates
```

**Key Services:**
- `StorageService`: Hive local database (offline-first)
- `FirebaseService`: Cloud Firestore sync & Firebase Storage
- `TtsService`: Arabic text-to-speech (Egyptian Arabic preferred)
- `AudioService`: Parent voice recording/playback
- `ImageService`: Image picking and compression

### Data Flow & Sync Strategy

**Offline-First Architecture:**
1. All data operations go to Hive first (local storage)
2. Firebase operations happen in background
3. Real-time listeners update local data when changes occur on other devices

**CRUD Operations:**
- Use `*WithSync()` methods in AppProvider (e.g., `addItemWithSync()`)
- These methods save locally THEN upload to Firebase
- Never wait for Firebase to complete before updating UI

**Real-Time Sync:**
- `_startRealtimeListeners()` in AppProvider listens to Firebase changes
- Listeners compare cloud data with local, then update/delete as needed
- Prevents duplicates by using Hive's ID-based storage (saves by ID, auto-replaces)

### Data Models

**Category** (`lib/models/category.dart`)
- Represents a category (e.g., Food, Emotions, Places)
- Has name, emoji, color, order
- Uses `@HiveType` for local storage serialization

**Item** (`lib/models/item.dart`)
- Represents a communication item within a category
- Has text, customSpeechText, imageType, imageValue, order
- **Important:** `customAudioPath` field stores path to parent's voice recording
- Uses `@HiveType` for local storage serialization

**After modifying models:** Always regenerate Hive adapters:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Firebase Structure

```
families/
  └── {familyCode}/
      ├── categories/
      │   └── {categoryId}/
      │       ├── id, name, emoji, colorValue, order
      │       ├── createdAt, updatedAt
      └── items/
          └── {itemId}/
              ├── id, categoryId, text, customSpeechText
              ├── imageType, imageValue
              ├── customAudioPath
              ├── order, createdAt, updatedAt

storage/
  └── families/
      └── {familyCode}/
          ├── images/
          │   └── {itemId}.jpg
          └── audio/
              └── {itemId}.m4a
```

**Family Code Isolation:**
- Each family has a unique 4-digit code
- All Firebase operations are scoped to family code
- Prevents data leakage between families

### Drag-and-Drop Implementation

**Categories (Home Screen):**
- Uses `ReorderableListView.builder` with `buildDefaultDragHandles: false`
- Wraps items with `ReorderableDragStartListener` for full-card dragging
- Calls `appProvider.reorderCategories()` which updates order field and syncs to Firebase

**Items (Category Screen):**
- Same pattern: `ReorderableListView` + `ReorderableDragStartListener`
- Edit mode shows list view with drag handles
- Normal mode shows grid view (no reordering)
- Calls `appProvider.reorderItems()` which updates order field and syncs to Firebase

**Critical:** The entire card is draggable (not just the drag handle icon) for better Android touch support.

### Audio Visual Indicators

Items with parent voice recordings show a blue microphone badge:
- **Grid view:** Circular badge in top-right corner (16px mic icon)
- **List view:** Inline badge next to text (14px mic icon)
- Check: `item.customAudioPath != null && item.customAudioPath!.isNotEmpty`

### Voice Recording Flow

1. User taps "ابدأ التسجيل" (Start Recording) in add/edit item screen
2. `AudioService.startRecording()` requests microphone permission
3. Records to local file: `app_documents/recordings/audio_{timestamp}.m4a`
4. User taps "إيقاف التسجيل" (Stop Recording)
5. Path stored in `item.customAudioPath`
6. When item is tapped in category view:
   - If `customAudioPath` exists: play parent's voice via `AudioService.playAudio()`
   - Else: fall back to TTS via `TtsService.speak()`

**Audio Format:**
- Codec: AAC-LC
- Bitrate: 128 kbps
- Sample rate: 44.1 kHz
- File extension: .m4a

## Important Patterns & Conventions

### RTL (Right-to-Left) Support
All screens wrap content in `Directionality(textDirection: TextDirection.rtl)` for Arabic.

### Arabic Text Rendering
- Use `GoogleFonts.cairo()` for all Arabic text
- Family code: 2024 (stored in Hive box 'settings')

### Firebase Safety
- Never push to Firebase without saving to local Hive first
- Use `_isDeleting` flag in AppProvider to prevent real-time listeners from interfering with deletions
- Use `_isInitialLoad` flag to prevent duplicate data during initial Firebase download

### Duplicate Prevention
**Solved Issue:** Initial implementation had duplicate data problems.

**Solution:**
- Hive automatically prevents ID-based duplicates (saves by ID, replaces if exists)
- Real-time listeners use this pattern:
  ```dart
  for (final item in cloudItems) {
    await _storageService.saveItem(item); // Hive replaces by ID
  }
  ```
- Delete items that exist locally but not in cloud
- **Never** compare by count, always compare by content or ID

### TTS Configuration
`TtsService` prefers Egyptian Arabic (ar-EG) with:
- Language: ar-EG → ar-SA → any Arabic → default
- Speech rate: 0.6 (slower for clarity)
- Pitch: 1.0 (neutral)

## Known Issues & Workarounds

### record_linux Compatibility
**Issue:** `record_linux` 0.7.2 doesn't compile with Dart SDK 3.9.2

**Solution:** Use dependency override in `pubspec.yaml`:
```yaml
dependency_overrides:
  record_linux: ^1.2.1
```

### Permissions
**Android:** `android/app/src/main/AndroidManifest.xml`
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
```

**iOS:** `ios/Runner/Info.plist`
```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs access to the microphone to record your voice for better communication with children with autism.</string>
```

## Feature Development Workflow

### Creating New Features
1. **Always** create a feature branch: `git checkout -b feature/feature-name`
2. Implement and test on physical Android device
3. Commit with descriptive message including:
   - ✨/🐛 emoji for feature/fix
   - Clear description of what changed
   - Why it's important (especially for autism-specific features)
   - "🤖 Generated with Claude Code" footer
4. Push feature branch: `git push -u origin feature/feature-name`
5. Test on device, then merge to main if working

### When Modifying Models
1. Update the model file (`lib/models/*.dart`)
2. Regenerate Hive adapters: `flutter pub run build_runner build --delete-conflicting-outputs`
3. Test data migration (existing local data should still work)
4. If breaking change: consider data migration strategy

### When Adding Services
1. Create service in `lib/services/`
2. Add to AppProvider constructor and initialization
3. Expose methods through AppProvider (don't access services directly from UI)
4. Remember to dispose in `AppProvider.dispose()`

## Firebase Project Info
- Project ID: `kalamy-basil-voice`
- Project Number: `170316411027`
- Default family code: `2024`
- Region: us-central1

## Debugging Tools

**Cleanup Tool:** Access via ⋮ menu button in home screen
- Removes duplicate items from Firebase (compares by text+category+order)
- Pre-filled with family code 2024
- Shows detailed logs of what's being cleaned

**Debug Logging:**
- All Firebase operations log to console
- Duplicate detection runs on app start (`checkForDuplicates()`)
- Look for 🔍, ✅, ❌ emoji in logs for quick scanning

## Special Considerations for Autism Support

**Voice Recording Priority:** Always prioritize parent voice over TTS. Research shows:
- Children with autism respond 3x better to familiar voices
- Reduces anxiety and improves communication success
- Creates emotional connection and trust

**UI Design Principles:**
- Large, clear buttons (min 60x60)
- High contrast colors
- Consistent visual patterns
- Instant feedback (visual + audio)
- No complex gestures (simple taps)

**Testing:** Always test on physical devices, especially for touch interactions like drag-and-drop and voice recording.
