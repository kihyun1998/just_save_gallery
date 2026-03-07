import 'package:flutter/services.dart';

import 'platform/platform_interface.dart';
import 'types/media_type.dart';
import 'types/save_error_code.dart';
import 'types/save_exception.dart';
import 'types/save_options.dart';

const _kVideoExtensions = {'.mp4', '.mov', '.avi', '.mkv', '.webm', '.3gp'};

/// A Flutter plugin for saving images and videos to the device gallery.
///
/// Supports both Android and iOS. Provides two ways to save media:
/// - From raw bytes using [saveImage] or [saveVideo].
/// - From a file path using [saveFileToGallery].
///
/// Example:
/// ```dart
/// final gallery = JustSaveGallery();
///
/// // Save from bytes
/// final path = await gallery.saveImage(
///   imageBytes,
///   name: 'photo.jpg',
///   albumName: 'My Album',
/// );
///
/// // Save from file path
/// final path = await gallery.saveFileToGallery(
///   '/path/to/video.mp4',
///   albumName: 'My Videos',
/// );
/// ```
class JustSaveGallery {
  /// Saves image bytes to the device gallery.
  ///
  /// [bytes] is the raw image data (JPEG, PNG, WebP, GIF, etc.).
  ///
  /// [name] is the desired file name including extension (e.g. `'photo.jpg'`).
  /// If a file with the same name already exists, a numeric suffix is
  /// automatically appended (e.g. `'photo(1).jpg'`).
  ///
  /// [albumName] is an optional album or folder to save the image into.
  ///
  /// [requestPermission] controls whether the plugin should automatically
  /// request the required storage permission. Defaults to `true`.
  ///
  /// Returns the URI or file path of the saved image.
  ///
  /// Throws [SaveException] if the operation fails.
  Future<String> saveImage(
    Uint8List bytes, {
    required String name,
    String? albumName,
    bool requestPermission = true,
  }) {
    return _save(
      bytes: bytes,
      options: SaveOptions(
        name: name,
        albumName: albumName,
        mediaType: MediaType.image,
        requestPermission: requestPermission,
      ),
    );
  }

  /// Saves video bytes to the device gallery.
  ///
  /// [bytes] is the raw video data. For large videos, consider using
  /// [saveFileToGallery] instead to avoid high memory usage.
  ///
  /// [name] is the desired file name including extension (e.g. `'clip.mp4'`).
  /// If a file with the same name already exists, a numeric suffix is
  /// automatically appended (e.g. `'clip(1).mp4'`).
  ///
  /// [albumName] is an optional album or folder to save the video into.
  ///
  /// [requestPermission] controls whether the plugin should automatically
  /// request the required storage permission. Defaults to `true`.
  ///
  /// Returns the URI or file path of the saved video.
  ///
  /// Throws [SaveException] if the operation fails.
  Future<String> saveVideo(
    Uint8List bytes, {
    required String name,
    String? albumName,
    bool requestPermission = true,
  }) {
    return _save(
      bytes: bytes,
      options: SaveOptions(
        name: name,
        albumName: albumName,
        mediaType: MediaType.video,
        requestPermission: requestPermission,
      ),
    );
  }

  /// Saves a file from the given [filePath] to the device gallery.
  ///
  /// The media type is inferred from the file extension. Video extensions
  /// (`.mp4`, `.mov`, `.avi`, `.mkv`, `.webm`, `.3gp`) are treated as video;
  /// all other extensions are treated as images.
  ///
  /// [albumName] is an optional album or folder to save the file into.
  ///
  /// [requestPermission] controls whether the plugin should automatically
  /// request the required storage permission. Defaults to `true`.
  ///
  /// Returns the URI or file path of the saved media.
  ///
  /// Throws [SaveException] if the operation fails.
  Future<String> saveFileToGallery(
    String filePath, {
    String? albumName,
    bool requestPermission = true,
  }) {
    final name = filePath.split('/').last;
    final ext = name.contains('.') ? '.${name.split('.').last}'.toLowerCase() : '';
    final mediaType = _kVideoExtensions.contains(ext)
        ? MediaType.video
        : MediaType.image;

    return _saveFile(
      filePath: filePath,
      options: SaveOptions(
        name: name,
        albumName: albumName,
        mediaType: mediaType,
        requestPermission: requestPermission,
      ),
    );
  }

  Future<String> _save({
    required Uint8List bytes,
    required SaveOptions options,
  }) async {
    try {
      return await JustSaveGalleryPlatform.instance.saveBytes(
        bytes,
        _optionsToArgs(options),
      );
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  Future<String> _saveFile({
    required String filePath,
    required SaveOptions options,
  }) async {
    try {
      return await JustSaveGalleryPlatform.instance.saveFile(
        filePath,
        _optionsToArgs(options),
      );
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    }
  }

  Map<String, dynamic> _optionsToArgs(SaveOptions options) {
    return {
      'name': options.name,
      if (options.albumName != null) 'albumName': options.albumName,
      'mediaType': options.mediaType?.name ?? MediaType.image.name,
      'requestPermission': options.requestPermission,
    };
  }

  SaveException _mapPlatformException(PlatformException e) {
    final code = switch (e.code) {
      'PERMISSION_DENIED' => SaveErrorCode.permissionDenied,
      'DISK_FULL' => SaveErrorCode.diskFull,
      'INVALID_FORMAT' => SaveErrorCode.invalidFormat,
      'FILE_NOT_FOUND' => SaveErrorCode.fileNotFound,
      _ => SaveErrorCode.unknown,
    };
    return SaveException(code: code, message: e.message);
  }
}
