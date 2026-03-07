import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'just_save_gallery_platform_interface.dart';

/// An implementation of [JustSaveGalleryPlatform] that uses method channels.
class MethodChannelJustSaveGallery extends JustSaveGalleryPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('just_save_gallery');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
