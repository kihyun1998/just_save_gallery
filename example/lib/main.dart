import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:just_save_gallery/just_save_gallery.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JustSaveGallery Playground',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const PlaygroundPage(),
    );
  }
}

class PlaygroundPage extends StatefulWidget {
  const PlaygroundPage({super.key});

  @override
  State<PlaygroundPage> createState() => _PlaygroundPageState();
}

class _PlaygroundPageState extends State<PlaygroundPage> {
  final _gallery = JustSaveGallery();
  final _nameController = TextEditingController(text: 'flutter_logo.png');
  final _albumController = TextEditingController(text: 'JustSaveGallery');
  final _previewKey = GlobalKey();

  String _status = 'Ready';
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _albumController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _status = 'Saving...';
    });

    try {
      final bytes = await _capturePreview();
      if (bytes == null) {
        setState(() {
          _status = 'Failed to capture preview';
          _saving = false;
        });
        return;
      }

      final albumName = _albumController.text.trim();

      final uri = await _gallery.saveImage(
        bytes,
        name: _nameController.text.trim(),
        albumName: albumName.isEmpty ? null : albumName,
      );

      setState(() => _status = 'Saved!\n$uri');
    } on SaveException catch (e) {
      setState(() => _status = 'SaveException\n${e.code}\n${e.message}');
    } catch (e) {
      setState(() => _status = 'Error\n$e');
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<Uint8List?> _capturePreview() async {
    final boundary = _previewKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('JustSaveGallery Playground')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview
            Center(
              child: RepaintBoundary(
                key: _previewKey,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const FlutterLogo(size: 120),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Preview (512x512 will be saved)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 24),

            // File name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'File name',
                hintText: 'e.g. my_image.png',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            // Album name
            TextField(
              controller: _albumController,
              decoration: const InputDecoration(
                labelText: 'Album name (optional)',
                hintText: 'Leave empty for default gallery',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            // Save button
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_alt),
              label: Text(_saving ? 'Saving...' : 'Save to Gallery'),
            ),

            const SizedBox(height: 24),

            // Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _status.startsWith('Saved')
                    ? Colors.green.shade50
                    : _status.startsWith('Error') ||
                            _status.startsWith('Save')
                        ? Colors.red.shade50
                        : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                _status,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: _status.startsWith('Saved')
                      ? Colors.green.shade800
                      : _status.startsWith('Error') ||
                              _status.startsWith('SaveException')
                          ? Colors.red.shade800
                          : Colors.grey.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
