import 'dart:async';
// ignore: unused_import
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:razak_travel/core/services/supabase_service.dart';
import 'package:razak_travel/core/services/storage_file_upload_stub.dart'
    if (dart.library.io) 'package:razak_travel/core/services/storage_file_upload_io.dart'
    as storage_file_upload;

class MediaUploadService {
  static const int _imageQuality = 85;
  static const double _maxImageWidth = 1600;
  static const double _maxImageHeight = 1600;

  MediaUploadService({
    SupabaseService? supabase,
    ImagePicker? imagePicker,
  })  : _supabase = supabase ?? SupabaseService.instance,
        _imagePicker = imagePicker ?? ImagePicker();

  final SupabaseService _supabase;
  final ImagePicker _imagePicker;

  Future<XFile?> pickImageFromGallery() async {
    try {
      await _ensureImageAccess();
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: _imageQuality,
      );

      if (pickedFile == null) {
        _log('Image selection cancelled.');
        return null;
      }

      if (!kIsWeb) {
        final imagePath = pickedFile.path.trim();
        if (imagePath.isEmpty) {
          throw StateError('Selected image has an invalid file path.');
        }

        final exists = await storage_file_upload.fileExists(imagePath);
        if (!exists) {
          throw StateError('Selected image file does not exist.');
        }
      }

      _log(
        'Selected image path="${pickedFile.path}" name="${pickedFile.name}"',
      );
      return pickedFile;
    } catch (e, s) {
      _log('Caught exception while picking image: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  Future<String?> pickAndUploadImage() async {
    try {
      final file = await pickImageFromGallery();

      if (file == null) {
        return null;
      }

      return uploadImage(file);
    } catch (e, s) {
      _log('Caught exception in pickAndUploadImage: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  Future<String?> pickAndUploadSingleImage({
    required String folder,
  }) async {
    try {
      final file = await pickImageFromGallery();

      if (file == null) {
        return null;
      }

      return uploadXFile(file: file, folder: folder);
    } catch (e, s) {
      _log('Caught exception in pickAndUploadSingleImage: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  Future<String> uploadImage(XFile file) {
    return uploadXFile(file: file, folder: 'tours');
  }

  Future<String> uploadReviewImage(XFile file) {
    return uploadXFile(file: file, folder: 'reviews');
  }

  Future<List<String>> pickAndUploadMultipleImages({
    required String folder,
  }) async {
    try {
      await _ensureImageAccess();
      final files = await _imagePicker.pickMultiImage(
        imageQuality: _imageQuality,
        maxWidth: _maxImageWidth,
        maxHeight: _maxImageHeight,
      );
      if (files.isEmpty) {
        _log('Multi-image selection cancelled.');
        return const [];
      }

      final urls = <String>[];
      for (final file in files) {
        _log(
          'Selected image path="${file.path}" name="${file.name}" for batch upload.',
        );
        final url = await uploadXFile(file: file, folder: folder);
        if (url.trim().isEmpty) {
          throw StateError('Storage returned an empty download URL.');
        }
        urls.add(url);
      }
      return urls;
    } catch (e, s) {
      _log('Caught exception in pickAndUploadMultipleImages: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  Future<String> uploadXFile({
    required XFile file,
    required String folder,
  }) async {
    try {
      final normalizedFolder = folder.trim();
      if (normalizedFolder.isEmpty) {
        throw StateError('Upload folder cannot be empty.');
      }

      final normalizedName = file.name.trim();
      if (normalizedName.isEmpty) {
        throw StateError('Selected image is missing a valid file name.');
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw StateError('Selected image bytes are empty.');
      }

      final path = '$normalizedFolder/${DateTime.now().microsecondsSinceEpoch}_$normalizedName';
      final contentType = _resolveContentType(normalizedName);

      _log('Upload started for path="$path" folder="$normalizedFolder" web=$kIsWeb');

      final url = await _supabase.uploadFileBinary(
        bucket: normalizedFolder,
        path: path,
        fileBytes: bytes,
        contentType: contentType,
      );

      _log('Download URL: $url');
      return url;
    } catch (e, s) {
      _log('Caught exception while uploading image: $e');
      debugPrintStack(stackTrace: s);
      rethrow;
    }
  }

  Future<void> _ensureImageAccess() async {
    if (kIsWeb) {
      return;
    }

    final mediaStatus = await Permission.photos.request();
    if (mediaStatus.isGranted || mediaStatus.isLimited) {
      return;
    }

    final storageStatus = await Permission.storage.request();
    if (storageStatus.isGranted) {
      return;
    }

    if (mediaStatus.isPermanentlyDenied || storageStatus.isPermanentlyDenied) {
      throw StateError(
        'Image permission is permanently denied. Please enable it in app settings.',
      );
    }

    throw StateError('Image permission was denied.');
  }

  String _resolveContentType(String fileName) {
    final normalized = fileName.toLowerCase();
    if (normalized.endsWith('.png')) {
      return 'image/png';
    }
    if (normalized.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  void _log(String message) {
    debugPrint('MediaUploadService: $message');
  }
}
