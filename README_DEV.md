# Basil Voice - Development Guide 💙

## كلامي - عالم باسل
**Communication App for Children with Special Needs**

---

## ✅ Current Status - MVP Complete!

### 🎉 **Phases 1-5 Complete** (Core App Functionality)

All essential features are now implemented and ready to test:

#### ✅ **Phase 1: Project Setup**
- Flutter project created with proper package structure
- All dependencies installed (Provider, Hive, TTS, Image Picker, etc.)
- Folder structure organized

#### ✅ **Phase 2: Core Data Layer**
- Category & Item models with Hive adapters
- 50+ default items across 8 categories
- Local storage service fully functional

#### ✅ **Phase 3: Essential Services**
- Text-to-Speech service (Arabic ar-SA)
- Image picker & compression service
- Provider state management

#### ✅ **Phase 4: Core UI**
- Family Code entry screen
- Home screen with 8 colorful category cards
- Category screen with item grid
- Item tap → instant voice + "أحسنت! 👏" message

#### ✅ **Phase 5: Content Management**
- Add/Edit item screen
- 64 emoji icons to choose from
- Camera & gallery image picker
- Delete with confirmation
- Edit mode toggle

---

## 🚀 Running the App

### Quick Start

```bash
# Make sure Flutter is in your PATH
export PATH="$HOME/flutter/bin:$PATH"

# Get dependencies (if needed)
flutter pub get

# Run on iOS Simulator
flutter run

# Or run on Android Emulator
flutter run
```

### First Launch Flow

1. **Splash Screen** → Loading services
2. **Family Code Screen** → Enter a 4-6 digit code (e.g., "2024")
3. **Home Screen** → 8 colorful category cards
4. Tap any category → See items inside
5. Tap any item → Hear it spoken + see "أحسنت!"

### Testing Content Management

1. Open any category
2. Tap the ⚙️ settings icon (top right)
3. Tap the green "إضافة عنصر" button
4. Fill in the text, choose an emoji or image
5. Save → Item appears immediately!

---

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── category.dart
│   ├── category.g.dart       # Generated Hive adapter
│   ├── item.dart
│   └── item.g.dart           # Generated Hive adapter
├── services/                 # Business logic
│   ├── storage_service.dart  # Hive local storage
│   ├── tts_service.dart      # Text-to-Speech
│   └── image_service.dart    # Image picker & compression
├── providers/                # State management
│   └── app_provider.dart     # Main app state
├── screens/                  # UI screens
│   ├── family_code_screen.dart
│   ├── home_screen.dart
│   ├── category_screen.dart
│   └── add_edit_item_screen.dart
├── widgets/                  # Reusable widgets (empty for now)
└── utils/                    # Constants & helpers
    └── constants.dart        # Default data, colors, emojis
```

---

## 🎨 Features Implemented

### ✅ For Children (Normal Use)
- [x] Simple, large, colorful buttons
- [x] Instant voice feedback in Arabic
- [x] "أحسنت! 👏" encouragement message
- [x] 8 categories with 50+ pre-loaded items
- [x] Works completely offline

### ✅ For Parents (Content Management)
- [x] Add custom items with text + image
- [x] Edit existing items
- [x] Delete items (with confirmation)
- [x] Choose from 64 emoji icons
- [x] Take photo with camera
- [x] Pick image from gallery
- [x] Custom speech text (optional)

### ✅ Technical Features
- [x] RTL (Right-to-Left) Arabic layout
- [x] Cairo font from Google Fonts
- [x] Local storage with Hive
- [x] State management with Provider
- [x] Image compression (saves space)
- [x] Family Code system (privacy)

---

## 📦 Dependencies Used

```yaml
# State Management
provider: ^6.1.2

# Local Storage
hive: ^2.2.3
hive_flutter: ^1.1.0

# Text-to-Speech
flutter_tts: ^4.2.0

# Image Handling
image_picker: ^1.1.2
flutter_image_compress: ^2.3.0

# UI & Fonts
google_fonts: ^6.2.1

# Utilities
uuid: ^4.5.1
path_provider: ^2.1.5
```

---

## 🔜 Next Steps (Phase 6-7)

### Phase 6: Firebase Integration
- [ ] Set up Firebase project
- [ ] Add Firebase config files
- [ ] Implement Firestore sync
- [ ] Implement Firebase Storage for images
- [ ] Background sync (upload changes)
- [ ] Auto-download updates from other devices
- [ ] Conflict resolution (last update wins)

### Phase 7: Polish & Production
- [ ] Add smooth animations
- [ ] Loading indicators
- [ ] Better error handling
- [ ] Offline mode testing
- [ ] Multi-device sync testing
- [ ] Performance optimization

---

## 🐛 Known Issues

1. **Warnings in flutter analyze**: Using deprecated methods (`.withOpacity()`, `.value`) - these are cosmetic and don't affect functionality. Can be fixed later.

2. **Firebase Not Set Up Yet**: The app currently works 100% offline. Multi-device sync will be added in Phase 6.

3. **No Animations Yet**: Basic animations will be added in Phase 7.

---

## 🎯 How to Test

### Test 1: Basic Flow
1. Run the app
2. Enter family code "2024"
3. See 8 categories on home screen
4. Tap "احتياجات أساسية"
5. Tap "عايز آكل 🍽️"
6. Hear voice + see encouragement

### Test 2: Add Item
1. Open any category
2. Tap settings icon
3. Tap "إضافة عنصر"
4. Type "عايز أروح الشاطئ"
5. Select 🏖️ emoji
6. Tap "حفظ"
7. New item appears!

### Test 3: Edit Item
1. Enable edit mode (settings icon)
2. Tap blue edit button on any item
3. Change text or emoji
4. Save
5. Item updates immediately

### Test 4: Delete Item
1. Enable edit mode
2. Tap red delete button
3. Confirm deletion
4. Item removed

---

## 💡 Tips for Development

### Regenerate Hive Adapters
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Check for Issues
```bash
flutter analyze
```

### Format Code
```bash
flutter format lib/
```

### Clean Build
```bash
flutter clean
flutter pub get
```

---

## 📱 Platform Support

- ✅ iOS 12.0+
- ✅ Android 6.0+ (API 23+)
- ⚠️ Web/Desktop not tested (but should work)

---

## 🎨 Design Colors

```dart
Blue (احتياجات أساسية):   #4A90E2
Pink (مشاعر):            #FF69B4
Green (أماكن):           #4CAF50
Purple (ألعاب):          #9C27B0
Red (تلفزيون):          #F44336
Orange (أكل):            #FF9800
Yellow (أشخاص):         #FFEB3B
Indigo (إجابات):        #3F51B5
```

---

## 🤝 Contributing

This is a family project for helping children with special needs communicate better.

---

## 📞 Support

If you encounter any issues during development, check:
1. Flutter is properly installed: `flutter doctor`
2. Dependencies are installed: `flutter pub get`
3. Hive adapters are generated: `flutter pub run build_runner build`

---

**Built with ❤️ for Basil and all children who need a voice**

محمد الأصوات بحب 💙
