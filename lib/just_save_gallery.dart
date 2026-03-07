/// A Flutter plugin for saving images and videos to the device gallery.
///
/// Supports both raw bytes and file path inputs on Android and iOS.
///
/// ```dart
/// final gallery = JustSaveGallery();
///
/// // Save image from bytes
/// final path = await gallery.saveImage(bytes, name: 'photo.jpg');
///
/// // Save file from path
/// final path = await gallery.saveFileToGallery('/path/to/video.mp4');
/// ```
library;

export 'src/just_save_gallery.dart';
export 'src/types/media_type.dart';
export 'src/types/save_error_code.dart';
export 'src/types/save_exception.dart';
export 'src/types/save_options.dart';
