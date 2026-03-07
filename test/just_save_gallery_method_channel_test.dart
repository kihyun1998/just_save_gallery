import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_save_gallery/just_save_gallery_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelJustSaveGallery platform = MethodChannelJustSaveGallery();
  const MethodChannel channel = MethodChannel('just_save_gallery');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
