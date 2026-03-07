import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'method_channel.dart';

/// The interface that platform-specific implementations must implement.
///
/// Platform implementations should extend this class rather than implement it,
/// as new methods may be added in the future. Extending this class ensures
/// backward compatibility via default [UnimplementedError] implementations.
abstract class JustSaveGalleryPlatform extends PlatformInterface {
  /// Constructs a [JustSaveGalleryPlatform].
  JustSaveGalleryPlatform() : super(token: _token);

  static final Object _token = Object();

  static JustSaveGalleryPlatform _instance = MethodChannelJustSaveGallery();

  /// The default instance of [JustSaveGalleryPlatform] to use.
  ///
  /// Defaults to [MethodChannelJustSaveGallery].
  static JustSaveGalleryPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [JustSaveGalleryPlatform] when
  /// they register themselves.
  static set instance(JustSaveGalleryPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Saves raw bytes to the device gallery.
  ///
  /// Returns the URI or file path of the saved media.
  /// The [args] map contains the serialized options for the save operation.
  Future<String> saveBytes(Uint8List bytes, Map<String, dynamic> args) {
    throw UnimplementedError('saveBytes() has not been implemented.');
  }

  /// Saves a file at the given [filePath] to the device gallery.
  ///
  /// Returns the URI or file path of the saved media.
  /// The [args] map contains the serialized options for the save operation.
  Future<String> saveFile(String filePath, Map<String, dynamic> args) {
    throw UnimplementedError('saveFile() has not been implemented.');
  }
}
