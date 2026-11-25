import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const MaterialApp(home: PhotoPage()));

class PhotoPage extends StatefulWidget {
  const PhotoPage({super.key});

  @override
  State<PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _picked; // the chosen photo
  Uint8List? _imageBytes; // photo data, used to show and upload it
  bool _uploading = false;

  // Open the camera or gallery
  Future<void> _pick(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(source: source);
    if (picked == null) return; // user cancelled
    final bytes = await picked.readAsBytes();
    setState(() {
      _picked = picked;
      _imageBytes = bytes;
    });
  }

  // Send the photo to the server as multipart/form-data
  Future<void> _upload() async {
    if (_picked == null || _imageBytes == null) return;
    setState(() => _uploading = true);
    try {
      final formData = FormData.fromMap({
        'description': 'My first upload', // normal text field
        'file': MultipartFile.fromBytes(
          _imageBytes!,
          filename: _picked!.name,
        ), // the photo
      });

      final res = await Dio().post(
        'https://httpbin.org/post', // test server, replace with your API
        data: formData,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Uploaded! Status ${res.statusCode}')),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _imageBytes == null
                ? const Text('No photo yet')
                : Image.memory(_imageBytes!, height: 250),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: (_imageBytes == null || _uploading) ? null : _upload,
              child: Text(_uploading ? 'Uploading...' : 'Upload'),
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'cam',
            onPressed: () => _pick(ImageSource.camera),
            child: const Icon(Icons.camera_alt),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            heroTag: 'gal',
            onPressed: () => _pick(ImageSource.gallery),
            child: const Icon(Icons.photo),
          ),
        ],
      ),
    );
  }
} 