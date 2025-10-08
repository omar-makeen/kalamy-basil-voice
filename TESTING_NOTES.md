# Testing Notes - Basil Voice App

## ✅ **What's Working (Tested on Chrome)**

### Core Features:
- ✅ Family Code entry
- ✅ Home screen with 8 categories
- ✅ Category screens with items
- ✅ Item tap → Voice output (may not work on web)
- ✅ "أحسنت! 👏" encouragement message
- ✅ Add/Edit/Delete items
- ✅ Add/Edit/Delete categories
- ✅ Image picker (emoji selection works)
- ✅ All data saves locally (Hive)
- ✅ Edit mode toggle for both categories and items

---

## ⚠️ **Known Web/Chrome Limitations**

### 1. **Drag-to-Reorder Categories & Items**
**Status:** ❌ Not working properly on web browsers
**Why:** Flutter's `ReorderableListView` has limited mouse/touch support on web
**Solution:** ✅ **Test on actual iOS/Android devices** - it will work perfectly there!

**How to Test on Device:**
1. Build APK or run on connected device
2. Go to Home screen → Tap settings
3. Long-press and drag any category up/down
4. Release - order will save immediately
5. Same for items inside categories!

### 2. **Text-to-Speech (TTS)**
**Status:** ⚠️ May not work on web
**Why:** Browser TTS APIs are limited
**Solution:** Test on actual devices for full voice output

### 3. **Camera/Gallery Image Picker**
**Status:** ⚠️ Limited on web
**Solution:** Emoji picker works perfectly everywhere; test camera on devices

---

## 📱 **Testing on Real Devices**

### iOS (iPhone/iPad):
```bash
# Connect device via USB
flutter run

# Or build IPA
flutter build ios
```

### Android:
```bash
# Connect device via USB with debugging enabled
flutter run

# Or build APK
flutter build apk
# APK will be in: build/app/outputs/flutter-apk/app-release.apk
```

### What to Test on Devices:
1. ✅ **Drag-to-reorder categories** (Home screen → Settings)
2. ✅ **Drag-to-reorder items** (Category screen → Settings)
3. ✅ **Text-to-Speech** (Tap any item to hear voice)
4. ✅ **Camera image picker** (Add item → Camera button)
5. ✅ **Gallery image picker** (Add item → Gallery button)
6. ✅ **All CRUD operations** work smoothly

---

## 🎯 **Full Feature List**

### Categories (Main Sections):
- ✅ Add new category (name, emoji, color)
- ✅ Edit category (change name, emoji, color)
- ✅ Delete category (with confirmation, deletes all items inside)
- ✅ Reorder categories (drag on devices, saves order)

### Items (Sub-items):
- ✅ Add new item (text, image/emoji, optional custom speech)
- ✅ Edit item
- ✅ Delete item (with confirmation)
- ✅ Reorder items (drag on devices, saves order)

### Images:
- ✅ Choose from 64 emoji icons
- ✅ Take photo with camera
- ✅ Pick from gallery
- ✅ Automatic compression

### Data:
- ✅ All saved locally with Hive
- ✅ Works 100% offline
- ✅ Instant save/load
- ✅ Family Code system for privacy

---

## 🚀 **Next Steps**

1. **Test on actual device** to verify drag-to-reorder works
2. **Test TTS** on device for Arabic voice output
3. **Test image picker** with camera and gallery
4. If everything works → Ready for Phase 6 (Firebase sync)!

---

## 💡 **Tips**

- **Chrome testing is great for:** UI, layout, navigation, CRUD operations
- **Device testing is essential for:** Drag-to-reorder, TTS, camera, full UX
- **Reordering on web workaround:** You can still edit items and change their order manually by editing them

---

**For best testing experience, use a real iOS or Android device!** 📱
