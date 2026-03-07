import 'package:flutter_test/flutter_test.dart';
import 'package:just_save_gallery/just_save_gallery.dart';
import 'package:just_save_gallery/just_save_gallery_platform_interface.dart';
import 'package:just_save_gallery/just_save_gallery_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockJustSaveGalleryPlatform
    with MockPlatformInterfaceMixin
    implements JustSaveGalleryPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final JustSaveGalleryPlatform initialPlatform = JustSaveGalleryPlatform.instance;

  test('$MethodChannelJustSaveGallery is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelJustSaveGallery>());
  });

  test('getPlatformVersion', () async {
    JustSaveGallery justSaveGalleryPlugin = JustSaveGallery();
    MockJustSaveGalleryPlatform fakePlatform = MockJustSaveGalleryPlatform();
    JustSaveGalleryPlatform.instance = fakePlatform;

    expect(await justSaveGalleryPlugin.getPlatformVersion(), '42');
  });
}
