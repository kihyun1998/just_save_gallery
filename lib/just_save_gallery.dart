
import 'just_save_gallery_platform_interface.dart';

class JustSaveGallery {
  Future<String?> getPlatformVersion() {
    return JustSaveGalleryPlatform.instance.getPlatformVersion();
  }
}
