import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_save_gallery/src/platform/method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelJustSaveGallery();
  const channel = MethodChannel('just_save_gallery');

  late List<MethodCall> log;

  setUp(() {
    log = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      log.add(methodCall);
      return 'content://media/external/images/media/1';
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('saveBytes', () {
    test('returns URI from platform', () async {
      final result = await platform.saveBytes(
        Uint8List.fromList([0xFF, 0xD8, 0xFF]),
        {'name': 'test.jpg', 'mediaType': 'image', 'requestPermission': true},
      );
      expect(result, 'content://media/external/images/media/1');
    });

    test('invokes correct method name', () async {
      await platform.saveBytes(
        Uint8List.fromList([0x00]),
        {'name': 'a.jpg', 'mediaType': 'image', 'requestPermission': true},
      );
      expect(log.single.method, 'saveBytes');
    });

    test('passes bytes and args in arguments', () async {
      final bytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);
      await platform.saveBytes(bytes, {
        'name': 'img.png',
        'albumName': 'TestAlbum',
        'mediaType': 'image',
        'requestPermission': false,
      });

      final args = log.single.arguments as Map;
      expect(args['bytes'], bytes);
      expect(args['name'], 'img.png');
      expect(args['albumName'], 'TestAlbum');
      expect(args['mediaType'], 'image');
      expect(args['requestPermission'], false);
    });
  });

  group('saveFile', () {
    test('returns URI from platform', () async {
      final result = await platform.saveFile(
        '/tmp/test.jpg',
        {'name': 'test.jpg', 'mediaType': 'image', 'requestPermission': true},
      );
      expect(result, 'content://media/external/images/media/1');
    });

    test('invokes correct method name', () async {
      await platform.saveFile(
        '/tmp/a.mp4',
        {'name': 'a.mp4', 'mediaType': 'video', 'requestPermission': true},
      );
      expect(log.single.method, 'saveFile');
    });

    test('passes filePath and args in arguments', () async {
      await platform.saveFile('/data/video.mp4', {
        'name': 'video.mp4',
        'albumName': 'Movies',
        'mediaType': 'video',
        'requestPermission': true,
      });

      final args = log.single.arguments as Map;
      expect(args['filePath'], '/data/video.mp4');
      expect(args['name'], 'video.mp4');
      expect(args['albumName'], 'Movies');
      expect(args['mediaType'], 'video');
      expect(args['requestPermission'], true);
    });
  });

  group('error propagation', () {
    test('throws PlatformException from native side', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        throw PlatformException(
          code: 'PERMISSION_DENIED',
          message: 'denied',
        );
      });

      expect(
        () => platform.saveBytes(
          Uint8List(0),
          {'name': 'a.jpg', 'mediaType': 'image', 'requestPermission': true},
        ),
        throwsA(isA<PlatformException>()),
      );
    });
  });
}
