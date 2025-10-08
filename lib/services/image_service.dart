import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  // Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return null;

      return await _compressAndSave(File(image.path));
    } catch (e) {
      print('Pick image from camera error: $e');
      return null;
    }
  }

  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return null;

      return await _compressAndSave(File(image.path));
    } catch (e) {
      print('Pick image from gallery error: $e');
      return null;
    }
  }

  // Compress and save image
  Future<File?> _compressAndSave(File imageFile) async {
    try {
      // Get app directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagesDir = '${appDir.path}/images';

      // Create images directory if it doesn't exist
      final Directory imagesDirObj = Directory(imagesDir);
      if (!await imagesDirObj.exists()) {
        await imagesDirObj.create(recursive: true);
      }

      // Generate unique filename
      final String fileName = '${_uuid.v4()}.jpg';
      final String targetPath = '$imagesDir/$fileName';

      // Compress image
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.path,
        targetPath,
        quality: 85,
        minWidth: 800,
        minHeight: 800,
        format: CompressFormat.jpeg,
      );

      if (compressedFile == null) {
        return null;
      }

      return File(compressedFile.path);
    } catch (e) {
      print('Compress and save error: $e');
      return null;
    }
  }

  // Delete local image file
  Future<void> deleteImage(String imagePath) async {
    try {
      final File file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Delete image error: $e');
    }
  }

  // Check if file exists
  Future<bool> fileExists(String path) async {
    try {
      final File file = File(path);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }
}
