import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'just_save_gallery_method_channel.dart';

abstract class JustSaveGalleryPlatform extends PlatformInterface {
  /// Constructs a JustSaveGalleryPlatform.
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

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
