import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'platform_interface.dart';

/// A [JustSaveGalleryPlatform] implementation that uses method channels.
class MethodChannelJustSaveGallery extends JustSaveGalleryPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('just_save_gallery');

  @override
  Future<String> saveBytes(Uint8List bytes, Map<String, dynamic> args) async {
    final result = await methodChannel.invokeMethod<String>('saveBytes', {
      'bytes': bytes,
      ...args,
    });
    return result!;
  }

  @override
  Future<String> saveFile(String filePath, Map<String, dynamic> args) async {
    final result = await methodChannel.invokeMethod<String>('saveFile', {
      'filePath': filePath,
      ...args,
    });
    return result!;
  }
}
